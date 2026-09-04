import datetime
import json
from typing import Any, Optional

from database import get_mssql_connection
from repositories.assessment_repository import (
    complete_assessment_session,
    create_assessment_session,
    find_project_reference,
    create_or_update_user,
    get_assessment_answers,
    get_assessment_session,
    get_assessment_session_by_id,
    get_user_assessment_history,
    upsert_assessment_answers,
    upsert_english_result,
)

ALLOWED_CHALLENGE_TYPES = {"english_placement", "project_fit"}
ALLOWED_STATUSES = {"started", "completed", "failed"}
ALLOWED_FEEDBACK_SOURCES = {"openrouter", "fallback", "none"}


class InvalidUsageError(Exception):
    pass


class NotFoundError(Exception):
    pass


class ConflictError(Exception):
    pass


def normalize_email(email: Optional[str]) -> Optional[str]:
    if not email:
        return None
    normalized = email.strip().lower()
    return normalized or None


def _normalize_string(value: Any) -> str:
    if value is None:
        return ""
    return str(value).strip()


def _validate_result_payload(result: dict) -> None:
    if not isinstance(result, dict):
        raise InvalidUsageError("Result payload must be an object.")

    if _normalize_string(result.get("estimatedLevel")) == "":
        raise InvalidUsageError("estimatedLevel is required.")

    if result.get("percentage") is None:
        raise InvalidUsageError("percentage is required.")

    if result.get("correctAnswers") is None or result.get("incorrectAnswers") is None:
        raise InvalidUsageError("correctAnswers and incorrectAnswers are required.")

    if result.get("earnedWeightedScore") is None or result.get("maximumWeightedScore") is None:
        raise InvalidUsageError("earnedWeightedScore and maximumWeightedScore are required.")

    feedback_source = _normalize_string(result.get("feedbackSource"))
    if feedback_source and feedback_source not in ALLOWED_FEEDBACK_SOURCES:
        raise InvalidUsageError("feedbackSource must be one of openrouter, fallback, none.")


def create_assessment_session_service(payload: dict) -> dict:
    if not isinstance(payload, dict):
        raise InvalidUsageError("Request body must be a JSON object.")

    user_data = payload.get("user")
    if not isinstance(user_data, dict):
        raise InvalidUsageError("user field is required and must be an object.")

    email = normalize_email(user_data.get("email"))
    if not email:
        raise InvalidUsageError("user.email is required.")

    name = _normalize_string(user_data.get("name"))
    gender = _normalize_string(user_data.get("gender"))
    challenge_type = _normalize_string(payload.get("challengeType"))
    if challenge_type not in ALLOWED_CHALLENGE_TYPES:
        raise InvalidUsageError("challengeType must be english_placement or project_fit.")

    project_data = payload.get("project", {}) or {}
    if not isinstance(project_data, dict):
        raise InvalidUsageError("project field must be an object.")

    project_id = _normalize_string(project_data.get("projectId")) or None
    project_url = _normalize_string(project_data.get("sourceUrl")) or None
    external_project_id = _normalize_string(project_data.get("projectId")) if project_id else None

    project_snapshot = {
        "externalProjectId": external_project_id,
        "title": _normalize_string(project_data.get("title")),
        "sourceName": _normalize_string(project_data.get("sourceName")),
        "sourceUrl": project_url,
    }

    with get_mssql_connection() as conn:
        conn.autocommit = False
        try:
            user_id = create_or_update_user(conn, email, name, gender)
            project_reference = find_project_reference(conn, project_id, project_url, external_project_id)
            session_id = create_assessment_session(
                conn,
                user_id,
                project_reference,
                project_snapshot,
                challenge_type,
                "started",
            )
            conn.commit()
        except Exception:
            conn.rollback()
            raise

    return {
        "success": True,
        "sessionId": session_id,
        "status": "started",
    }


def complete_english_placement_result_service(session_id: int, payload: dict) -> dict:
    if not isinstance(payload, dict):
        raise InvalidUsageError("Request body must be a JSON object.")

    result = payload.get("result")
    answers = payload.get("answers")
    if not isinstance(result, dict):
        raise InvalidUsageError("result field is required and must be an object.")
    if not isinstance(answers, list):
        raise InvalidUsageError("answers field is required and must be an array.")

    _validate_result_payload(result)

    with get_mssql_connection() as conn:
        conn.autocommit = False
        try:
            session = get_assessment_session_by_id(conn, session_id)
            if not session:
                raise NotFoundError("Assessment session not found.")

            if session.ChallengeType != "english_placement":
                raise ConflictError("Session is not an english_placement assessment.")

            upsert_assessment_answers(conn, session_id, answers)
            upsert_english_result(conn, session_id, {
                "estimatedLevel": result.get("estimatedLevel"),
                "percentage": result.get("percentage"),
                "correctAnswers": result.get("correctAnswers"),
                "incorrectAnswers": result.get("incorrectAnswers"),
                "earnedWeightedScore": result.get("earnedWeightedScore"),
                "maximumWeightedScore": result.get("maximumWeightedScore"),
                "skillScores": result.get("skillScores", {}),
                "strengths": result.get("strengths"),
                "weaknesses": result.get("weaknesses"),
                "aiFeedback": result.get("aiFeedback"),
                "feedbackSource": _normalize_string(result.get("feedbackSource")) or "none",
                "aiModel": result.get("aiModel"),
            })
            now = datetime.datetime.utcnow()
            complete_assessment_session(conn, session_id, "completed", now)
            conn.commit()
        except Exception:
            conn.rollback()
            raise

    return {
        "success": True,
        "sessionId": session_id,
        "status": "completed",
    }


def get_assessment_session_detail_service(session_id: int) -> dict:
    with get_mssql_connection() as conn:
        session = get_assessment_session(conn, session_id)
        if not session:
            raise NotFoundError("Assessment session not found.")

        answers = get_assessment_answers(conn, session_id)

    strengths = None
    weaknesses = None
    if session.StrengthsJson:
        strengths = json.loads(session.StrengthsJson)
    if session.WeaknessesJson:
        weaknesses = json.loads(session.WeaknessesJson)

    english_result = None
    if session.ResultID is not None:
        english_result = {
            "resultId": session.ResultID,
            "estimatedLevel": session.EstimatedLevel,
            "percentage": float(session.Percentage) if session.Percentage is not None else None,
            "correctAnswers": session.CorrectAnswers,
            "incorrectAnswers": session.IncorrectAnswers,
            "earnedWeightedScore": float(session.EarnedWeightedScore) if session.EarnedWeightedScore is not None else None,
            "maximumWeightedScore": float(session.MaximumWeightedScore) if session.MaximumWeightedScore is not None else None,
            "grammarScore": float(session.GrammarScore) if session.GrammarScore is not None else None,
            "vocabularyScore": float(session.VocabularyScore) if session.VocabularyScore is not None else None,
            "readingScore": float(session.ReadingScore) if session.ReadingScore is not None else None,
            "communicationScore": float(session.CommunicationScore) if session.CommunicationScore is not None else None,
            "useOfEnglishScore": float(session.UseOfEnglishScore) if session.UseOfEnglishScore is not None else None,
            "strengths": strengths,
            "weaknesses": weaknesses,
            "aiFeedback": session.AiFeedback,
            "feedbackSource": session.FeedbackSource,
            "aiModel": session.AiModel,
            "createdAt": session.ResultCreatedAt.isoformat() if session.ResultCreatedAt else None,
            "updatedAt": session.ResultUpdatedAt.isoformat() if session.ResultUpdatedAt else None,
        }

    return {
        "session": {
            "sessionId": session.SessionID,
            "challengeType": session.ChallengeType,
            "status": session.Status,
            "startedAt": session.StartedAt.isoformat() if session.StartedAt else None,
            "completedAt": session.CompletedAt.isoformat() if session.CompletedAt else None,
            "createdAt": session.SessionCreatedAt.isoformat() if session.SessionCreatedAt else None,
            "updatedAt": session.SessionUpdatedAt.isoformat() if session.SessionUpdatedAt else None,
        },
        "user": {
            "id": session.UserId,
            "name": session.UserName,
            "gender": session.UserGender,
            "email": session.UserEmail,
            "createdAt": session.UserCreatedAt.isoformat() if session.UserCreatedAt else None,
            "updatedAt": session.UserUpdatedAt.isoformat() if session.UserUpdatedAt else None,
        },
        "project": {
            "projectId": session.ProjectID,
            "externalProjectId": session.ExternalProjectID,
            "title": session.ProjectTitle,
            "source": session.ProjectSource,
            "url": session.ProjectUrl,
        },
        "englishResult": english_result,
        "answers": [
            {
                "answerId": row.AnswerID,
                "questionId": row.QuestionID,
                "displayOrder": row.DisplayOrder,
                "questionType": row.QuestionType,
                "skill": row.Skill,
                "cefrLevel": row.CefrLevel,
                "questionText": row.QuestionText,
                "passageText": row.PassageText,
                "options": json.loads(row.OptionsJson) if row.OptionsJson else None,
                "selectedOptionIndex": row.SelectedOptionIndex,
                "textAnswer": row.TextAnswer,
                "isCorrect": bool(row.IsCorrect) if row.IsCorrect is not None else None,
                "earnedScore": float(row.EarnedScore) if row.EarnedScore is not None else None,
                "maximumScore": float(row.MaximumScore) if row.MaximumScore is not None else None,
                "answeredAt": row.AnsweredAt.isoformat() if row.AnsweredAt else None,
            }
            for row in answers
        ],
    }


def get_user_assessment_history_service(email: str, page: int, page_size: int) -> dict:
    normalized_email = normalize_email(email)
    if not normalized_email:
        raise InvalidUsageError("Email is required.")

    if page < 1 or page_size < 1:
        raise InvalidUsageError("page and pageSize must be positive integers.")

    with get_mssql_connection() as conn:
        total, rows = get_user_assessment_history(conn, normalized_email, page, page_size)

    items = [
        {
            "sessionId": row.SessionID,
            "challengeType": row.ChallengeType,
            "projectTitle": row.ProjectTitle,
            "estimatedLevel": row.EstimatedLevel,
            "percentage": float(row.Percentage) if row.Percentage is not None else None,
            "completedAt": row.CompletedAt.isoformat() if row.CompletedAt else None,
        }
        for row in rows
    ]

    return {
        "page": page,
        "pageSize": page_size,
        "total": total,
        "items": items,
    }

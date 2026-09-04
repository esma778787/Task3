import datetime
import json
from typing import Any, Optional


def _now_utc():
    return datetime.datetime.utcnow()


def _to_json(value: Any) -> Optional[str]:
    if value is None:
        return None

    return json.dumps(value, ensure_ascii=False)


def find_user_by_email(conn, email: str):
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, name, gender, email, interests, motivation_letter, europass_cv, selected_project_title, selected_project_description, created_at, updated_at "
        "FROM dbo.Users WHERE email = ?",
        email,
    )
    return cursor.fetchone()


def create_or_update_user(conn, email: str, name: str, gender: str) -> int:
    now = _now_utc()
    cursor = conn.cursor()
    existing = find_user_by_email(conn, email)

    if existing:
        cursor.execute(
            "UPDATE dbo.Users SET name = ?, gender = ?, email = ?, updated_at = ? WHERE id = ?",
            name,
            gender,
            email,
            now,
            existing.id,
        )
        return existing.id

    cursor.execute(
        "INSERT INTO dbo.Users (name, gender, email, created_at, updated_at) OUTPUT INSERTED.id VALUES (?, ?, ?, ?, ?)",
        name,
        gender,
        email,
        now,
        now,
    )
    row = cursor.fetchone()
    if not row or row[0] is None:
        raise RuntimeError("Unable to retrieve inserted user ID.")
    return int(row[0])


def find_project_reference(conn, project_id: Optional[str], project_url: Optional[str], external_project_id: Optional[str]):
    cursor = conn.cursor()

    if project_id is not None:
        try:
            project_id_int = int(project_id)
            cursor.execute(
                "SELECT ProjectID, Title, Link FROM dbo.Projects WHERE ProjectID = ?",
                project_id_int,
            )
            row = cursor.fetchone()
            if row:
                return row
        except ValueError:
            pass

    if project_url:
        cursor.execute(
            "SELECT ProjectID, Title, Link FROM dbo.Projects WHERE Link = ?",
            project_url,
        )
        row = cursor.fetchone()
        if row:
            return row

    if external_project_id is not None and external_project_id.isdigit():
        cursor.execute(
            "SELECT ProjectID, Title, Link FROM dbo.Projects WHERE ProjectID = ?",
            int(external_project_id),
        )
        row = cursor.fetchone()
        if row:
            return row

    return None


def create_assessment_session(
    conn,
    user_id: int,
    project_reference,
    project_snapshot: dict,
    challenge_type: str,
    status: str,
) -> int:
    now = _now_utc()
    project_id = project_reference.ProjectID if project_reference is not None else None

    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO dbo.AssessmentSessions (UserID, ProjectID, ExternalProjectID, ProjectTitle, ProjectSource, ProjectUrl, ChallengeType, Status, StartedAt, CompletedAt, CreatedAt, UpdatedAt) OUTPUT INSERTED.SessionID VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        user_id,
        project_id,
        project_snapshot.get("externalProjectId"),
        project_snapshot.get("title"),
        project_snapshot.get("sourceName"),
        project_snapshot.get("sourceUrl"),
        challenge_type,
        status,
        now,
        None,
        now,
        now,
    )
    row = cursor.fetchone()
    if not row or row[0] is None:
        raise RuntimeError("Unable to retrieve inserted session ID.")
    return int(row[0])


def upsert_assessment_answers(conn, session_id: int, answers: list) -> None:
    cursor = conn.cursor()
    now = _now_utc()

    for answer in answers:
        question_id = answer.get("questionId")
        if not question_id:
            continue

        selected_option_index = answer.get("selectedOptionIndex")
        text_answer = answer.get("textAnswer")
        is_correct = answer.get("isCorrect")
        earned_score = answer.get("earnedScore")
        maximum_score = answer.get("maximumScore")
        answered_at = answer.get("answeredAt")
        answered_at_value = answered_at if answered_at is not None else now

        cursor.execute(
            "IF EXISTS (SELECT 1 FROM dbo.AssessmentAnswers WHERE SessionID = ? AND QuestionID = ?) "
            "BEGIN "
            "UPDATE dbo.AssessmentAnswers SET DisplayOrder = ?, QuestionType = ?, Skill = ?, CefrLevel = ?, QuestionText = ?, PassageText = ?, OptionsJson = ?, SelectedOptionIndex = ?, TextAnswer = ?, IsCorrect = ?, EarnedScore = ?, MaximumScore = ?, AnsweredAt = ?, UpdatedAt = ? "
            "WHERE SessionID = ? AND QuestionID = ? "
            "END "
            "ELSE "
            "BEGIN "
            "INSERT INTO dbo.AssessmentAnswers (SessionID, QuestionID, DisplayOrder, QuestionType, Skill, CefrLevel, QuestionText, PassageText, OptionsJson, SelectedOptionIndex, TextAnswer, IsCorrect, EarnedScore, MaximumScore, AnsweredAt, CreatedAt, UpdatedAt) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) "
            "END",
            session_id,
            question_id,
            answer.get("displayOrder"),
            answer.get("questionType"),
            answer.get("skill"),
            answer.get("cefrLevel"),
            answer.get("questionText"),
            answer.get("passageText"),
            _to_json(answer.get("options")),
            selected_option_index,
            text_answer,
            1 if is_correct else 0 if is_correct is not None else None,
            earned_score,
            maximum_score,
            answered_at_value,
            now,
            session_id,
            question_id,
            session_id,
            question_id,
            answer.get("displayOrder"),
            answer.get("questionType"),
            answer.get("skill"),
            answer.get("cefrLevel"),
            answer.get("questionText"),
            answer.get("passageText"),
            _to_json(answer.get("options")),
            selected_option_index,
            text_answer,
            1 if is_correct else 0 if is_correct is not None else None,
            earned_score,
            maximum_score,
            answered_at_value,
            now,
            now,
        )


def upsert_english_result(conn, session_id: int, result: dict) -> None:
    cursor = conn.cursor()
    now = _now_utc()
    strengths = _to_json(result.get("strengths"))
    weaknesses = _to_json(result.get("weaknesses"))

    cursor.execute(
        "IF EXISTS (SELECT 1 FROM dbo.EnglishPlacementResults WHERE SessionID = ?) "
        "BEGIN "
        "UPDATE dbo.EnglishPlacementResults SET EstimatedLevel = ?, Percentage = ?, CorrectAnswers = ?, IncorrectAnswers = ?, EarnedWeightedScore = ?, MaximumWeightedScore = ?, GrammarScore = ?, VocabularyScore = ?, ReadingScore = ?, CommunicationScore = ?, UseOfEnglishScore = ?, StrengthsJson = ?, WeaknessesJson = ?, AiFeedback = ?, FeedbackSource = ?, AiModel = ?, UpdatedAt = ? "
        "WHERE SessionID = ? "
        "END "
        "ELSE "
        "BEGIN "
        "INSERT INTO dbo.EnglishPlacementResults (SessionID, EstimatedLevel, Percentage, CorrectAnswers, IncorrectAnswers, EarnedWeightedScore, MaximumWeightedScore, GrammarScore, VocabularyScore, ReadingScore, CommunicationScore, UseOfEnglishScore, StrengthsJson, WeaknessesJson, AiFeedback, FeedbackSource, AiModel, CreatedAt, UpdatedAt) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) "
        "END",
        session_id,
        result.get("estimatedLevel"),
        result.get("percentage"),
        result.get("correctAnswers"),
        result.get("incorrectAnswers"),
        result.get("earnedWeightedScore"),
        result.get("maximumWeightedScore"),
        result.get("skillScores", {}).get("grammar"),
        result.get("skillScores", {}).get("vocabulary"),
        result.get("skillScores", {}).get("reading"),
        result.get("skillScores", {}).get("communication"),
        result.get("skillScores", {}).get("useOfEnglish"),
        strengths,
        weaknesses,
        result.get("aiFeedback"),
        result.get("feedbackSource"),
        result.get("aiModel"),
        now,
        session_id,
        session_id,
        result.get("estimatedLevel"),
        result.get("percentage"),
        result.get("correctAnswers"),
        result.get("incorrectAnswers"),
        result.get("earnedWeightedScore"),
        result.get("maximumWeightedScore"),
        result.get("skillScores", {}).get("grammar"),
        result.get("skillScores", {}).get("vocabulary"),
        result.get("skillScores", {}).get("reading"),
        result.get("skillScores", {}).get("communication"),
        result.get("skillScores", {}).get("useOfEnglish"),
        strengths,
        weaknesses,
        result.get("aiFeedback"),
        result.get("feedbackSource"),
        result.get("aiModel"),
        now,
        now,
    )


def get_assessment_session(conn, session_id: int):
    cursor = conn.cursor()
    cursor.execute(
        "SELECT s.SessionID, s.UserID, s.ProjectID, s.ExternalProjectID, s.ProjectTitle, s.ProjectSource, s.ProjectUrl, s.ChallengeType, s.Status, s.StartedAt, s.CompletedAt, s.CreatedAt AS SessionCreatedAt, s.UpdatedAt AS SessionUpdatedAt, "
        "u.id AS UserId, u.name AS UserName, u.gender AS UserGender, u.email AS UserEmail, u.created_at AS UserCreatedAt, u.updated_at AS UserUpdatedAt, "
        "r.ResultID, r.EstimatedLevel, r.Percentage, r.CorrectAnswers, r.IncorrectAnswers, r.EarnedWeightedScore, r.MaximumWeightedScore, r.GrammarScore, r.VocabularyScore, r.ReadingScore, r.CommunicationScore, r.UseOfEnglishScore, r.StrengthsJson, r.WeaknessesJson, r.AiFeedback, r.FeedbackSource, r.AiModel, r.CreatedAt AS ResultCreatedAt, r.UpdatedAt AS ResultUpdatedAt "
        "FROM dbo.AssessmentSessions s "
        "JOIN dbo.Users u ON s.UserID = u.id "
        "LEFT JOIN dbo.EnglishPlacementResults r ON s.SessionID = r.SessionID "
        "WHERE s.SessionID = ?",
        session_id,
    )
    return cursor.fetchone()


def get_assessment_session_by_id(conn, session_id: int):
    cursor = conn.cursor()
    cursor.execute(
        "SELECT SessionID, ChallengeType, Status FROM dbo.AssessmentSessions WHERE SessionID = ?",
        session_id,
    )
    return cursor.fetchone()


def complete_assessment_session(conn, session_id: int, status: str, completed_at):
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE dbo.AssessmentSessions SET Status = ?, CompletedAt = ?, UpdatedAt = ? WHERE SessionID = ?",
        status,
        completed_at,
        completed_at,
        session_id,
    )


def get_assessment_answers(conn, session_id: int):
    cursor = conn.cursor()
    cursor.execute(
        "SELECT AnswerID, SessionID, QuestionID, DisplayOrder, QuestionType, Skill, CefrLevel, QuestionText, PassageText, OptionsJson, SelectedOptionIndex, TextAnswer, IsCorrect, EarnedScore, MaximumScore, AnsweredAt, CreatedAt, UpdatedAt "
        "FROM dbo.AssessmentAnswers "
        "WHERE SessionID = ? ORDER BY DisplayOrder ASC, AnswerID ASC",
        session_id,
    )
    return cursor.fetchall()


def get_user_assessment_history(conn, email: str, page: int, page_size: int):
    offset = (page - 1) * page_size

    cursor = conn.cursor()
    cursor.execute(
        "SELECT COUNT(1) "
        "FROM dbo.AssessmentSessions s "
        "JOIN dbo.Users u ON s.UserID = u.id "
        "WHERE u.email = ?",
        email,
    )
    total = cursor.fetchone()[0]

    cursor.execute(
        "SELECT s.SessionID, s.ChallengeType, s.ProjectTitle, r.EstimatedLevel, r.Percentage, s.CompletedAt "
        "FROM dbo.AssessmentSessions s "
        "JOIN dbo.Users u ON s.UserID = u.id "
        "LEFT JOIN dbo.EnglishPlacementResults r ON s.SessionID = r.SessionID "
        "WHERE u.email = ? "
        "ORDER BY s.CreatedAt DESC "
        "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY",
        email,
        offset,
        page_size,
    )
    return total, cursor.fetchall()


def get_assessment_session_by_id(conn, session_id: int):
    cursor = conn.cursor()
    cursor.execute(
        "SELECT SessionID, ChallengeType, Status FROM dbo.AssessmentSessions WHERE SessionID = ?",
        session_id,
    )
    return cursor.fetchone()


def complete_assessment_session(conn, session_id: int, status: str, completed_at: datetime.datetime) -> None:
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE dbo.AssessmentSessions SET Status = ?, CompletedAt = ?, UpdatedAt = ? WHERE SessionID = ?",
        status,
        completed_at,
        completed_at,
        session_id,
    )


def get_session_basic(conn, session_id: int):
    cursor = conn.cursor()
    cursor.execute(
        "SELECT SessionID, UserID, ProjectID, ExternalProjectID, ProjectTitle, ProjectSource, ProjectUrl, ChallengeType, Status, StartedAt, CompletedAt, CreatedAt, UpdatedAt FROM dbo.AssessmentSessions WHERE SessionID = ?",
        session_id,
    )
    return cursor.fetchone()

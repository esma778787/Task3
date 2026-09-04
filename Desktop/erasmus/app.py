import json
import os
from pathlib import Path

from flask import Flask, jsonify, request
from flask_cors import CORS

try:
    from pymongo import MongoClient
    from pymongo.errors import PyMongoError
except ImportError:
    MongoClient = None
    PyMongoError = Exception

from database import get_mssql_connection
from services.assessment_service import (
    InvalidUsageError,
    NotFoundError,
    ConflictError,
    create_assessment_session_service,
    complete_english_placement_result_service,
    get_assessment_session_detail_service,
    get_user_assessment_history_service,
)

app = Flask(__name__)
CORS(app)

@app.route("/")
def home():
    return "🎉 API çalışıyor! /projects adresine git"


def get_db_connection():
    return get_mssql_connection()


@app.errorhandler(InvalidUsageError)
def handle_invalid_usage(error):
    return jsonify({"error": str(error)}), 400


@app.errorhandler(NotFoundError)
def handle_not_found(error):
    return jsonify({"error": str(error)}), 404


@app.errorhandler(ConflictError)
def handle_conflict(error):
    return jsonify({"error": str(error)}), 409


@app.errorhandler(Exception)
def handle_exception(error):
    return jsonify({"error": "Internal server error"}), 500


def get_mongo_collection(uri: str, db_name: str, collection_name: str):
    client = MongoClient(uri, serverSelectionTimeoutMS=5000)
    db = client[db_name]
    return client, db[collection_name]


def format_european_youth_project(item: dict) -> dict:
    return {
        "id": item.get("sourceUrl", "") or "",
        "title": item.get("title", "") or "",
        "link": item.get("sourceUrl", "") or "",
        "content": item.get("description", "") or "",
        "description": item.get("description", "") or "",
        "category": item.get("recordType", "") or item.get("sourceName", "European Youth Portal") or "European Youth Portal",
        "source": item.get("sourceName", "European Youth Portal") or "European Youth Portal",
    }


def load_json_file(path: Path):
    with path.open("r", encoding="utf-8") as fp:
        return json.load(fp)


def rows_to_dicts(cursor):
    if not cursor.description:
        return []

    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def load_projects_from_fallback():
    for candidate in (Path("erasmusgram_projects.json"), Path("assets/erasmusgram_projects.json")):
        if not candidate.exists():
            continue

        raw_data = load_json_file(candidate)
        if isinstance(raw_data, list):
            return raw_data

        if isinstance(raw_data, dict):
            projects = raw_data.get("projects") or raw_data.get("data") or raw_data.get("items")
            if isinstance(projects, list):
                return projects

    return []


@app.route("/projects", methods=["GET"])
def get_projects():
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT 
                p.ProjectID,
                p.Title,
                p.Link,
                ISNULL(p.Description, '') AS Description,
                ISNULL(c.CategoryName, 'Erasmus+') AS CategoryName
            FROM dbo.Projects p
            LEFT JOIN dbo.ProjectCategories c
                ON p.CategoryID = c.CategoryID
            ORDER BY p.ProjectID DESC
        """)

        rows = rows_to_dicts(cur)
        data = []

        for row in rows:
            data.append({
                "id": row.get("ProjectID"),
                "title": row.get("Title", "") or "",
                "link": row.get("Link", "") or "",
                "content": row.get("Description", "") or "",
                "description": row.get("Description", "") or "",
                "category": row.get("CategoryName", "Erasmus+") or "Erasmus+",
                "source": ""
            })

        return jsonify(data), 200

    except EnvironmentError as e:
        app.logger.warning("MSSQL environment not configured: %s", e)
        fallback = load_projects_from_fallback()
        if fallback:
            return jsonify(fallback), 200
        return jsonify({"error": "MSSQL environment not configured", "details": str(e)}), 500

    except Exception as e:
        app.logger.exception("Error while fetching /projects")
        fallback = load_projects_from_fallback()
        if fallback:
            return jsonify(fallback), 200
        return jsonify({"error": "Internal server error", "details": str(e)}), 500

    finally:
        if conn is not None:
            conn.close()

@app.route("/projects/european-youth", methods=["GET"])
def get_european_youth_projects():
    try:
        projects = []
        mongo_uri = os.getenv("MONGO_URI")

        if mongo_uri and MongoClient is not None:
            client = None
            try:
                mongo_db = os.getenv("MONGO_DB_NAME", "erasmusdb")
                collection_name = os.getenv("MONGO_COLLECTION", "european_youth_projects")
                client, collection = get_mongo_collection(mongo_uri, mongo_db, collection_name)
                for doc in collection.find({}, {"_id": False}):
                    if isinstance(doc, dict):
                        projects.append(format_european_youth_project(doc))
            finally:
                if client is not None:
                    client.close()

        if not projects:
            fallback_file = Path("european_youth_projects.json")
            if fallback_file.exists():
                raw_data = load_json_file(fallback_file)
                raw_projects = raw_data.get("projects", []) if isinstance(raw_data, dict) else []
                for item in raw_projects:
                    if isinstance(item, dict):
                        projects.append(format_european_youth_project(item))

        return jsonify(projects), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/simulation-result", methods=["POST"])
def save_simulation_result():
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({"error": "Geçerli JSON gönderilmedi."}), 400

    name = data.get("Name", "") or ""
    gender = data.get("Gender", "") or ""
    interests = data.get("Interests", "") or ""
    motivation_letter = data.get("MotivationLetter", "") or ""
    europass_cv = data.get("EuropassCV", "") or ""
    selected_project_title = data.get("SelectedProjectTitle", "") or ""
    selected_project_description = data.get("SelectedProjectDescription", "") or ""
    score = data.get("Score")
    feedback = data.get("Feedback", "") or ""
    category = data.get("Category", "") or ""
    language_level = data.get("LanguageLevel", "") or ""
    cv_language = data.get("CVLanguage", "") or ""
    ai_feedback = data.get("AIFeedback", "") or ""

    try:
        score = int(score) if score is not None else None
    except (TypeError, ValueError):
        score = None

    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            """
            INSERT INTO dbo.SimulationResults
                (Name, Gender, Interests, MotivationLetter, EuropassCV,
                 SelectedProjectTitle, SelectedProjectDescription,
                 Score, Feedback, Category, LanguageLevel, CVLanguage,
                 AIFeedback, CreatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())
            """,
            name,
            gender,
            interests,
            motivation_letter,
            europass_cv,
            selected_project_title,
            selected_project_description,
            score,
            feedback,
            category,
            language_level,
            cv_language,
            ai_feedback,
        )

        conn.commit()

        return jsonify({
            "success": True,
            "message": "Simülasyon sonucu kaydedildi."
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        if conn is not None:
            conn.close()

@app.route("/api/assessment-sessions", methods=["POST"])
def create_assessment_session_route():
    payload = request.get_json(silent=True)
    result = create_assessment_session_service(payload)
    return jsonify(result), 201


@app.route("/api/assessment-sessions/<int:session_id>/english-result", methods=["POST"])
def complete_english_result_route(session_id):
    payload = request.get_json(silent=True)
    result = complete_english_placement_result_service(session_id, payload)
    return jsonify(result), 200


@app.route("/api/assessment-sessions/<int:session_id>", methods=["GET"])
def get_assessment_session_route(session_id):
    result = get_assessment_session_detail_service(session_id)
    return jsonify(result), 200


@app.route("/api/users/<path:email>/assessment-history", methods=["GET"])
def get_user_assessment_history_route(email):
    page = request.args.get("page", default=1, type=int)
    page_size = request.args.get("pageSize", default=20, type=int)
    result = get_user_assessment_history_service(email, page, page_size)
    return jsonify(result), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
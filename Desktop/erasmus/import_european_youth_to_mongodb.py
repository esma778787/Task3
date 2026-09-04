#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

try:
    from pymongo import MongoClient
    from pymongo.errors import PyMongoError
except ImportError as exc:
    raise SystemExit(
        "Missing required dependency. Install with: pip install pymongo python-dotenv"
    ) from exc

DEFAULT_SOURCE_FILE = Path("european_youth_projects.json")


def get_env(name: str, default: str | None = None) -> str | None:
    value = os.getenv(name)
    if value is not None and value.strip() == "":
        value = None
    return value or default


def get_mongo_collection(uri: str, db_name: str, collection_name: str):
    client = MongoClient(uri, serverSelectionTimeoutMS=5000)
    db = client[db_name]
    return client, db[collection_name]


def load_project_file(source_path: Path) -> dict:
    if not source_path.exists():
        raise FileNotFoundError(f"Source file not found: {source_path}")

    with source_path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    if not isinstance(data, dict) or "projects" not in data:
        raise ValueError("Expected a JSON object with a top-level 'projects' list.")

    if not isinstance(data["projects"], list):
        raise ValueError("The top-level 'projects' field must be a list.")

    return data


def normalize_project(project: dict, default_source: str) -> dict:
    return {
        "sourceUrl": project.get("sourceUrl", "") or "",
        "sourceName": project.get("sourceName", default_source) or default_source,
        "sourceLanguage": project.get("sourceLanguage", "") or "",
        "language": project.get("language", "") or "",
        "recordType": project.get("recordType", "") or "",
        "isActiveOpportunity": bool(project.get("isActiveOpportunity", True)),
        "title": (project.get("title") or "").strip(),
        "description": (project.get("description") or "").strip(),
        "country": (project.get("country") or "").strip(),
        "town": (project.get("town") or "").strip(),
        "organisation": (project.get("organisation") or "").strip(),
        "duration": (project.get("duration") or "").strip(),
        "date_start": (project.get("date_start") or "").strip(),
        "date_end": (project.get("date_end") or "").strip(),
        "date_application_end": (project.get("date_application_end") or "").strip(),
        "applicationDeadline": (project.get("applicationDeadline") or "").strip(),
        "additionalFields": project.get("additionalFields", {}),
        "scrapedAt": project.get("scrapedAt", ""),
    }


def import_to_mongodb(
    uri: str,
    db_name: str,
    collection_name: str,
    source_path: Path,
    dry_run: bool,
) -> None:
    data = load_project_file(source_path)
    default_source = data.get("source", "European Youth Portal")
    projects = data["projects"]

    if dry_run:
        print(f"Dry run mode: {len(projects)} projects ready for import.")
        print("First 3 normalized records:")
        for project in projects[:3]:
            print(json.dumps(normalize_project(project, default_source), ensure_ascii=False, indent=2))
        return

    client, collection = get_mongo_collection(uri, db_name, collection_name)
    try:
        inserted = 0
        updated = 0
        skipped = 0

        for project in projects:
            source_url = (project.get("sourceUrl") or "").strip()
            if not source_url:
                skipped += 1
                continue

            normalized = normalize_project(project, default_source)
            result = collection.update_one(
                {"sourceUrl": source_url},
                {"$set": normalized},
                upsert=True,
            )

            if result.matched_count == 0 and result.upserted_id is not None:
                inserted += 1
            elif result.matched_count == 1:
                updated += 1
            else:
                updated += 1

        print(f"Import completed. inserted={inserted}, updated={updated}, skipped={skipped}.")
    except PyMongoError as exc:
        raise RuntimeError(f"MongoDB import failed: {exc}") from exc
    finally:
        client.close()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import European Youth scraped project data into MongoDB."
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE_FILE,
        help="Path to european_youth_projects.json source file.",
    )
    parser.add_argument(
        "--mongo-uri",
        type=str,
        default=None,
        help="MongoDB connection URI. If not set, reads MONGO_URI from environment.",
    )
    parser.add_argument(
        "--mongo-db",
        type=str,
        default=None,
        help="MongoDB database name. If not set, reads MONGO_DB_NAME from environment.",
    )
    parser.add_argument(
        "--mongo-collection",
        type=str,
        default=None,
        help="MongoDB collection name. If not set, reads MONGO_COLLECTION from environment.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate data and show sample documents without writing to MongoDB.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    mongo_uri = args.mongo_uri or get_env("MONGO_URI")
    if not mongo_uri:
        raise SystemExit("MONGO_URI is required. Set it via --mongo-uri or environment variable.")

    mongo_db = args.mongo_db or get_env("MONGO_DB_NAME", "erasmusdb")
    mongo_collection = args.mongo_collection or get_env("MONGO_COLLECTION", "european_youth_projects")

    import_to_mongodb(
        uri=mongo_uri,
        db_name=mongo_db,
        collection_name=mongo_collection,
        source_path=args.source,
        dry_run=args.dry_run,
    )


if __name__ == "__main__":
    main()

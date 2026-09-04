import glob
import os
import pathlib
import re
import sys

from database import get_mssql_connection, load_env_from_file


def run_migrations():
    load_env_from_file()
    sql_dir = pathlib.Path(__file__).resolve().parent / "sql"
    sql_files = sorted(sql_dir.glob("*.sql"))

    if not sql_files:
        print("No SQL migration files found.")
        return 0

    conn = get_mssql_connection()
    try:
        conn.autocommit = False
        cursor = conn.cursor()

        for sql_file in sql_files:
            print(f"Applying migration: {sql_file.name}")
            with sql_file.open("r", encoding="utf-8") as fp:
                sql_text = fp.read()

            batches = [batch.strip() for batch in re.split(r"(?im)^\s*GO\s*$", sql_text) if batch.strip()]
            for index, batch in enumerate(batches, start=1):
                print(f"  Applying batch {index}/{len(batches)}")
                cursor.execute(batch)

        conn.commit()
        print("Migrations completed successfully.")
        return 0
    except Exception as exc:
        conn.rollback()
        print("Migration failed:", exc)
        return 1
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(run_migrations())

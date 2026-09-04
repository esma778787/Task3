from contextlib import closing
from typing import Optional
import os

import pyodbc
import pymongo

from database import load_env_from_file, get_mssql_connection

load_env_from_file()

mongo_uri = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
mongo_db = os.getenv("MONGO_DB_NAME", "erasmus_db")
mongo_collection_name = os.getenv("MONGO_COLLECTION", "erasmusgram_projects")

mongo_client = pymongo.MongoClient(mongo_uri)
mongo_db = mongo_client[mongo_db]
mongo_collection = mongo_db[mongo_collection_name]

def try_connect() -> Optional[pyodbc.Connection]:
    try:
        conn = get_mssql_connection()
        print("✅  MSSQL bağlantısı başarılı.")
        return conn
    except Exception as exc:
        print("❌ MSSQL bağlantı hatası ⇒", exc)
        return None

conn = try_connect()
if conn is None:
    raise RuntimeError("MSSQL'e bağlanılamadı; betik sonlandırıldı.")

try:
    with closing(conn) as mssql_conn:

        with closing(mssql_conn.cursor()) as cur:
            mongo_count = mongo_collection.count_documents({})
            print(f"📦 MongoDB kayıt sayısı: {mongo_count}")

            inserted = 0
            updated = 0
            skipped = 0

            for doc in mongo_collection.find({}, {"title": 1, "link": 1, "content": 1}):
                title = (doc.get("title") or "").strip()
                link = (doc.get("link") or "").strip()
                description = (doc.get("content") or "").strip()

                if not (title and link):
                    skipped += 1
                    continue

                cur.execute(
                    "SELECT 1 FROM dbo.Projects WHERE Link = ?;",
                    link
                )
                if cur.fetchone():
                    cur.execute(
                        """
                        UPDATE dbo.Projects
                        SET Title = ?, Description = ?
                        WHERE Link = ?;
                        """,
                        title, description, link
                    )
                    updated += 1
                else:
                    cur.execute(
                        """
                        INSERT INTO dbo.Projects (Title, Link, Description)
                        VALUES (?, ?, ?);
                        """,
                        title, link, description
                    )
                    inserted += 1

            mssql_conn.commit()
            print(f"✅  Aktarılan yeni kayıt sayısı: {inserted}")
            print(f"✅  Güncellenen kayıt sayısı: {updated}")
            print(f"⏭️  Atlanan kayıt sayısı: {skipped}")

except pyodbc.Error as e:
    print("❌ ODBC/SQL hatası:", e)
except Exception as e:
    print("❌ Genel hata   :", e)
finally:
    mongo_client.close()

import os
from pathlib import Path
import pyodbc
from typing import Optional

DEFAULT_ENV_PATH = Path(".env")


def _parse_env_line(line: str):
    if "#" in line:
        line = line.split("#", 1)[0]
    if "=" not in line:
        return None, None
    key, value = line.split("=", 1)
    return key.strip(), value.strip().strip('"').strip("'")


def load_env_from_file(env_path: Path = DEFAULT_ENV_PATH, overwrite: bool = False):
    if not env_path.exists():
        return

    with env_path.open("r", encoding="utf-8") as env_file:
        for raw_line in env_file:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue

            key, value = _parse_env_line(line)
            if not key:
                continue

            if overwrite or key not in os.environ:
                os.environ[key] = value


def _normalize_driver(driver: str) -> str:
    driver = driver.strip()
    if not driver.startswith("{") and not driver.endswith("}"):
        return f"{{{driver}}}"
    return driver


def get_env(name: str, default: Optional[str] = None, required: bool = False) -> Optional[str]:
    value = os.getenv(name, default)
    if required and (value is None or value.strip() == ""):
        raise EnvironmentError(f"Required environment variable '{name}' is not set.")
    return value


def get_mssql_connection():
    load_env_from_file()

    driver = _normalize_driver(get_env("SQL_DRIVER", "ODBC Driver 17 for SQL Server", required=True))
    server = get_env("SQL_SERVER", required=True)
    database = get_env("SQL_DATABASE", required=True)
    auth_mode = get_env("SQL_AUTH_MODE", "windows").strip().lower()
    encrypt = get_env("SQL_ENCRYPT", "no")
    trust_server_certificate = get_env("SQL_TRUST_SERVER_CERTIFICATE", "yes")

    conn_parts = [
        f"DRIVER={driver}",
        f"SERVER={server}",
        f"DATABASE={database}",
        f"Encrypt={encrypt}",
        f"TrustServerCertificate={trust_server_certificate}",
    ]

    if auth_mode == "windows":
        conn_parts.insert(3, "Trusted_Connection=yes")
    elif auth_mode == "sql":
        username = get_env("SQL_USERNAME", required=True)
        password = get_env("SQL_PASSWORD", required=True)
        conn_parts.insert(3, f"UID={username}")
        conn_parts.insert(4, f"PWD={password}")
    else:
        raise EnvironmentError(
            "Invalid SQL_AUTH_MODE value. Expected 'windows' or 'sql'."
        )

    conn_str = ";".join(conn_parts) + ";"
    return pyodbc.connect(conn_str, timeout=5)

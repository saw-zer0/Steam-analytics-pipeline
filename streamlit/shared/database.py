import os
from typing import Any

from dotenv import load_dotenv
import pandas as pd
import psycopg2


load_dotenv()


def get_connection() -> psycopg2.extensions.connection:
    return psycopg2.connect(
        host=os.getenv("STREAMLIT_PGHOST", "localhost"),
        port=os.getenv("STREAMLIT_PGPORT", "5432"),
        dbname=os.getenv("STREAMLIT_PGDATABASE", "steam_dw"),
        user=os.getenv("STREAMLIT_PGUSER", "postgres"),
        password=os.getenv("STREAMLIT_PGPASSWORD", "admin"),
    )


def run_query(query: str, params: tuple[Any, ...] = ()) -> pd.DataFrame:
    with get_connection() as connection:
        return pd.read_sql_query(query, connection, params=params)
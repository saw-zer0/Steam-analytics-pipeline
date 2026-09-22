from pathlib import Path
import os

import pandas as pd
import psycopg2
from dotenv import load_dotenv
from psycopg2.extras import execute_batch


PROJECT_ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = PROJECT_ROOT / "data/raw" / "games.csv"
BATCH_SIZE = 1_000

CSV_COLUMNS = (
    "AppID",
    "Name",
    "Release date",
    "Estimated owners",
    "Peak CCU",
    "Required age",
    "Price",
    "Discount",
    "DLC count",
    "About the game",
    "Supported languages",
    "Full audio languages",
    "Reviews",
    "Header image",
    "Website",
    "Support url",
    "Support email",
    "Windows",
    "Mac",
    "Linux",
    "Metacritic score",
    "Metacritic url",
    "User score",
    "Positive",
    "Negative",
    "Score rank",
    "Achievements",
    "Recommendations",
    "Notes",
    "Average playtime forever",
    "Average playtime two weeks",
    "Median playtime forever",
    "Median playtime two weeks",
    "Developers",
    "Publishers",
    "Categories",
    "Genres",
    "Tags",
    "Screenshots",
    "Movies",
)

DB_COLUMNS = (
    "app_id",
    "name",
    "release_date",
    "estimated_owners",
    "peak_ccu",
    "required_age",
    "price",
    "discount",
    "dlc_count",
    "about_the_game",
    "supported_languages",
    "full_audio_languages",
    "reviews",
    "header_image",
    "website",
    "support_url",
    "support_email",
    "windows",
    "mac",
    "linux",
    "metacritic_score",
    "metacritic_url",
    "user_score",
    "positive",
    "negative",
    "score_rank",
    "achievements",
    "recommendations",
    "notes",
    "average_playtime_forever",
    "average_playtime_two_weeks",
    "median_playtime_forever",
    "median_playtime_two_weeks",
    "developers",
    "publishers",
    "categories",
    "genres",
    "tags",
    "screenshots",
    "movies",
)

INSERT_SQL = f"""
    INSERT INTO public.steam_games ({', '.join(DB_COLUMNS)})
    VALUES ({', '.join(['%s'] * len(DB_COLUMNS))})
    ON CONFLICT (app_id) DO UPDATE SET
        {', '.join(f'{column} = EXCLUDED.{column}' for column in DB_COLUMNS[1:])}
"""


def get_connection()->psycopg2.extensions.connection:
    load_dotenv(PROJECT_ROOT / ".env")
    required_settings: dict[str, str | None] = {
        "host": os.getenv("PGHOST", "localhost"),
        "port": os.getenv("PGPORT", "5432"),
        "dbname": os.getenv("PGDATABASE"),
        "user": os.getenv("PGUSER"),
        "password": os.getenv("PGPASSWORD"),
    }
    missing_settings = [
        name for name, value in required_settings.items() if not value
    ]
    if missing_settings:
        raise RuntimeError(
            "Missing PostgreSQL environment variables: "
            + ", ".join(missing_settings)
        )

    try:
        return psycopg2.connect(**required_settings)
    except psycopg2.Error as exc:
        raise RuntimeError(f"Failed to connect to PostgreSQL: {exc}") from exc


def load_csv_in_batches() -> int:
    total_rows = 0
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                for chunk in pd.read_csv(CSV_PATH, chunksize=BATCH_SIZE, engine='python'):
                    if tuple(chunk.columns) != CSV_COLUMNS:
                        raise ValueError("CSV columns do not match the expected schema")

                    rows = chunk.astype(object).where(pd.notna(chunk), None)
                    execute_batch(
                        cursor,
                        INSERT_SQL,
                        rows.itertuples(index=False, name=None),
                        page_size=BATCH_SIZE,
                    )
                    total_rows += len(chunk)
                    print(f"Loaded {total_rows} rows")
    except psycopg2.Error as exc:
        raise RuntimeError(f"Database error while loading CSV: {exc}") from exc
    return total_rows


def main() -> None:
    try:
        loaded_rows = load_csv_in_batches()
        print(f"Finished loading {loaded_rows} rows into public.steam_games")
    except (RuntimeError, ValueError) as exc:
        print(f"Error: {exc}")


if __name__ == "__main__":
    main()
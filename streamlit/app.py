import os

import psycopg2
import streamlit as st

from shared import database
from tabs import category, genre, price, publisher, release_date


st.set_page_config(
    page_title="Steam Games Insights",
    layout="wide",
)


def main() -> None:
    st.title("Steam Games Insights")
    st.caption(
        "Price analysis and popularity rankings from the dbt mart layer"
    )

    schema = os.getenv("STEAM_DBT_MART_SCHEMA", "dbt_marts")
    price_tab, genre_tab, category_tab, publisher_tab, release_date_tab = st.tabs(
        ["Price", "Genre", "Category", "Publisher", "Release date"]
    )

    with release_date_tab:
        release_grain = release_date.select_grain()

    try:
        price_data = price.load_data(schema)
        genre_data = genre.load_data(schema)
        category_data = category.load_data(schema)
        publisher_games_data = publisher.load_data(
            schema, "games_with_publisher"
        )
        self_published_data = publisher.load_data(schema, "self_published")
        release_date_data = release_date.load_data(schema, release_grain)
    except psycopg2.Error as exc:
        st.error("Could not connect to the Steam warehouse.")
        st.code(str(exc))
        st.info(
            "Check STREAMLIT_PGHOST, STREAMLIT_PGPORT, STREAMLIT_PGDATABASE, "
            "STREAMLIT_PGUSER, and STREAMLIT_PGPASSWORD."
        )
        return

    with price_tab:
        price.render(price_data)

    with genre_tab:
        genre.render(genre_data)

    with category_tab:
        category.render(category_data)

    with publisher_tab:
        publisher.render(publisher_games_data, self_published_data)

    with release_date_tab:
        release_date.render(release_date_data, release_grain)


if __name__ == "__main__":
    main()
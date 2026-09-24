import pandas as pd
import streamlit as st

from shared.database import run_query


GRAINS = ["Month", "Year", "Decade", "Quarter", "Week"]


def select_grain() -> str:
    return st.selectbox("Group releases by", GRAINS)


def load_data(schema: str, grain: str) -> pd.DataFrame:
    grain_sql = {
        "Month": {
            "label": "to_char(min(dates.full_date), 'YYYY-Mon')",
            "group_by": "dates.year, dates.month",
        },
        "Year": {
            "label": "dates.year::text",
            "group_by": "dates.year",
        },
        "Decade": {
            "label": "dates.decade::text || 's'",
            "group_by": "dates.decade",
        },
        "Quarter": {
            "label": "dates.year::text || '-Q' || dates.quarter::text",
            "group_by": "dates.year, dates.quarter",
        },
        "Week": {
            "label": "dates.year::text || '-W' || lpad(dates.week::text, 2, '0')",
            "group_by": "dates.year, dates.week",
        },
    }
    selected_grain = grain_sql[grain]
    query = f"""
        select
            {selected_grain["label"]} as release_period,
            count(distinct games.game_sk) as game_count
        from {schema}.dim_game as games
        join {schema}.dim_date as dates
            on games.date_key = dates.date_key
        where dates.full_date is not null
        group by {selected_grain["group_by"]}
        order by min(dates.full_date)
    """
    return run_query(query)


def render(data: pd.DataFrame, grain: str) -> None:
    st.subheader(f"Games released by {grain.lower()}")
    st.line_chart(
        data=data,
        x="release_period",
        y="game_count",
        x_label=f"Release {grain.lower()}",
        y_label="Games released",
    )
    st.dataframe(
        data[["release_period", "game_count"]],
        hide_index=True,
        use_container_width=True,
    )
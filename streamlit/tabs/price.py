import pandas as pd
import streamlit as st

from shared.database import run_query


def load_data(schema: str) -> pd.DataFrame:
    query = f"""
        select
            case
                when price = 0 then 'Free'
                when price < 5 then '$0.01-$4.99'
                when price < 10 then '$5.00-$9.99'
                when price < 15 then '$10.00-$14.99'
                when price < 20 then '$15.00-$19.99'
                when price < 30 then '$20.00-$29.99'
                when price < 50 then '$30.00-$49.99'
                else '$50.00+'
            end as price_band,
            case
                when price = 0 then 0
                when price < 5 then 1
                when price < 10 then 2
                when price < 15 then 3
                when price < 20 then 4
                when price < 30 then 5
                when price < 50 then 6
                else 7
            end as band_order,
            count(distinct game_sk) as game_count
        from {schema}.fct_game_metrics
        where price is not null and price >= 0
        group by price_band, band_order
        order by band_order
    """
    return run_query(query)


def render(data: pd.DataFrame) -> None:
    st.subheader("Games by price band")
    st.bar_chart(
        data=data.sort_values("band_order"),
        x="price_band",
        y="game_count",
        sort="band_order",
        x_label="Price band",
        y_label="Games",
    )
    st.dataframe(
        data[["price_band", "game_count"]],
        hide_index=True,
        use_container_width=True,
    )
import pandas as pd
import streamlit as st


def popularity_cte(schema: str) -> str:
    return f"""
        with base_metrics as (
            select
                metrics.game_sk,
                ln(1 + coalesce(metrics.peak_ccu, 0)) as peak_ccu_value,
                ln(1 + coalesce(metrics.positive, 0)) as positive_value,
                ln(1 + coalesce(metrics.recommendations, 0)) as recommendations_value,
                coalesce(
                    metrics.positive::numeric
                    / nullif(metrics.positive + metrics.negative, 0),
                    0
                ) as sentiment_value,
                ln(1 + coalesce(owners.max_owners, owners.min_owners, 0))
                    as owners_value
            from {schema}.fct_game_metrics as metrics
            left join {schema}.dim_estimated_owners as owners
                on metrics.estimated_owners_sk = owners.estimated_owners_sk
        ),
        ranked_metrics as (
            select
                *,
                percent_rank() over (order by peak_ccu_value) as peak_ccu_rank,
                percent_rank() over (order by positive_value) as positive_rank,
                percent_rank() over (order by recommendations_value)
                    as recommendations_rank,
                percent_rank() over (order by owners_value) as owners_rank
            from base_metrics
        ),
        popularity as (
            select
                game_sk,
                100 * (
                    0.35 * peak_ccu_rank
                    + 0.20 * positive_rank
                    + 0.15 * recommendations_rank
                    + 0.10 * sentiment_value
                    + 0.20 * owners_rank
                ) as popularity_score
            from ranked_metrics
        )
    """


def render_ranking_tab(
    data: pd.DataFrame,
    name_column: str,
    title: str,
) -> None:
    st.subheader(title)
    st.bar_chart(
        data,
        x=name_column,
        y="popularity_score",
        sort="popularity_score",
        x_label=name_column.replace("_", " ").title(),
        y_label="Popularity score",
    )
    st.dataframe(data, hide_index=True, use_container_width=True)
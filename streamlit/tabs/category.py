import pandas as pd

from shared.database import run_query
from shared.popularity import popularity_cte, render_ranking_tab


def load_data(schema: str) -> pd.DataFrame:
    query = popularity_cte(schema) + """
        , category_scores as (
            select
                categories.category_name,
                round(avg(popularity.popularity_score)::numeric, 2)
                    as popularity_score,
                count(distinct popularity.game_sk) as game_count
            from popularity
            join (
                select distinct game_sk, category_sk
                from {schema}.bridge_game_category
            ) as game_categories
                on popularity.game_sk = game_categories.game_sk
            join {schema}.dim_category as categories
                on game_categories.category_sk = categories.category_sk
            group by categories.category_name
            having count(distinct popularity.game_sk) >= 5
        ), ranked_groups as (
            select
                rank() over (order by popularity_score desc, game_count desc) as rank,
                category_name,
                popularity_score,
                game_count
            from category_scores
        )
        select rank, category_name, popularity_score, game_count
        from ranked_groups
        order by rank, category_name
    """
    return run_query(query.format(schema=schema))


def render(data: pd.DataFrame) -> None:
    render_ranking_tab(data, "category_name", "Popularity by category")
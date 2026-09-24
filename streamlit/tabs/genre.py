import pandas as pd

from shared.database import run_query
from shared.popularity import popularity_cte, render_ranking_tab


def load_data(schema: str) -> pd.DataFrame:
    query = popularity_cte(schema) + """
        , genre_scores as (
            select
                genres.genre_name,
                round(avg(popularity.popularity_score)::numeric, 2)
                    as popularity_score,
                count(distinct popularity.game_sk) as game_count
            from popularity
            join (
                select distinct game_sk, genre_sk
                from {schema}.bridge_game_genre
            ) as game_genres
                on popularity.game_sk = game_genres.game_sk
            join {schema}.dim_genre as genres
                on game_genres.genre_sk = genres.genre_sk
            group by genres.genre_name
            having count(distinct popularity.game_sk) >= 5
        ), ranked_groups as (
            select
                rank() over (order by popularity_score desc, game_count desc) as rank,
                genre_name,
                popularity_score,
                game_count
            from genre_scores
        )
        select rank, genre_name, popularity_score, game_count
        from ranked_groups
        order by rank, genre_name
    """
    return run_query(query.format(schema=schema))


def render(data: pd.DataFrame) -> None:
    render_ranking_tab(data, "genre_name", "Popularity by genre")
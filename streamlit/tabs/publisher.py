import pandas as pd

from shared.database import run_query
from shared.popularity import popularity_cte, render_ranking_tab


def load_data(schema: str, publication_type: str) -> pd.DataFrame:
    query = popularity_cte(schema) + """
        , publisher_games as (
            select distinct
                game_publishers.game_sk,
                game_publishers.publisher_sk,
                publishers.publisher_name,
                case
                    when exists (
                        select 1
                        from {schema}.bridge_game_developer as game_developers
                        join {schema}.dim_developer as developers
                            on game_developers.developer_sk = developers.developer_sk
                        where game_developers.game_sk = game_publishers.game_sk
                          and lower(trim(developers.developer_name)) =
                              lower(trim(publishers.publisher_name))
                    ) then 'self_published'
                    when exists (
                        select 1
                        from {schema}.bridge_game_developer as game_developers
                        where game_developers.game_sk = game_publishers.game_sk
                    ) then 'games_with_publisher'
                    else 'unknown_developer'
                end as publication_type
            from {schema}.bridge_game_publisher as game_publishers
            join {schema}.dim_publisher as publishers
                on game_publishers.publisher_sk = publishers.publisher_sk
        ), publisher_scores as (
            select
                publishers.publisher_name,
                round(avg(popularity.popularity_score)::numeric, 2)
                    as popularity_score,
                count(distinct popularity.game_sk) as game_count
            from popularity
            join publisher_games as publishers
                on popularity.game_sk = publishers.game_sk
            where publishers.publication_type = %s
            group by publishers.publisher_name
            having count(distinct popularity.game_sk) >= 5
        ), ranked_groups as (
            select
                rank() over (order by popularity_score desc, game_count desc) as rank,
                publisher_name,
                popularity_score,
                game_count
            from publisher_scores
        )
        select rank, publisher_name, popularity_score, game_count
        from ranked_groups
        order by rank, publisher_name
    """
    return run_query(query.format(schema=schema), (publication_type,))


def render(
    games_with_publisher: pd.DataFrame,
    self_published: pd.DataFrame,
) -> None:
    render_ranking_tab(
        games_with_publisher,
        "publisher_name",
        "Games with publisher",
    )
    render_ranking_tab(self_published, "publisher_name", "Self-published")
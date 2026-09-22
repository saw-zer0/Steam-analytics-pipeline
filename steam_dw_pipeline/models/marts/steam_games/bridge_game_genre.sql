-- depends_on: {{ ref('dim_game') }}
-- depends_on: {{ ref('dim_genre') }}

select
    games.game_sk,
    genres.genre_sk
from {{ ref('stg_game_genres') }} as links
join {{ ref('dim_game') }} as games using (app_id)
join {{ ref('dim_genre') }} as genres using (genre_id)

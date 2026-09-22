-- depends_on: {{ ref('dim_game') }}
-- depends_on: {{ ref('dim_developer') }}

select
    games.game_sk,
    developers.developer_sk
from {{ ref('stg_game_developers') }} as links
join {{ ref('dim_game') }} as games using (app_id)
join {{ ref('dim_developer') }} as developers using (developer_id)

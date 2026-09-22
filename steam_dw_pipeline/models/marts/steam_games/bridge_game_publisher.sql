-- depends_on: {{ ref('dim_game') }}
-- depends_on: {{ ref('dim_publisher') }}

select
    games.game_sk,
    publishers.publisher_sk
from {{ ref('stg_game_publishers') }} as links
join {{ ref('dim_game') }} as games using (app_id)
join {{ ref('dim_publisher') }} as publishers using (publisher_id)

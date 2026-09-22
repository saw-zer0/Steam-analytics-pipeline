-- depends_on: {{ ref('dim_game') }}
-- depends_on: {{ ref('dim_tag') }}

select
    games.game_sk,
    tags.tag_sk
from {{ ref('stg_game_tags') }} as links
join {{ ref('dim_game') }} as games using (app_id)
join {{ ref('dim_tag') }} as tags using (tag_id)

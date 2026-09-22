-- depends_on: {{ ref('dim_game') }}
-- depends_on: {{ ref('dim_category') }}

select
    games.game_sk,
    categories.category_sk
from {{ ref('stg_game_categories') }} as links
join {{ ref('dim_game') }} as games using (app_id)
join {{ ref('dim_category') }} as categories using (category_id)

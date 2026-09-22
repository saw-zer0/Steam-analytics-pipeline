-- depends_on: {{ ref('dim_game') }}
-- depends_on: {{ ref('dim_language') }}

select
    games.game_sk,
    languages.language_sk
from {{ ref('stg_game_full_audio_languages') }} as links
join {{ ref('dim_game') }} as games using (app_id)
join {{ ref('dim_language') }} as languages using (language_id)

select
    app_id,
    name,
    dates.date_key,
    required_age,
    about_the_game,
    website,
    support_url,
    support_email,
    linux,
    windows,
    mac
from {{ ref('stg_games') }} as games
left join {{ ref('dim_date') }} as dates
    on games.release_date = dates.full_date

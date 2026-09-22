with metrics as (
    select
        current_date as snapshot_date,
        app_id,
        estimated_owners_id,
        peak_ccu,
        price,
        discount,
        metacritic_score as metacritic,
        user_score,
        positive,
        negative,
        achievements,
        recommendations
    from {{ ref('stg_games') }}
)

select
    snapshot_date,
    games.game_sk,
    metrics.app_id,
    owners.estimated_owners_sk,
    peak_ccu,
    price,
    discount,
    metacritic,
    user_score,
    positive,
    negative,
    achievements,
    recommendations
from metrics
join {{ ref('dim_game') }} as games on metrics.app_id = games.app_id
left join {{ ref('dim_estimated_owners') }} as owners
    on metrics.estimated_owners_id = owners.estimated_owners_id

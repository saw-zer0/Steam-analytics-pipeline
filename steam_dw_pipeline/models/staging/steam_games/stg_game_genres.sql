with values as (
    select
        app_id,
        trim(genre_name) as genre_name
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(genres, ''), '\s*,\s*') as genre_name
)

select distinct
    app_id,
    genres.genre_id
from values
join {{ ref('stg_genres') }} as genres
    on lower(genres.genre_name) = lower(values.genre_name)
where values.genre_name <> ''
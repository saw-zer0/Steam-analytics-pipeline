with values as (
    select
        app_id,
        trim(genre_name) as genre_name
    from {{ ref('stg_games') }}
    cross join lateral regexp_split_to_table(coalesce(genres, ''), '\s*,\s*') as genre_name
)

select distinct
    app_id,
    md5(lower(genre_name)) as genre_id
from values
where genre_name <> ''
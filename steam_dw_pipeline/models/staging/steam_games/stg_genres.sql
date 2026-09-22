with values as (
    select trim(genre_name) as genre_name
    from {{ ref('stg_games') }}
    cross join lateral regexp_split_to_table(coalesce(genres, ''), '\s*,\s*') as genre_name
)

select
    md5(lower(genre_name)) as genre_id,
    genre_name
from values
where genre_name <> ''
group by genre_name
with values as (
    select trim(genre_name) as genre_name
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(genres, ''), '\s*,\s*') as genre_name
)

select
    genre_name
from values
where genre_name <> ''
group by genre_name
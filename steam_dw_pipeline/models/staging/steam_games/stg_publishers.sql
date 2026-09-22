with values as (
    select
        trim(publisher_name) as publisher_name,
        lower(trim(publisher_name)) as publisher_key
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(publishers, ''), '\s*,\s*') as publisher_name
)

select
    min(publisher_name) as publisher_name
from values
where publisher_name <> ''
group by publisher_key
with values as (
    select trim(publisher_name) as publisher_name
    from {{ ref('stg_games') }}
    cross join lateral regexp_split_to_table(coalesce(publishers, ''), '\s*,\s*') as publisher_name
)

select
    md5(lower(publisher_name)) as publisher_id,
    publisher_name
from values
where publisher_name <> ''
group by publisher_name
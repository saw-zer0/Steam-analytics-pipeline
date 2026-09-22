with values as (
    select
        app_id,
        trim(publisher_name) as publisher_name
    from {{ ref('stg_games') }}
    cross join lateral regexp_split_to_table(coalesce(publishers, ''), '\s*,\s*') as publisher_name
)

select distinct
    app_id,
    md5(lower(publisher_name)) as publisher_id
from values
where publisher_name <> ''
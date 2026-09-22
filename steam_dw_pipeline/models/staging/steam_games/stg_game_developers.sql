with values as (
    select
        app_id,
        trim(developer_name) as developer_name
    from {{ ref('stg_games') }}
    cross join lateral regexp_split_to_table(coalesce(developers, ''), '\s*,\s*') as developer_name
)

select distinct
    app_id,
    md5(lower(developer_name)) as developer_id
from values
where developer_name <> ''
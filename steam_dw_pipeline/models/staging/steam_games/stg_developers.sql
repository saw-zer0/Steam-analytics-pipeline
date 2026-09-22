with values as (
    select trim(developer_name) as developer_name
    from {{ ref('stg_games') }}
    cross join lateral regexp_split_to_table(coalesce(developers, ''), '\s*,\s*') as developer_name
)

select
    md5(lower(developer_name)) as developer_id,
    developer_name
from values
where developer_name <> ''
group by developer_name
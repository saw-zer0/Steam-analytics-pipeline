with values as (
    select
        trim(developer_name) as developer_name,
        lower(trim(developer_name)) as developer_key
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(developers, ''), '\s*,\s*') as developer_name
)

select
    min(developer_name) as developer_name
from values
where developer_name <> ''
group by developer_key
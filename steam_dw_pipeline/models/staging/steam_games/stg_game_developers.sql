with values as (
    select
        app_id,
        trim(developer_name) as developer_name
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(developers, ''), '\s*,\s*') as developer_name
)

select distinct
    app_id,
    developers.developer_id
from values
join {{ ref('stg_developers') }} as developers
    on lower(developers.developer_name) = lower(values.developer_name)
where values.developer_name <> ''
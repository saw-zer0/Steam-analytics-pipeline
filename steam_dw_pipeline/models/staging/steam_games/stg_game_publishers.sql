with values as (
    select
        app_id,
        trim(publisher_name) as publisher_name
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(publishers, ''), '\s*,\s*') as publisher_name
)

select distinct
    app_id,
    publishers.publisher_id
from values
join {{ ref('stg_publishers') }} as publishers
    on lower(publishers.publisher_name) = lower(values.publisher_name)
where values.publisher_name <> ''
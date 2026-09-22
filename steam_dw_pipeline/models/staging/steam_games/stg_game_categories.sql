with values as (
    select
        app_id,
        trim(category_name) as category_name
    from {{ ref('stg_games') }}
    cross join lateral regexp_split_to_table(coalesce(categories, ''), '\s*,\s*') as category_name
)

select distinct
    app_id,
    md5(lower(category_name)) as category_id
from values
where category_name <> ''
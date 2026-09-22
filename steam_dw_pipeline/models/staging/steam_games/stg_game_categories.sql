with values as (
    select
        app_id,
        trim(category_name) as category_name
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(categories, ''), '\s*,\s*') as category_name
)

select distinct
    app_id,
    categories.category_id
from values
join {{ ref('stg_categories') }} as categories
    on lower(categories.category_name) = lower(values.category_name)
where values.category_name <> ''
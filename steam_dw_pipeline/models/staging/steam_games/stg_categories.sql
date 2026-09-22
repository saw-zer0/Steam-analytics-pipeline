with values as (
    select trim(category_name) as category_name
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(categories, ''), '\s*,\s*') as category_name
)

select
    category_name
from values
where category_name <> ''
group by category_name
with values as (
    select trim(tag_name) as tag_name
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(tags, ''), '\s*,\s*') as tag_name
)

select
    tag_name
from values
where tag_name <> ''
group by tag_name
with values as (
    select
        app_id,
        trim(tag_name) as tag_name
    from {{ ref('raw_games') }}
    cross join lateral regexp_split_to_table(coalesce(tags, ''), '\s*,\s*') as tag_name
)

select distinct
    app_id,
    tags.tag_id
from values
join {{ ref('stg_tags') }} as tags
    on lower(tags.tag_name) = lower(values.tag_name)
where values.tag_name <> ''
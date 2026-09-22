with values as (
    select
        app_id,
        trim(tag_name) as tag_name
    from {{ ref('stg_games') }}
    cross join lateral regexp_split_to_table(coalesce(tags, ''), '\s*,\s*') as tag_name
)

select distinct
    app_id,
    md5(lower(tag_name)) as tag_id
from values
where tag_name <> ''
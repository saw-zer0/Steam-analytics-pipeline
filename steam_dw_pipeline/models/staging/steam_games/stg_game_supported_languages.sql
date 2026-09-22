with language_values as (
    select
        app_id,
        regexp_replace(coalesce(supported_languages, ''), '^\[|\]$', '', 'g') as languages
    from {{ ref('stg_games') }}
),
cleaned_languages as (
    select
        app_id,
        trim(both ' ''"' from language_name) as language_name
    from language_values
    cross join lateral regexp_split_to_table(languages, '\s*,\s*') as language_name
)

select distinct
    app_id,
    md5(lower(language_name)) as language_id
from cleaned_languages
where language_name <> ''
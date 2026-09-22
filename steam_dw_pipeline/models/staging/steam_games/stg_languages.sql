with language_values as (
    select supported_languages as languages
    from {{ ref('stg_games') }}
    union all
    select full_audio_languages as languages
    from {{ ref('stg_games') }}
),
cleaned_languages as (
    select
        trim(both ' ''"' from language_name) as language_name
    from language_values
    cross join lateral regexp_split_to_table(
        regexp_replace(coalesce(languages, ''), '^\[|\]$', '', 'g'),
        '\s*,\s*'
    ) as language_name
)

select
    md5(lower(language_name)) as language_id,
    language_name
from cleaned_languages
where language_name <> ''
group by language_name
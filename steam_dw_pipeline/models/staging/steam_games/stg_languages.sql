with language_values as (
    select supported_languages as languages
    from {{ ref('raw_games') }}
    union all
    select full_audio_languages as languages
    from {{ ref('raw_games') }}
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
    language_name
from cleaned_languages
where language_name <> ''
group by language_name
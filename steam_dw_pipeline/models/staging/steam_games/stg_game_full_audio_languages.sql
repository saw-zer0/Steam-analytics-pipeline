with language_values as (
    select
        app_id,
        regexp_replace(coalesce(full_audio_languages, ''), '^\[|\]$', '', 'g') as languages
    from {{ ref('raw_games') }}
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
    languages.language_id
from cleaned_languages
join {{ ref('stg_languages') }} as languages
    on lower(languages.language_name) = lower(cleaned_languages.language_name)
where cleaned_languages.language_name != ''
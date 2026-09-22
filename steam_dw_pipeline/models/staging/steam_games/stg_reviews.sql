with source_reviews as (
    select
        app_id,
        nullif(trim(reviews), '') as reviews
    from {{ ref('raw_games') }}
),
parsed_reviews as (
    select
        app_id,
        row_number() over (
            partition by app_id
            order by match[1]
        )::integer as review_ordinal,
        match[1] as review_text,
        match[2]::numeric as rating,
        trim(match[3]) as source
    from source_reviews
    cross join lateral regexp_matches(
        reviews,
        '“([^”]+)”\s+([0-9]+(?:\.[0-9]+)?)/10\s*[–-]\s*([^“]+?)(?=\s+“|$)',
        'g'
    ) as match
),
unparsed_reviews as (
    select
        app_id,
        1 as review_ordinal,
        reviews as review_text,
        null::numeric as rating,
        null::text as source
    from source_reviews
    where reviews is not null
      and not exists (
          select 1
          from parsed_reviews
          where parsed_reviews.app_id = source_reviews.app_id
      )
)

select
    app_id,
    review_ordinal,
    review_text,
    rating,
    source
from parsed_reviews

union all

select
    app_id,
    review_ordinal,
    review_text,
    rating,
    source
from unparsed_reviews
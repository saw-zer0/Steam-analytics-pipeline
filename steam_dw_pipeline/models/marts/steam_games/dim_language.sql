select
    language_id,
    language_name
from {{ ref('stg_languages') }}

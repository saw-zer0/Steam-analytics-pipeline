select
    tag_id,
    tag_name
from {{ ref('stg_tags') }}

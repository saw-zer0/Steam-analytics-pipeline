select
    publisher_id,
    publisher_name
from {{ ref('stg_publishers') }}

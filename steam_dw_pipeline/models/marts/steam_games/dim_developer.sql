select
    developer_id,
    developer_name
from {{ ref('stg_developers') }}

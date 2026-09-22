select
    estimated_owners_id,
    estimated_owners,
    min_owners,
    max_owners,
    estimated_owners_label
from {{ ref('stg_estimated_owners') }}

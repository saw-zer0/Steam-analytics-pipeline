with owner_ranges as (
    select distinct
        estimated_owners,
        replace(split_part(estimated_owners, '-', 1), ',', '')::bigint as min_owners,
        replace(split_part(estimated_owners, '-', 2), ',', '')::bigint as max_owners
    from {{ ref('raw_games') }}
    where estimated_owners is not null
),
 labeled_ranges as (
    select
        estimated_owners,
        min_owners,
        max_owners,
        case
            when max_owners = 0 then 'No owners'
            else estimated_owners || ' owners'
        end as estimated_owners_label
    from owner_ranges
)

select
    estimated_owners,
    min_owners,
    max_owners,
    estimated_owners_label
from labeled_ranges
with calendar as (
    select generate_series(
        date '1960-01-01',
        current_date,
        interval '1 day'
    )::date as full_date
)

select
    to_char(full_date, 'YYYYMMDD') as date_key,
    full_date,
    extract(year from full_date)::integer as year,
    (extract(year from full_date)::integer / 10) * 10 as decade,
    extract(quarter from full_date)::integer as quarter,
    extract(month from full_date)::integer as month,
    to_char(full_date, 'FMMonth') as month_name,
    extract(week from full_date)::integer as week,
    to_char(full_date, 'FMDay') as day_name
from calendar

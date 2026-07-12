with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2022-01-01' as date)",
        end_date="cast('2026-01-01' as date)"
    ) }}
)
select
    cast(to_char(date_day, 'YYYYMMDD') as integer) as date_key,
    cast(date_day as date)                         as full_date,
    extract(year from date_day)                    as year,
    extract(quarter from date_day)                 as quarter,
    extract(month from date_day)                   as month,
    to_char(date_day, 'MMMM')                      as month_name,
    dayname(date_day)                              as day_name,
    (dayname(date_day) in ('Sat','Sun'))           as is_weekend
from spine

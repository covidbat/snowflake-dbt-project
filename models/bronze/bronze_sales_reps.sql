with source as (
    select * from {{ source('pm_raw', 'raw_sales_reps') }}
)
select
    salesrepid as sales_rep_id,
    repname    as rep_name,
    team,
    region,
    hiredate   as hire_date,
    _source_file, _load_ts
from source

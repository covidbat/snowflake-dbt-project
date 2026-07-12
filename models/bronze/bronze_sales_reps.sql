with source as (
    select * from {{ ref('raw_sales_reps') }}
)
select
    salesrepid as sales_rep_id,
    repname    as rep_name,
    team, region,
    hiredate   as hire_date,
    'seed:raw_sales_reps' as _source_file,
    current_timestamp()   as _load_ts
from source

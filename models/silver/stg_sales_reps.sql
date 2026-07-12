with bronze as (
    select * from {{ ref('bronze_sales_reps') }}
)
select
    sales_rep_id,
    initcap(trim(rep_name)) as rep_name,
    initcap(trim(team))     as team,
    initcap(trim(region))   as region,
    hire_date
from bronze
qualify row_number() over (partition by sales_rep_id order by _load_ts desc) = 1

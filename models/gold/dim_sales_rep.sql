select
    {{ dbt_utils.generate_surrogate_key(['sales_rep_id']) }} as sales_rep_sk,
    sales_rep_id, rep_name, team, region, hire_date
from {{ ref('stg_sales_reps') }}

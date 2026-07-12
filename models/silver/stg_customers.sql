with bronze as (
    select * from {{ ref('bronze_customers') }}
)
select
    customer_id,
    initcap(trim(customer_name)) as customer_name,
    upper(trim(channel_type))    as channel_type,
    market_id,
    onboard_date,
    upper(trim(status))          as status
from bronze
qualify row_number() over (partition by customer_id order by _load_ts desc) = 1

with source as (
    select * from {{ ref('raw_customers') }}
)
select
    customerid   as customer_id,
    customername as customer_name,
    channeltype  as channel_type,
    marketid     as market_id,
    onboarddate  as onboard_date,
    status,
    'seed:raw_customers' as _source_file,
    current_timestamp()  as _load_ts
from source

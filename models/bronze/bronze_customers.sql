with source as (
    select * from {{ source('pm_raw', 'raw_customers') }}
)
select
    customerid    as customer_id,
    customername  as customer_name,
    channeltype   as channel_type,
    marketid      as market_id,
    onboarddate   as onboard_date,
    status,
    _source_file, _load_ts
from source

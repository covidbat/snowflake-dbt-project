with source as (
    select * from {{ source('pm_raw', 'raw_markets') }}
)
select
    marketid   as market_id,
    marketname as market_name,
    region,
    country,
    _source_file, _load_ts
from source

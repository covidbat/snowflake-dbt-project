with source as (
    select * from {{ ref('raw_markets') }}
)
select
    marketid   as market_id,
    marketname as market_name,
    region, country,
    'seed:raw_markets'  as _source_file,
    current_timestamp() as _load_ts
from source

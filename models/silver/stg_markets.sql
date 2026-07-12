with bronze as (
    select * from {{ ref('bronze_markets') }}
)
select
    market_id,
    initcap(trim(market_name)) as market_name,
    initcap(trim(region))      as region,
    upper(trim(country))       as country
from bronze
qualify row_number() over (partition by market_id order by _load_ts desc) = 1

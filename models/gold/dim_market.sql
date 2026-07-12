select
    {{ dbt_utils.generate_surrogate_key(['market_id']) }} as market_sk,
    market_id, market_name, region, country
from {{ ref('stg_markets') }}

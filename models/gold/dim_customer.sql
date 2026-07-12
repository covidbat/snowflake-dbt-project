select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_sk,
    {{ dbt_utils.generate_surrogate_key(['market_id']) }}   as market_sk,
    customer_id, customer_name, channel_type, onboard_date, status
from {{ ref('stg_customers') }}

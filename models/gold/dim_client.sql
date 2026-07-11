with clients as (
    select * from {{ ref('stg_clients') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['client_id']) }} as client_sk,
    client_id,
    client_name,
    industry,
    onboard_date
from clients

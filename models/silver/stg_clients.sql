with bronze as (
    select * from {{ ref('bronze_clients') }}
)
select
    trim(client_id)              as client_id,
    initcap(trim(client_name))   as client_name,
    trim(industry)               as industry,
    cast(onboard_date as date)   as onboard_date
from bronze

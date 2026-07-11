with source as (
    select * from {{ source('arm', 'raw_clients') }}
)
select
    client_id,
    client_name,
    industry,
    onboard_date,
    current_timestamp() as _loaded_at
from source

with source as (
    select * from {{ source('arm', 'raw_collection_activities') }}
)
select
    activity_id,
    account_id,
    agent_id,
    activity_date,
    activity_type,
    outcome,
    current_timestamp() as _loaded_at
from source

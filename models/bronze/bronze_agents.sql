with source as (
    select * from {{ source('arm', 'raw_agents') }}
)
select
    agent_id,
    agent_name,
    team,
    hire_date,
    current_timestamp() as _loaded_at
from source

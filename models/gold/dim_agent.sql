with agents as (
    select * from {{ ref('stg_agents') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['agent_id']) }} as agent_sk,
    agent_id,
    agent_name,
    team,
    hire_date
from agents

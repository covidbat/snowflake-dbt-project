with bronze as (
    select * from {{ ref('bronze_agents') }}
)
select
    trim(agent_id)             as agent_id,
    initcap(trim(agent_name))  as agent_name,
    trim(team)                 as team,
    cast(hire_date as date)    as hire_date
from bronze

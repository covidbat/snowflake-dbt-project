with bronze as (
    select * from {{ ref('bronze_collection_activities') }}
)
select
    trim(activity_id)             as activity_id,
    trim(account_id)              as account_id,
    trim(agent_id)                as agent_id,
    cast(activity_date as date)   as activity_date,
    upper(trim(activity_type))    as activity_type,
    upper(trim(outcome))          as outcome,
    -- did this touch produce money?
    (upper(trim(outcome)) = 'PAYMENT_MADE') as resulted_in_payment
from bronze

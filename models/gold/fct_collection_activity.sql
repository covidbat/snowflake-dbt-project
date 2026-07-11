-- Grain: one row per collection activity (call / letter / email).
with activities as (
    select * from {{ ref('stg_collection_activities') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['activity_id']) }} as activity_sk,
    {{ dbt_utils.generate_surrogate_key(['account_id']) }}  as account_sk,
    {{ dbt_utils.generate_surrogate_key(['agent_id']) }}    as agent_sk,
    cast(to_char(activity_date, 'YYYYMMDD') as integer)     as date_key,
    -- degenerate dimensions
    activity_id,
    activity_type,
    outcome,
    -- measures
    1                            as activity_count,
    iff(resulted_in_payment, 1, 0) as payment_outcome_count
from activities

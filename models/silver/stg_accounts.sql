with bronze as (
    select * from {{ ref('bronze_accounts') }}
)
select
    trim(account_id)                     as account_id,
    trim(client_id)                      as client_id,
    trim(debtor_id)                      as debtor_id,
    cast(original_balance as number(12,2)) as original_balance,
    cast(current_balance  as number(12,2)) as current_balance,
    cast(placement_date  as date)        as placement_date,
    cast(charge_off_date as date)        as charge_off_date,
    upper(trim(status))                  as status,
    -- recovered so far and how much of the debt that represents
    cast(original_balance - current_balance as number(12,2)) as amount_recovered,
    round(
        (original_balance - current_balance)
        / nullif(original_balance, 0), 4
    )                                    as recovery_rate,
    (current_balance <= 0)               as is_fully_recovered
from bronze

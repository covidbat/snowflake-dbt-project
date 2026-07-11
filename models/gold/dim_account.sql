-- Account is the entity being collected on. It carries FKs (surrogate) to
-- client and debtor so facts can roll up either way through this dimension.
with accounts as (
    select * from {{ ref('stg_accounts') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['account_id']) }} as account_sk,
    {{ dbt_utils.generate_surrogate_key(['client_id']) }}  as client_sk,
    {{ dbt_utils.generate_surrogate_key(['debtor_id']) }}  as debtor_sk,
    account_id,
    status,
    original_balance,
    current_balance,
    amount_recovered,
    recovery_rate,
    is_fully_recovered,
    placement_date,
    charge_off_date
from accounts

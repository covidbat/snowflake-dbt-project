with source as (
    select * from {{ source('arm', 'raw_accounts') }}
)
select
    account_id,
    client_id,
    debtor_id,
    original_balance,
    current_balance,
    placement_date,
    charge_off_date,
    status,
    current_timestamp() as _loaded_at
from source

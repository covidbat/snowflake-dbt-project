with source as (
    select * from {{ source('arm', 'raw_payments') }}
)
select
    payment_id,
    account_id,
    payment_date,
    payment_amount,
    payment_method,
    current_timestamp() as _loaded_at
from source

with bronze as (
    select * from {{ ref('bronze_payments') }}
)
select
    trim(payment_id)                      as payment_id,
    trim(account_id)                      as account_id,
    cast(payment_date as date)            as payment_date,
    cast(payment_amount as number(12,2))  as payment_amount,
    upper(trim(payment_method))           as payment_method
from bronze

with debtors as (
    select * from {{ ref('stg_debtors') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['debtor_id']) }} as debtor_sk,
    debtor_id,
    full_name,
    first_name,
    last_name,
    state,
    email,
    phone,
    is_contactable
from debtors

with source as (
    select * from {{ source('arm', 'raw_debtors') }}
)
select
    debtor_id,
    first_name,
    last_name,
    state,
    email,
    phone,
    date_of_birth,
    current_timestamp() as _loaded_at
from source

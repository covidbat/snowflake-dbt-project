with bronze as (
    select * from {{ ref('bronze_debtors') }}
)
select
    trim(debtor_id)                                as debtor_id,
    initcap(trim(first_name))                      as first_name,
    initcap(trim(last_name))                       as last_name,
    initcap(trim(first_name)) || ' ' ||
        initcap(trim(last_name))                   as full_name,
    upper(trim(state))                             as state,
    nullif(trim(email), '')                        as email,
    nullif(trim(phone), '')                        as phone,
    cast(date_of_birth as date)                    as date_of_birth,
    -- can we reach them at all?
    (nullif(trim(email), '') is not null
        or nullif(trim(phone), '') is not null)    as is_contactable
from bronze

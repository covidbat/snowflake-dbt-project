-- Grain: one row per payment (transactional fact).
with payments as (
    select * from {{ ref('stg_payments') }}
),
accounts as (
    select account_id, client_id, debtor_id from {{ ref('stg_accounts') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['p.payment_id']) }}  as payment_sk,
    {{ dbt_utils.generate_surrogate_key(['p.account_id']) }}  as account_sk,
    {{ dbt_utils.generate_surrogate_key(['a.client_id']) }}   as client_sk,
    {{ dbt_utils.generate_surrogate_key(['a.debtor_id']) }}   as debtor_sk,
    cast(to_char(p.payment_date, 'YYYYMMDD') as integer)      as date_key,
    -- degenerate dimensions
    p.payment_id,
    p.payment_method,
    -- measure
    p.payment_amount
from payments p
left join accounts a on p.account_id = a.account_id

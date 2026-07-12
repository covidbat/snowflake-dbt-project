with bronze as (
    select * from {{ ref('bronze_sales_transactions') }}
)
select
    sale_id,
    order_id,
    cast(transaction_date as date)            as transaction_date,
    product_id,
    customer_id,
    sales_rep_id,
    market_id,
    cast(quantity as number(12,2))            as quantity,
    cast(unit_price as number(12,4))          as unit_price,
    cast(discount_amount as number(14,4))     as discount_amount,
    cast(gross_amount as number(14,4))        as gross_amount,
    cast(net_amount as number(14,4))          as net_amount,
    upper(trim(currency))                     as currency,
    -- recompute net as a guard against bad source values
    cast(gross_amount - discount_amount as number(14,4)) as net_amount_calc
from bronze
qualify row_number() over (partition by sale_id order by _load_ts desc) = 1

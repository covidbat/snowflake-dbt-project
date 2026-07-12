with source as (
    select * from {{ source('pm_raw', 'raw_sales_transactions') }}
)
select
    salesid          as sale_id,
    orderid          as order_id,
    transactiondate  as transaction_date,
    productid        as product_id,
    customerid       as customer_id,
    salesrepid       as sales_rep_id,
    marketid         as market_id,
    quantity,
    unitprice        as unit_price,
    discountamount   as discount_amount,
    grossamount      as gross_amount,
    netamount        as net_amount,
    currency,
    _source_file,
    _load_ts
from source

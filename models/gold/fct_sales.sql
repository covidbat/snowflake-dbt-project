{{ config(materialized='incremental', unique_key='sale_sk', incremental_strategy='merge') }}

with sales as (
    select * from {{ ref('stg_sales_transactions') }}
    {% if is_incremental() %}
      -- only pull rows newer than what's already loaded
      where transaction_date >= (select coalesce(max(transaction_date), '1900-01-01') from {{ this }})
    {% endif %}
),
customers as (select customer_id, market_id from {{ ref('stg_customers') }})
select
    {{ dbt_utils.generate_surrogate_key(['s.sale_id']) }}       as sale_sk,
    {{ dbt_utils.generate_surrogate_key(['s.product_id']) }}    as product_sk,
    {{ dbt_utils.generate_surrogate_key(['s.customer_id']) }}   as customer_sk,
    {{ dbt_utils.generate_surrogate_key(['s.sales_rep_id']) }}  as sales_rep_sk,
    {{ dbt_utils.generate_surrogate_key(['s.market_id']) }}     as market_sk,
    cast(to_char(s.transaction_date, 'YYYYMMDD') as integer)    as date_key,
    s.sale_id, s.order_id, s.currency,          -- degenerate dims
    s.quantity, s.gross_amount, s.discount_amount, s.net_amount   -- measures
from sales s
left join customers c on s.customer_id = c.customer_id

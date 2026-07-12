with source as (
    select * from {{ ref('raw_nps_responses') }}
)
select
    responseid as response_id,
    surveydate as survey_date,
    customerid as customer_id,
    productid  as product_id,
    marketid   as market_id,
    channel,
    npsscore   as nps_score,
    comment,
    'seed:raw_nps_responses' as _source_file,
    current_timestamp()      as _load_ts
from source

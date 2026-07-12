with source as (
    select * from {{ source('pm_raw', 'raw_nps_responses') }}
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
    _source_file, _load_ts
from source

{{ config(materialized='incremental', unique_key='nps_sk', incremental_strategy='merge') }}

with nps as (
    select * from {{ ref('stg_nps_responses') }}
    {% if is_incremental() %}
      where survey_date >= (select coalesce(max(survey_date), '1900-01-01') from {{ this }})
    {% endif %}
)
select
    {{ dbt_utils.generate_surrogate_key(['response_id']) }} as nps_sk,
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_sk,
    {{ dbt_utils.generate_surrogate_key(['product_id']) }}  as product_sk,
    {{ dbt_utils.generate_surrogate_key(['market_id']) }}   as market_sk,
    cast(to_char(survey_date, 'YYYYMMDD') as integer)       as date_key,
    response_id, channel, comment,             -- degenerate dims
    nps_score, nps_category,                   -- attributes
    is_promoter, is_detractor,                 -- for NPS = %promoters - %detractors
    1 as response_count                        -- measure
from nps

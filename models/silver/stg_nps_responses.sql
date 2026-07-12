with bronze as (
    select * from {{ ref('bronze_nps_responses') }}
)
select
    response_id,
    cast(survey_date as date)     as survey_date,
    customer_id,
    product_id,
    market_id,
    upper(trim(channel))          as channel,
    cast(nps_score as number(2))  as nps_score,
    nullif(trim(comment), '')     as comment,
    {{ nps_category('nps_score') }} as nps_category,
    iff(nps_score >= 9, 1, 0)                    as is_promoter,
    iff(nps_score between 0 and 6, 1, 0)         as is_detractor
from bronze
qualify row_number() over (partition by response_id order by _load_ts desc) = 1

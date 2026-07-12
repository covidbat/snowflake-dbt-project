with bronze as (
    select * from {{ ref('bronze_products') }}
)
select
    product_id,
    initcap(trim(product_name)) as product_name,
    initcap(trim(brand))        as brand,
    initcap(trim(category))     as category,
    trim(pack_size)             as pack_size,
    launch_date,
    coalesce(is_active, false)  as is_active
from bronze
qualify row_number() over (partition by product_id order by _load_ts desc) = 1

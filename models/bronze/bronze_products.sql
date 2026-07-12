with source as (
    select * from {{ ref('raw_products') }}
)
select
    productid   as product_id,
    productname as product_name,
    brand, category,
    packsize    as pack_size,
    launchdate  as launch_date,
    isactive    as is_active,
    'seed:raw_products' as _source_file,
    current_timestamp() as _load_ts
from source

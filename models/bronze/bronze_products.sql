with source as (
    select * from {{ source('pm_raw', 'raw_products') }}
)
select
    productid    as product_id,
    productname  as product_name,
    brand,
    category,
    packsize     as pack_size,
    launchdate   as launch_date,
    isactive     as is_active,
    _source_file, _load_ts
from source

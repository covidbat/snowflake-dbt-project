select
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_sk,
    product_id, product_name, brand, category, pack_size, launch_date, is_active
from {{ ref('stg_products') }}

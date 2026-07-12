-- ============================================================================
-- STEP 3: Snowpipes (auto-ingest) for GO-FORWARD Parquet files.
-- Watch the .../incoming/ prefix ONLY (backfill lives in .../history/, loaded
-- once by script 04) so nothing is double-loaded. One pipe per feed.
--
-- Parquet loads as a single VARIANT ($1); fields are pulled BY NAME ($1:Field),
-- so file column order doesn't matter. metadata$filename + load time are
-- captured for lineage. NOTE: $1:Field is case-sensitive to the Parquet field
-- name -- confirm exact casing with:  select $1 from @pm_raw_stage/sales/incoming/ limit 1;
--
-- (If your go-forward files stay CSV instead of Parquet, keep a CSV file format
--  and use positional $1..$n -- CSV is fine for small daily files; Parquet's
--  real win is the heavy historical backfill.)
-- ============================================================================
use role sysadmin;
use database pm_db;
use schema raw;

create or replace pipe pm_pipe_sales auto_ingest = true as
  copy into raw_sales_transactions from (
    select
      $1:SalesID::number,        $1:OrderID::number,
      $1:TransactionDate::date,  $1:ProductID::number,
      $1:CustomerID::number,     $1:SalesRepID::number,
      $1:MarketID::number,       $1:Quantity::number,
      $1:UnitPrice::number(12,4),$1:DiscountAmount::number(12,4),
      $1:GrossAmount::number(14,4), $1:NetAmount::number(14,4),
      $1:Currency::varchar,
      metadata$filename, current_timestamp()
    from @pm_raw_stage/sales/incoming/
  )
  file_format = (format_name = pm_parquet_ff);

create or replace pipe pm_pipe_products auto_ingest = true as
  copy into raw_products from (
    select $1:ProductID::number, $1:ProductName::varchar, $1:Brand::varchar,
           $1:Category::varchar,  $1:PackSize::varchar,    $1:LaunchDate::date,
           $1:IsActive::boolean,  metadata$filename, current_timestamp()
    from @pm_raw_stage/products/incoming/
  )
  file_format = (format_name = pm_parquet_ff);

create or replace pipe pm_pipe_customers auto_ingest = true as
  copy into raw_customers from (
    select $1:CustomerID::number, $1:CustomerName::varchar, $1:ChannelType::varchar,
           $1:MarketID::number,   $1:OnboardDate::date,     $1:Status::varchar,
           metadata$filename, current_timestamp()
    from @pm_raw_stage/customers/incoming/
  )
  file_format = (format_name = pm_parquet_ff);

create or replace pipe pm_pipe_sales_reps auto_ingest = true as
  copy into raw_sales_reps from (
    select $1:SalesRepID::number, $1:RepName::varchar, $1:Team::varchar,
           $1:Region::varchar,    $1:HireDate::date,
           metadata$filename, current_timestamp()
    from @pm_raw_stage/sales_reps/incoming/
  )
  file_format = (format_name = pm_parquet_ff);

create or replace pipe pm_pipe_markets auto_ingest = true as
  copy into raw_markets from (
    select $1:MarketID::number, $1:MarketName::varchar, $1:Region::varchar,
           $1:Country::varchar,  metadata$filename, current_timestamp()
    from @pm_raw_stage/markets/incoming/
  )
  file_format = (format_name = pm_parquet_ff);

create or replace pipe pm_pipe_nps auto_ingest = true as
  copy into raw_nps_responses from (
    select $1:ResponseID::number, $1:SurveyDate::date, $1:CustomerID::number,
           $1:ProductID::number,  $1:MarketID::number, $1:Channel::varchar,
           $1:NPSScore::number,   $1:Comment::varchar,
           metadata$filename, current_timestamp()
    from @pm_raw_stage/nps/incoming/
  )
  file_format = (format_name = pm_parquet_ff);

-- ----------------------------------------------------------------------------
-- WIRE UP AUTO-INGEST (do this AFTER the historical backfill in script 04):
--   1. show pipes;  -> copy each pipe's notification_channel (an SQS ARN)
--   2. AWS: S3 bucket -> Properties -> Event notifications ->
--      ObjectCreated (All) -> destination = that SQS ARN,
--      scoped to the INCOMING prefix (e.g. raw/sales/incoming/).
--   3. Drop a Parquet file in s3://pm-datalake/raw/sales/incoming/ -> loads ~1 min.
-- Backfill already-present incoming files once:  alter pipe pm_pipe_sales refresh;
-- ----------------------------------------------------------------------------
show pipes;

-- ============================================================================
-- STEP 4: ONE-TIME historical backfill from Parquet (run ONCE).
-- Loads 2-3 years of SQL Server history into the SAME RAW tables the pipes use.
-- Reads Parquet under .../history/  (go-forward pipes read .../incoming/), so
-- the two never touch the same files.
--
-- Uses MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE: Parquet carries column names, so
-- export column ORDER and CASE don't matter. INCLUDE_METADATA populates the
-- lineage columns. Suggested S3 layout for parallelism + selective re-runs:
--   s3://pm-datalake/raw/sales/history/2022/part-*.parquet
--   s3://pm-datalake/raw/sales/history/2023/...
--   s3://pm-datalake/raw/sales/history/2024/...
-- A single COPY over .../history/ loads every year in parallel across threads.
-- ============================================================================
use role sysadmin;
use database pm_db;
use schema raw;

-- Size UP just for the heavy one-time load, then shrink back at the end.
alter warehouse transform_wh set warehouse_size = 'XLARGE';

copy into raw_sales_transactions
  from @pm_raw_stage/sales/history/
  file_format          = (format_name = pm_parquet_ff)
  match_by_column_name = case_insensitive
  include_metadata     = (_source_file = metadata$filename,
                          _load_ts     = metadata$start_scan_time)
  on_error             = 'ABORT_STATEMENT';

copy into raw_products
  from @pm_raw_stage/products/history/
  file_format = (format_name = pm_parquet_ff)
  match_by_column_name = case_insensitive
  include_metadata = (_source_file = metadata$filename, _load_ts = metadata$start_scan_time)
  on_error = 'ABORT_STATEMENT';

copy into raw_customers
  from @pm_raw_stage/customers/history/
  file_format = (format_name = pm_parquet_ff)
  match_by_column_name = case_insensitive
  include_metadata = (_source_file = metadata$filename, _load_ts = metadata$start_scan_time)
  on_error = 'ABORT_STATEMENT';

copy into raw_sales_reps
  from @pm_raw_stage/sales_reps/history/
  file_format = (format_name = pm_parquet_ff)
  match_by_column_name = case_insensitive
  include_metadata = (_source_file = metadata$filename, _load_ts = metadata$start_scan_time)
  on_error = 'ABORT_STATEMENT';

copy into raw_markets
  from @pm_raw_stage/markets/history/
  file_format = (format_name = pm_parquet_ff)
  match_by_column_name = case_insensitive
  include_metadata = (_source_file = metadata$filename, _load_ts = metadata$start_scan_time)
  on_error = 'ABORT_STATEMENT';

copy into raw_nps_responses
  from @pm_raw_stage/nps/history/
  file_format = (format_name = pm_parquet_ff)
  match_by_column_name = case_insensitive
  include_metadata = (_source_file = metadata$filename, _load_ts = metadata$start_scan_time)
  on_error = 'ABORT_STATEMENT';

-- Shrink compute back down for the cheap incremental pipe loads.
alter warehouse transform_wh set warehouse_size = 'XSMALL';

-- Validate row counts before wiring go-forward ingestion:
select 'sales'     as feed, count(*) as rows from raw_sales_transactions
union all select 'products',  count(*) from raw_products
union all select 'customers', count(*) from raw_customers
union all select 'reps',      count(*) from raw_sales_reps
union all select 'markets',   count(*) from raw_markets
union all select 'nps',       count(*) from raw_nps_responses;

-- To reload just one year (e.g. after a correction), scope the path:
--   copy into raw_sales_transactions from @pm_raw_stage/sales/history/2023/
--     file_format=(format_name=pm_parquet_ff) match_by_column_name=case_insensitive
--     include_metadata=(_source_file=metadata$filename,_load_ts=metadata$start_scan_time)
--     force=true;

-- ============================================================================
-- EXPORT NOTES: SQL Server -> Parquet in S3 (BCP cannot write Parquet)
-- ============================================================================
-- Option A (Microsoft-native): Azure Data Factory / SSIS copy activity,
--   source = SQL Server, sink = Parquet, partitioned by year -> S3.
-- Option B (Spark / Glue): read via JDBC, write .parquet partitioned by year.
-- Option C (Python, small-to-mid tables):
--   import pyodbc, pandas as pd
--   for yr in (2022, 2023, 2024):
--       df = pd.read_sql(f"SELECT * FROM dbo.SalesTransactions "
--                        f"WHERE YEAR(TransactionDate)={yr}", conn)
--       df.to_parquet(f"sales_{yr}.parquet", index=False)   # then aws s3 cp
-- Split large tables into multiple files (~a few hundred MB each) so Snowflake
-- loads them in parallel. Keep column NAMES intact; order/case don't matter.
-- ============================================================================

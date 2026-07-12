# PM Sales & NPS — Snowflake + dbt (migrated from SQL Server)

Medallion warehouse for sales and Net Promoter Score analytics. Data is
migrated out of SQL Server as **Parquet**, landed in S3, and loaded into
Snowflake (no dbt seeds).

```
S3 (raw/*.parquet)  ->  RAW  ->  BRONZE  ->  SILVER  ->  GOLD
 SQL Server export      land    rename      clean       star schema
 (Parquet)                      to snake    + dedup     (facts = incremental)
```

## Setup order
1. `snowflake/01_storage_integration_and_stage.sql`  (ACCOUNTADMIN; wire AWS IAM trust)
2. `snowflake/02_raw_tables.sql`                      (create RAW targets — shared by both loads)
3. `snowflake/04_bulk_backfill.sql`                   (ONE-TIME: load historical SQL Server data from .../history/)
4. `snowflake/03_snowpipes.sql`                       (go-forward: auto-ingest from .../incoming/; wire S3 -> SQS AFTER backfill)
5. `dbt deps && dbt run && dbt test`                  (build bronze -> gold)

## Two-track ingestion (SQL Server -> Snowflake migration)
Both tracks load the **same RAW tables**, from Parquet:
- **Historical backfill (once):** SQL Server exported to Parquet, partitioned by year ->
  `s3://pm-datalake/raw/<feed>/history/YYYY/` -> direct `COPY INTO` with
  `MATCH_BY_COLUMN_NAME` (script 04). Warehouse is sized up to XL for the run, then back to XS.
- **Go-forward (ongoing):** new Parquet files land in
  `s3://pm-datalake/raw/<feed>/incoming/` -> **Snowpipe** auto-ingest (script 03).

Why Parquet: columnar + compressed (~5-10x smaller than CSV) and type-preserving,
so a 2-3 year backfill loads fast without date/decimal parsing errors. Split large
tables into many ~few-hundred-MB files so Snowflake loads them in parallel.

Prefix separation (`history/` vs `incoming/`) keeps the one-time COPY and the
auto-ingest pipe from loading the same files twice. Run the backfill first,
validate row counts, *then* wire the S3 event notifications for `incoming/`.

## Gold star schema
- Dims: `dim_product`, `dim_customer`, `dim_sales_rep`, `dim_market`, `dim_date`
- Facts: `fct_sales` (grain: sales line), `fct_nps_response` (grain: survey) — both incremental (merge)

## NPS metric
`fct_nps_response` carries `is_promoter` / `is_detractor` flags so BI can compute:
```sql
select
  round(100.0 * (sum(is_promoter) - sum(is_detractor)) / count(*), 1) as nps
from gold.fct_nps_response;
```

## What changed vs. a seed-based project
- Seeds removed; ingestion is S3 + Snowpipe (see `snowflake/`).
- Bronze now normalizes SQL Server PascalCase -> snake_case and carries
  `_source_file` / `_load_ts` for lineage.
- Silver dedupes to the latest record per key (`qualify row_number()`), so a
  re-dropped corrected file wins.
- Facts are incremental with `merge`, keyed on surrogate keys.
See `MIGRATION.md` for the T-SQL -> Snowflake rewrites.

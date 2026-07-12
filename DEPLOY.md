# Deployment runbook — PM Sales & NPS

Ordered, one pass from empty account to scheduled production. Run the Snowflake
scripts in numeric order; the ordering matters (backfill before wiring pipes).

## Phase 0 — Prerequisites (outside these scripts)
- Snowflake account **on AWS**, with `ACCOUNTADMIN` access for phases 0–1.
- S3 bucket with per-feed prefixes, e.g.
  `s3://pm-datalake/raw/sales/history/YYYY/` and `.../sales/incoming/`.
- An AWS IAM role Snowflake will assume (trust policy finalized in Phase 2).
- Git repo containing this dbt project (for dbt Cloud) or dbt Core installed.

## Phase 1 — Account foundation
Run `snowflake/00_account_setup.sql` as `ACCOUNTADMIN`.
- Creates `TRANSFORM_WH`, `PM_DB`, `TRANSFORM_ROLE`, grants, and `dbt_user`.
- Replace the `dbt_user` password placeholder first.
- Note the `account_identifier` from the last query — you need it for dbt.

## Phase 2 — S3 storage integration + stage
Run `snowflake/01_storage_integration_and_stage.sql` as `ACCOUNTADMIN`.
- After `desc integration pm_s3_int`, copy `STORAGE_AWS_IAM_USER_ARN` and
  `STORAGE_AWS_EXTERNAL_ID` into the AWS IAM role's **trust policy**
  (principal + `sts:ExternalId` condition), and give the role read on the bucket.
- Re-run `list @pm_raw_stage/...` — it should list your files once trust is set.

## Phase 3 — RAW landing tables
Run `snowflake/02_raw_tables.sql`. Creates the six `RAW` tables both load
tracks write into.

## Phase 4 — Historical backfill (one-time)
1. Export SQL Server history to **Parquet**, partitioned by year (see export
   notes at the bottom of `04_bulk_backfill.sql`).
2. Upload to `s3://pm-datalake/raw/<feed>/history/YYYY/`.
3. Run `snowflake/04_bulk_backfill.sql`. It sizes the warehouse up to XL, loads,
   sizes back to XS, and prints row counts.
4. **Validate** the row counts against SQL Server before proceeding.

## Phase 5 — Go-forward Snowpipes
Run `snowflake/03_snowpipes.sql` (creates the pipes), then:
1. `show pipes;` → copy each pipe's `notification_channel` (SQS ARN).
2. In AWS, add an S3 **event notification** (ObjectCreated) per feed, scoped to
   the `.../incoming/` prefix, targeting that pipe's SQS ARN.
3. Drop one test Parquet file in an `incoming/` folder; confirm it loads:
   `select system$pipe_status('pm_pipe_sales');`

> Backfill BEFORE wiring notifications so no file is loaded twice. History lives
> under `history/`, go-forward under `incoming/`; the pipes watch only `incoming/`.

## Phase 6 — dbt deploy
**dbt Cloud:** connect the repo, set the Snowflake connection (account id from
Phase 1, database `PM_DB`, warehouse `TRANSFORM_WH`, role `TRANSFORM_ROLE`,
user `dbt_user`), dev schema e.g. `DBT_PM`. **dbt Core:** fill `~/.dbt/profiles.yml`.
Then:
```bash
dbt deps
dbt build          # bronze -> silver -> gold + tests, in DAG order
dbt docs generate  # optional: lineage graph
```
Confirm `GOLD` has the five dims + two facts and tests pass.

## Phase 7 — Schedule
- dbt Cloud: create a **Job** running `dbt build`, triggered on a schedule that
  follows your daily loads (or via the dbt Cloud API from your orchestrator).
- Add a `dbt source freshness` step so stale S3 feeds surface (freshness is
  already configured on the sources).

## Phase 8 — Monitor
- Ingestion: `system$pipe_status(...)`, `information_schema.copy_history`,
  `pipe_usage_history`.
- Transform: dbt test results / dbt Cloud run history; source freshness.

## Environments (before real prod)
The `generate_schema_name` macro routes models to fixed `BRONZE/SILVER/GOLD`
schemas regardless of target, so a dev run and a prod run would write to the
**same** schemas. Before running prod alongside dev, either point prod at a
separate database (`PM_DB` vs `PM_DB_DEV`) or make that macro
environment-aware (prefix schemas by target name in non-prod).

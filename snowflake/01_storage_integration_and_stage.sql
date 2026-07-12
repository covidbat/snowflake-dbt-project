-- ============================================================================
-- STEP 1: AWS S3 -> Snowflake external staging (run as ACCOUNTADMIN)
-- Parquet-based. Historical extracts + go-forward files land in S3 as Parquet;
-- Parquet is columnar, compressed (~5-10x smaller than CSV) and carries types,
-- so loads are faster and there's no date/decimal parsing pain.
-- ============================================================================
use role accountadmin;

-- 1a. Storage integration: trust bridge to an AWS IAM role.
create storage integration if not exists pm_s3_int
  type                      = external_stage
  storage_provider          = 'S3'
  enabled                   = true
  storage_aws_role_arn      = 'arn:aws:iam::<AWS_ACCOUNT_ID>:role/snowflake_pm_role'
  storage_allowed_locations = ('s3://pm-datalake/raw/');

-- 1b. Copy STORAGE_AWS_IAM_USER_ARN + STORAGE_AWS_EXTERNAL_ID into the AWS IAM
--     role's trust policy.
desc integration pm_s3_int;

-- 1c. Parquet file format (binary; no header/quoting settings needed).
create file format if not exists pm_parquet_ff
  type                    = parquet
  compression             = auto        -- typically snappy
  binary_as_text          = false
  use_logical_type        = true;       -- map Parquet DATE/TIMESTAMP logical types

-- 1d. External stage over the S3 prefix (subfolders per feed).
create stage if not exists pm_raw_stage
  storage_integration = pm_s3_int
  url                 = 's3://pm-datalake/raw/'
  file_format         = pm_parquet_ff;

grant usage on integration pm_s3_int to role sysadmin;

-- Inspect the Parquet schema before loading (confirms field names/case):
list @pm_raw_stage/sales/history/;
-- select * from table(infer_schema(
--   location => '@pm_raw_stage/sales/history/',
--   file_format => 'pm_parquet_ff')) order by order_id;

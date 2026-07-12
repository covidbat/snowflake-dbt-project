-- ============================================================================
-- STEP 0: Account foundation (run ONCE as ACCOUNTADMIN, before everything).
-- Creates the warehouse, database, role, grants, and a dbt service user that
-- the rest of the scripts and the dbt profile expect.
-- ============================================================================
use role accountadmin;

-- Compute -------------------------------------------------------------------
create warehouse if not exists transform_wh
  warehouse_size      = 'xsmall'
  auto_suspend        = 60
  auto_resume         = true
  initially_suspended = true;

-- Role ----------------------------------------------------------------------
create role if not exists transform_role;
grant role transform_role to role sysadmin;

-- Database ------------------------------------------------------------------
create database if not exists pm_db;

-- Grants --------------------------------------------------------------------
grant usage, operate on warehouse transform_wh to role transform_role;
-- allow the backfill to resize the warehouse up/down (script 04)
grant modify on warehouse transform_wh to role transform_role;

grant usage         on database pm_db to role transform_role;
grant create schema on database pm_db to role transform_role;
grant all on all schemas    in database pm_db to role transform_role;
grant all on future schemas in database pm_db to role transform_role;

-- dbt service user ----------------------------------------------------------
create user if not exists dbt_user
  password             = 'CHANGE_ME_TO_A_STRONG_PASSWORD'
  default_role         = transform_role
  default_warehouse    = transform_wh
  must_change_password = false;
grant role transform_role to user dbt_user;

-- Sanity + account identifier for the dbt connection ------------------------
use role transform_role;
use warehouse transform_wh;
use database pm_db;
select current_organization_name() || '-' || current_account_name() as account_identifier;

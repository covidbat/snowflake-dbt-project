-- ============================================================================
-- STEP 2: RAW landing tables (run as SYSADMIN or TRANSFORM_ROLE)
-- Snowpipe loads INTO these; it does not create them. Columns mirror the
-- migrated SQL Server tables, plus two ingestion-metadata columns for lineage.
-- ============================================================================
use role sysadmin;
use database pm_db;
create schema if not exists raw;
use schema raw;

create table if not exists raw_sales_transactions (
    SalesID          number,
    OrderID          number,
    TransactionDate  date,
    ProductID        number,
    CustomerID       number,
    SalesRepID       number,
    MarketID         number,
    Quantity         number,
    UnitPrice        number(12,4),
    DiscountAmount   number(12,4),
    GrossAmount      number(14,4),
    NetAmount        number(14,4),
    Currency         varchar,
    _source_file     varchar,     -- populated by the pipe (metadata$filename)
    _load_ts         timestamp_ntz
);

create table if not exists raw_products (
    ProductID    number,  ProductName varchar, Brand varchar,
    Category     varchar,  PackSize   varchar, LaunchDate date,
    IsActive     boolean,  _source_file varchar, _load_ts timestamp_ntz
);

create table if not exists raw_customers (
    CustomerID   number, CustomerName varchar, ChannelType varchar,
    MarketID     number, OnboardDate  date,    Status      varchar,
    _source_file varchar, _load_ts    timestamp_ntz
);

create table if not exists raw_sales_reps (
    SalesRepID   number, RepName varchar, Team varchar,
    Region       varchar, HireDate date,
    _source_file varchar, _load_ts timestamp_ntz
);

create table if not exists raw_markets (
    MarketID     number, MarketName varchar, Region varchar, Country varchar,
    _source_file varchar, _load_ts  timestamp_ntz
);

create table if not exists raw_nps_responses (
    ResponseID   number, SurveyDate date, CustomerID number, ProductID number,
    MarketID     number, Channel varchar, NPSScore number, Comment varchar,
    _source_file varchar, _load_ts timestamp_ntz
);

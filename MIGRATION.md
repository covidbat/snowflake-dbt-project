# SQL Server / SSMS -> Snowflake + dbt: conversion notes

Applied while porting the sales & NPS logic. Common rewrites:

| SQL Server (T-SQL)              | Snowflake / dbt                                  |
|---------------------------------|--------------------------------------------------|
| `GETDATE()` / `GETUTCDATE()`    | `current_timestamp()` / `sysdate()`              |
| `ISNULL(x, y)`                  | `coalesce(x, y)` or `ifnull(x, y)`               |
| `IIF(c, a, b)`                  | `iff(c, a, b)`                                    |
| `SELECT TOP 10 ...`             | `... limit 10`                                   |
| `[Bracketed Identifiers]`       | `"Quoted"` (or just lower_snake, unquoted)       |
| `a + b` (string concat)         | `a || b` or `concat(a, b)`                        |
| `LEN(x)`                        | `length(x)`                                       |
| `DATEADD(day, 1, d)`            | `dateadd(day, 1, d)` (same, but no `[]`)          |
| `CONVERT(date, x)`              | `cast(x as date)` / `to_date(x)`                  |
| `IDENTITY` columns              | `autoincrement` / sequences (or dbt surrogate keys)|
| Stored procedures (ETL)         | dbt models (ref/source), not procs                |
| SSIS / BCP export + load        | Export to Parquet (ADF/Spark/Python) -> S3 -> COPY/Snowpipe          |
| `MERGE` upsert proc             | dbt incremental model, `incremental_strategy='merge'` |

Naming: SQL Server `PascalCase` columns are normalized to `snake_case` in the
**bronze** layer (e.g. `SalesID` -> `sale_id`), so downstream models stay clean.

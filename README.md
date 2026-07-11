# ARM Analytics — dbt + Snowflake (Medallion Architecture)

A small, runnable dbt project for the **Accounts Receivable Management (ARM /
debt collections)** domain. It builds a three-layer medallion architecture on
Snowflake and lands a clean star schema in the gold layer.

```
RAW (seeds)  ->  BRONZE (views)  ->  SILVER (views)  ->  GOLD (tables)
 ingestion       as-is landing       cleaned/typed        star schema
```

## Domain model

Clients (creditors: banks, hospitals, telecom...) place delinquent **accounts**
against **debtors**. Collections **agents** work those accounts, logging
**activities** (calls/letters/emails), and debtors make **payments**.

### Gold star schema

| Dimensions      | Facts (grain)                                   |
|-----------------|-------------------------------------------------|
| `dim_client`    | `fct_payments` — one row per payment            |
| `dim_debtor`    | `fct_collection_activity` — one row per touch   |
| `dim_agent`     |                                                 |
| `dim_account`   | (carries client_sk + debtor_sk)                 |
| `dim_date`      |                                                 |

## Layer responsibilities

- **Bronze** (`models/bronze`): 1:1 with raw sources. Standardize casing/naming,
  stamp `_loaded_at`. No business logic. Materialized as **views**.
- **Silver** (`models/silver`): the `stg_` models. Type casting, trimming,
  null handling, derived fields (`full_name`, `recovery_rate`,
  `resulted_in_payment`). Materialized as **views**.
- **Gold** (`models/gold`): dimensional marts with `dbt_utils`-generated
  surrogate keys and a `date_spine` calendar. Materialized as **tables** — this
  is what BI tools query.

## Prerequisites

- A Snowflake account with a warehouse, a database (e.g. `ARM_DB`), and a role
  that can create schemas.
- dbt with the Snowflake adapter (`dbt-snowflake`), or a dbt Cloud project.

## Setup & run

**dbt Cloud:** configure the Snowflake connection in the UI, point it at this
repo, then run the commands below in the IDE command bar.

**dbt Core:** copy `profiles.yml.example` to `~/.dbt/profiles.yml`, fill in your
Snowflake details, then:

```bash
dbt deps      # install dbt_utils
dbt seed      # load RAW tables (simulates ingestion) -- RUN THIS FIRST
dbt run       # build bronze -> silver -> gold
dbt test      # run 40 data tests
```

Or all at once (seeds included in the DAG):

```bash
dbt deps && dbt build
```

## Schema naming

`macros/generate_schema_name.sql` overrides dbt's default so custom schemas
resolve to `RAW`, `BRONZE`, `SILVER`, `GOLD` cleanly instead of
`ARM_bronze` etc. All four live under the database set in your profile.

## Example gold queries

```sql
-- Recovery rate by client
select c.client_name, c.industry,
       sum(a.original_balance)  as placed,
       sum(a.amount_recovered)  as recovered,
       round(sum(a.amount_recovered) / nullif(sum(a.original_balance),0), 3) as recovery_rate
from gold.dim_account a
join gold.dim_client  c on a.client_sk = c.client_sk
group by 1, 2
order by recovery_rate desc;

-- Agent effectiveness: activities vs. those that led to payment
select ag.agent_name, ag.team,
       count(*)                     as touches,
       sum(f.payment_outcome_count) as payments_driven
from gold.fct_collection_activity f
join gold.dim_agent ag on f.agent_sk = ag.agent_sk
group by 1, 2
order by payments_driven desc;

-- Monthly payments collected
select d.year, d.month_name, sum(f.payment_amount) as collected
from gold.fct_payments f
join gold.dim_date d on f.date_key = d.date_key
group by 1, 2, d.month
order by d.month;
```

## Note on dbt versions

The generic tests use the classic `tests:` syntax (as in most dbt courses).
Newer dbt versions emit a deprecation warning suggesting arguments be nested
under an `arguments:` key. It still runs fine; migrate later if you like.

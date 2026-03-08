# AGENTS.md — cc_dbt_utils

> Clearcover's fork of dbt-utils: a dbt package of reusable Jinja2 macros, schema tests, SQL generators, and cross-DB adapter utilities consumed by Clearcover's analytics dbt projects.

## Quick start

```bash
# Install dbt adapter and run integration tests against Postgres (local)
./run_test.sh postgres

# Run via Docker — from repo root
cd integration_tests && make test target=postgres

# Run against other adapters (requires credentials in ~/.dbt/profiles.yml — copy from integration_tests/ci/sample.profiles.yml)
./run_test.sh redshift
./run_test.sh snowflake
./run_test.sh bigquery
```

## Domain position

**Layer:** Shared Services
**Domain:** Analytics Domain

**This service owns:**
- Reusable dbt macro library (SQL generators, schema tests, cross-DB adapter abstractions)
- No database ownership — this is a stateless dbt package (library)

**Observed dependencies:** Postgres (integration tests), Redshift, Snowflake, BigQuery (CI targets)

> Absence means not observed in this scan, not that the integration doesn't exist.

## Tech stack

- **Language/runtime:** Jinja2/SQL (dbt macros), Python 3 (test runner — version not pinned)
- **Framework:** dbt >=1.0.0, <2.0.0
- **Test:** dbt test (integration only — no unit test framework)
- **DB:** None owned; tests run against Postgres, Redshift, Snowflake, BigQuery

## Project structure

```
macros/
  cross_db_utils/   # Adapter-agnostic SQL functions (dateadd, datediff, hash, etc.)
  sql/              # SQL generators (date_spine, surrogate_key, star, pivot, union, etc.)
  schema_tests/     # Custom dbt schema tests (recency, mutually_exclusive_ranges, etc.)
  materializations/ # Custom materializations (insert_by_period)
  web/              # URL parsing macros
  hooks/            # Hook utilities
  jinja_helpers/    # Jinja2 utility macros
  operations/       # dbt operation macros
integration_tests/  # dbt project wiring tests against real adapters
.circleci/          # CI config (runs all 4 adapter targets)
```

## Boundaries

**Always:** run `./run_test.sh postgres` before pushing · respect domain boundaries above · no secrets in commits
**Ask first:** new adapter-specific implementations · changes to cross_db_utils (affects all adapters) · schema test signature changes (breaking for consumers)
**Never:** push to main/master · skip failing tests · add business logic (this is a utility library only)

> Last updated: [date]. Review and update when this repo next changes meaningfully.

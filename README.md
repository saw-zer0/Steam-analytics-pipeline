# Steam Analytics Pipeline

A local analytics warehouse for Steam game catalog data. The project loads a scraper-produced CSV into PostgreSQL, transforms it into analytics models with dbt, orchestrates the workflow with Apache Airflow, and serves interactive reports with Streamlit.

## Table of Contents

- [Overview](#overview)
- [Architecture and Data Flow](#architecture-and-data-flow)
- [Technology](#technology)
- [Repository Layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Build and Run](#build-and-run)
  - [1. Install Python Dependencies](#1-install-python-dependencies)
  - [2. Prepare PostgreSQL](#2-prepare-postgresql)
  - [3. Load the CSV and Build dbt Models](#3-load-the-csv-and-build-dbt-models)
  - [4. Run the Dashboard](#4-run-the-dashboard)
  - [5. Run the Orchestrated Pipeline](#5-run-the-orchestrated-pipeline)
- [Data Warehouse Design](#data-warehouse-design)
- [Dashboard](#dashboard)
- [Operations and Troubleshooting](#operations-and-troubleshooting)
- [Development Notes](#development-notes)

## Overview

The project works with a CSV export produced by a Steam games scraper; it does not scrape Steam itself. The input file is `data/raw/games.csv`. The extractor reads it in batches, validates its expected columns, and upserts game records into PostgreSQL. dbt then builds staging models and a dimensional analytics layer, and the Streamlit application queries that layer for interactive summaries.

The main workflow can be run as separate local steps or scheduled through Airflow. Airflow and its metadata database run in Docker Compose. The Steam warehouse is a separate PostgreSQL database that must be reachable by the extractor, dbt, and dashboard.

## Architecture and Data Flow

```text
Scraper CSV (data/raw/games.csv)
	|
	v
Python extractor (elt/extract.py)
	|
	v
PostgreSQL source table (public.steam_games)
	|
	v
dbt staging models and dimensions / bridges / fact table
	|
	v
Streamlit analytics dashboard

Airflow schedules and runs the extractor followed by the dbt model group.
```

The Airflow DAG runs daily, does not backfill missed scheduled dates, and runs extraction before the dbt models. Re-running the extractor updates existing records by Steam app ID. The current fact model records a `current_date` snapshot when dbt builds; it is not a long-term history of changing Steam metrics.

## Technology

- Python 3.14 or newer, managed with [uv](https://docs.astral.sh/uv/)
- PostgreSQL for the Steam warehouse and Airflow metadata
- Apache Airflow 3.3.0, using Docker Compose and `LocalExecutor`
- dbt Core with the PostgreSQL adapter; Airflow integrates dbt through Cosmos
- pandas and psycopg2 for CSV loading and PostgreSQL access
- Streamlit for the dashboard

## Repository Layout

| Path | Purpose |
| --- | --- |
| `data/raw/games.csv` | Scraper-produced source dataset consumed by the extractor |
| `elt/extract.py` | Reads, validates, and batch-upserts CSV rows into `public.steam_games` |
| `sql/init.sql` | PostgreSQL database and raw table DDL |
| `airflow/dags/steam_pipeline_dag.py` | Daily extraction and dbt orchestration DAG |
| `airflow/profiles.yml` | Environment-driven dbt connection profile used in Airflow |
| `docker-compose.yml` | Local Airflow services and their metadata PostgreSQL database |
| `steam_dw_pipeline/models/staging/steam_games/` | Source declarations and cleaned/normalized staging models |
| `steam_dw_pipeline/models/marts/steam_games/` | Date/game dimensions, lookup dimensions, bridge tables, and metrics fact |
| `steam_dw_pipeline/macros/` | Post-hooks for staging identity columns and mart constraints |
| `steam_dw_pipeline/profiles.yml` | Local dbt profile defaults for command-line development |
| `streamlit/app.py` | Dashboard entry point |
| `streamlit/tabs/` | Price, genre, category, publisher, and release-date views |
| `streamlit/shared/` | Shared database and popularity-query helpers |
| `pyproject.toml`, `uv.lock` | Python package metadata, dependencies, and locked environment |

## Prerequisites

- Git and this repository checked out locally
- Python 3.14+ and uv for local extraction, dbt, or dashboard execution
- PostgreSQL 16 or a compatible PostgreSQL server for the Steam warehouse
- Docker Desktop with Docker Compose for Airflow
- At least 4 GB of memory, 2 CPUs, and 10 GB of free disk space available to Docker for a comfortable Airflow setup

The Compose file starts a PostgreSQL 16 container for Airflow's metadata only. It does not start the Steam warehouse or load the game data. For a simple local setup, run the warehouse on the host and use `localhost` for local processes and `host.docker.internal` for Airflow containers.

## Configuration

Create a root `.env` file. It is ignored by Git; do not commit passwords, connection URIs, or encryption keys. Docker Compose uses this file for Airflow services, while local Python tools load it from the project root.

Configure the following values as appropriate for your PostgreSQL server:

| Variable(s) | Used by | Meaning |
| --- | --- | --- |
| `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD` | Extractor | Connection to the Steam warehouse and raw table |
| `STEAM_DBT_HOST`, `STEAM_DBT_PORT`, `STEAM_DBT_DATABASE`, `STEAM_DBT_USER`, `STEAM_DBT_PASSWORD`, `STEAM_DBT_SCHEMA`, `STEAM_DBT_THREADS` | Airflow dbt profile | dbt target settings; defaults in the Airflow profile target database `steam_dw` and schema `dbt` |
| `AIRFLOW_CONN_STEAM_DW` | Airflow/Cosmos | Airflow connection URI for connection ID `steam_dw`; point it at the same Steam warehouse |
| `FERNET_KEY` | Airflow | Fernet key used by Airflow to encrypt stored connection values |
| `AIRFLOW_UID` | Airflow/Docker | Optional container UID setting; the Compose file defaults to `50000` |
| `_AIRFLOW_WWW_USER_USERNAME`, `_AIRFLOW_WWW_USER_PASSWORD` | Airflow | Optional initial Airflow administrator credentials; defaults are `airflow` / `airflow` |
| `STREAMLIT_PGHOST`, `STREAMLIT_PGPORT`, `STREAMLIT_PGDATABASE`, `STREAMLIT_PGUSER`, `STREAMLIT_PGPASSWORD` | Dashboard | Connection to the Steam warehouse; the application defaults to database `steam_dw` and schema `dbt_marts` |
| `STEAM_DBT_MART_SCHEMA` | Dashboard | dbt mart schema to query; defaults to `dbt_marts` |

Use `localhost` in the PostgreSQL variables for tools running directly on your computer. For the `PGHOST` and `STEAM_DBT_HOST` values consumed inside Airflow containers, use `host.docker.internal` when PostgreSQL runs on the host. `AIRFLOW_CONN_STEAM_DW` must also resolve to that warehouse, not the Compose metadata database.

Generate a Fernet key locally with:

```powershell
uv run python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Put the output in `.env` as `FERNET_KEY=...`. The project currently has no checked-in `.env.example`; create `.env` yourself and supply the settings needed for the workflow you intend to run. Keep the actual values private.

## Build and Run

Run commands from the repository root unless otherwise stated. PowerShell commands are shown; the equivalent `uv`, `psql`, `docker compose`, and `streamlit` commands work in other shells with their normal path/variable syntax.

### 1. Install Python Dependencies

Install the locked project dependencies with uv:

```powershell
uv sync
```

This creates or updates the local virtual environment from `pyproject.toml` and `uv.lock`. The Docker Airflow services use the Airflow image and install `astronomer-cosmos`, `dbt-postgres`, pandas, and python-dotenv through the Compose configuration.

### 2. Prepare PostgreSQL

Create a PostgreSQL database named `steam_dw` and initialize its `public.steam_games` table using the DDL in `sql/init.sql`. The extractor expects that table to exist before it runs. Make sure the table is created while connected to `steam_dw`: `CREATE DATABASE` does not switch the active connection to the newly created database. If applying the SQL file with a client, create the database first, connect to `steam_dw`, then execute the table definition from the file.

Configure the extractor's `PG*` variables and ensure the selected database/user can insert and update rows in `public.steam_games`. Keep this warehouse separate from the PostgreSQL service that Compose creates for Airflow metadata.

The expected source CSV is `data/raw/games.csv`. The extractor checks that its column names and order match the Steam scraper export schema before loading each 1,000-row batch. A missing file, incompatible CSV export, absent table, or invalid database credentials will stop extraction with an error.

### 3. Load the CSV and Build dbt Models

Load the raw data directly, outside Airflow:

```powershell
uv run python elt/extract.py
```

Build the dbt warehouse models using the local profile in `steam_dw_pipeline/profiles.yml`:

```powershell
uv run dbt debug --project-dir steam_dw_pipeline --profiles-dir steam_dw_pipeline
uv run dbt build --project-dir steam_dw_pipeline --profiles-dir steam_dw_pipeline
```

The checked-in local profile uses local development defaults. Update it for your local PostgreSQL credentials as needed, or use the environment-driven profile mounted for Airflow. `dbt build` runs models and their declared data tests. The target database and schemas must be accessible to the configured dbt user.

### 4. Run the Dashboard

After the dbt marts have been built, start Streamlit:

```powershell
uv run streamlit run streamlit/app.py
```

Open the local URL printed by Streamlit (normally `http://localhost:8501`). The dashboard uses the `STREAMLIT_PG*` connection variables and queries the mart schema configured by `STEAM_DBT_MART_SCHEMA`.

### 5. Run the Orchestrated Pipeline

1. Ensure `.env` contains the Airflow settings, extractor `PG*` settings, dbt profile settings, and `AIRFLOW_CONN_STEAM_DW` described above. Airflow's connection ID must be `steam_dw` and point to the Steam warehouse.
2. Ensure the Steam warehouse database and `public.steam_games` table exist and `data/raw/games.csv` is present.
3. Initialize Airflow's metadata database and create the initial admin user:

   ```powershell
   docker compose up airflow-init
   ```

4. Start the Airflow services:

   ```powershell
   docker compose up -d
   ```

5. Open [http://localhost:8080](http://localhost:8080) and sign in with the configured administrator credentials. Find `steam_pipeline_dag`, unpause it, and trigger a run. The DAG is configured for daily scheduling, but is created paused in Airflow.

Check service health and logs with:

```powershell
docker compose ps
docker compose logs -f airflow-scheduler
```

Stop the services and retain Airflow metadata with:

```powershell
docker compose down
```

Remove the containers and Airflow metadata volume for a full reset (this deletes Airflow's stored state, not the separately hosted Steam warehouse):

```powershell
docker compose down -v
```

The Compose setup is for local development, not production deployment.

## Data Warehouse Design

dbt reads the raw source from `public.steam_games` and builds two model layers. The project config sets staging models to the `staging` custom schema and marts to the `marts` custom schema. With dbt's default schema naming, and the configured base schema `dbt`, these become `dbt_staging` and `dbt_marts`.

- **Staging**: casts and cleans game attributes, normalizes estimated-owner ranges, and separates multi-valued categories, genres, tags, developers, publishers, and languages into reusable models.
- **Dimensions**: descriptive game and date dimensions, plus dimensions for owners, developers, publishers, categories, genres, tags, and languages.
- **Bridge tables**: represent many-to-many game relationships to categories, genres, tags, developers, publishers, and languages.
- **Fact table**: `fct_game_metrics` contains price, discount, concurrent users, scores, reviews, achievements, recommendations, and owner-range keys for games at the build date.
- **Tests and hooks**: dbt schema tests check uniqueness, required values, and relationships; project macros apply identity columns and mart constraints after materialization.

## Dashboard

The Streamlit app has five views:

- **Price**: counts games across price bands, including free games.
- **Genre**: ranks genres by an aggregate popularity score, excluding groups with fewer than five games.
- **Category**: ranks categories using the shared popularity calculation.
- **Publisher**: compares publisher-level popularity and self-published games.
- **Release date**: summarizes games by a selectable date grain.

All dashboard tabs query the built dbt marts; the dashboard does not trigger extraction or dbt builds itself. Run the data pipeline first if the marts are empty or stale.

## Operations and Troubleshooting

- **Extractor cannot connect**: check `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, and `PGPASSWORD`; verify PostgreSQL accepts the connection and that `public.steam_games` exists.
- **Airflow task cannot reach the warehouse**: do not use `localhost` from inside a container to reach host PostgreSQL. Use `host.docker.internal`, check the host server's network access rules, and ensure the container environment includes the right credentials.
- **dbt connection or missing relation errors**: verify `AIRFLOW_CONN_STEAM_DW` is configured as the Airflow connection with ID `steam_dw`, and that dbt's `STEAM_DBT_*` target values refer to the same warehouse as extraction.
- **Dashboard reports a database error**: confirm the `STREAMLIT_PG*` settings and check that dbt has created the mart schema and its models. The app reads `dbt_marts` by default.
- **Airflow is unavailable after startup**: inspect `docker compose ps` and the scheduler/API-server logs. Initialization must complete before the API server and scheduler start.
- **CSV schema error**: use the expected scraper export with the original headers and column order. The loader intentionally fails rather than silently loading a different schema.

## Development Notes

- Rebuild and test dbt models with `uv run dbt build --project-dir steam_dw_pipeline --profiles-dir steam_dw_pipeline` after changing models.
- Airflow DAG files are mounted from `airflow/dags`; task logs are persisted under `airflow/logs`.
- The Docker Compose PostgreSQL volume contains Airflow metadata. Removing it does not erase data in the separate Steam warehouse.
- The pipeline is currently designed for one CSV input and a local development workflow. Review credentials, network exposure, scheduling, retries, and database backups before adapting it for shared or production use.

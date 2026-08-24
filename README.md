# Data Lake in a Codespace

A self-contained teaching environment that walks through the idea of a 
data lake — from a raw CSV export to a lakehouse with ACID transactions 
— entirely inside a GitHub Codespace. No local installation, no cloud account, 
no Spark cluster.

## The story, in five steps

| # | Topic | Where |
|---|-------|-------|
| — | Setup: reproducible environment | [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json) |
| 1 | Raw data — the landing zone | [notebooks/01_raw_data.ipynb](notebooks/01_raw_data.ipynb) |
| 2 | Curation: Parquet & partitioning | [notebooks/02_parquet_and_partitioning.ipynb](notebooks/02_parquet_and_partitioning.ipynb) |
| 3 | Querying: DuckDB, schema-on-read | [notebooks/03_duckdb_queries.ipynb](notebooks/03_duckdb_queries.ipynb) |
| 4 | Object storage: MinIO (S3-compatible) | [notebooks/04_object_storage_minio.ipynb](notebooks/04_object_storage_minio.ipynb) |
| 5 | Lakehouse: Delta Lake & ACID | [notebooks/05_lakehouse_delta.ipynb](notebooks/05_lakehouse_delta.ipynb) |

Plain files on a lake (CSV, Parquet, or partitioned Parquet in a bucket)
have no notion of a transaction: a write that fails halfway leaves a
half-written file, and a reader can see that half-written state. A database
avoids this by guaranteeing four properties for every transaction — the
acronym **ACID**:

- **Atomicity** — a transaction happens completely or not at all. There is
  no state where only 3 of 5 new rows made it in.
- **Consistency** — every transaction takes the table from one valid state
  to another valid state; the schema and any constraints always hold.
- **Isolation** — concurrent transactions can't see each other's
  half-finished work; every reader sees one complete, consistent snapshot.
- **Durability** — once a transaction is confirmed, it survives, even if
  the system crashes a moment later.

Plain Parquet files give you none of this. `05_lakehouse_delta.ipynb` shows
how Delta Lake adds it back with nothing more exotic than a folder of JSON
files (`_delta_log/`): every write becomes one atomic, durable log entry, a
reader only ever sees the files listed by a fully-written log entry
(isolation + consistency), and because old data files are never deleted,
loading an older log state is all "time travel" really is.

## Getting started

1. On GitHub, click **Code → Create codespace on main**.
2. Wait ~2 minutes while the container builds and `pip install -r requirements.txt` runs automatically.
3. Open `notebooks/01_raw_data.ipynb` and run the cells top to bottom.
4. Continue through `02`, `03` in order.
5. Before `04_object_storage_minio.ipynb`, start MinIO from a terminal:
   ```bash
   bash scripts/start_minio.sh
   ```
   Codespaces forwards port 9001 automatically — open the **Ports** tab to
   reach the MinIO web console.
6. Finish with `05_lakehouse_delta.ipynb`.

## Repository layout

```
|-- .devcontainer/
|   `-- devcontainer.json          # Codespace definition (Python, Docker-in-Docker, ports)
|-- requirements.txt               # duckdb, pandas, pyarrow, deltalake, minio, jupyter, ...
|-- scripts/
|   |-- generate_data.py           # generates the synthetic raw CSV
|   |-- start_minio.sh             # docker compose up for MinIO
|   `-- stop_minio.sh              # docker compose down
|-- docker/
|   `-- docker-compose.yml         # MinIO service definition
|-- notebooks/                     # the five teaching steps
|   |-- 01_raw_data.ipynb
|   |-- 02_parquet_and_partitioning.ipynb
|   |-- 03_duckdb_queries.ipynb
|   |-- 04_object_storage_minio.ipynb
|   `-- 05_lakehouse_delta.ipynb
|-- lake/                           # generated at runtime, gitignored
`-- README.md
```

`lake/` is where all generated output lands: `lake/raw/sales.csv`
(~10-15 MB, 300,000 rows), `lake/verkauf/jahr=.../monat=.../*.parquet`, and
`lake/delta/sales_delta/`. The dataset is deliberately kept small: generating
and querying it takes seconds, not minutes, and it's small enough that a
student can open the raw CSV directly and page through it by hand — the
point is to see the mechanism clearly, not to benchmark at scale.

`lake/` is listed in [.gitignore](.gitignore) — generated data has no
business in git history, however small. Every notebook regenerates what it
needs, so a fresh Codespace always works from nothing.

## Compute budget

GitHub's free tier includes 120 core-hours/month for personal accounts.

- Setup through step 3 (no MinIO) runs comfortably on the default
  **2-core** machine.
- Steps 4–5 (MinIO + Delta Lake) are more pleasant on a **4-core** machine —
  this repo's `devcontainer.json` requests 4 cores by default.
- **GitHub Education** (teachers and students) unlocks substantially higher
  Codespaces quotas at no cost — apply before the course starts.
- **GitHub Classroom** can distribute this repository as a template to an
  entire class, with each student getting their own copy and their own
  Codespace.

## Notes for instructors

- `scripts/generate_data.py` is deterministic (fixed `--seed`), so every
  student's raw data — and therefore every query result — is identical,
  which makes live comparisons of results and query plans meaningful.
- The revenue timing comparison in `03_duckdb_queries.ipynb` and the size
  comparison in `02_parquet_and_partitioning.ipynb` are designed to be run
  live and discussed on the spot — the numbers are the lesson.
- If a Codespace runs out of the free-tier budget mid-course, students can
  stop and restart it; the `lake/` folder is regenerated by re-running the
  earlier notebooks (nothing valuable is lost by deleting it).

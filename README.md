# Data Lake in a Codespace

A self-contained teaching environment that walks through the idea of a
data lake in five steps: raw CSV data, curation into partitioned Parquet,
querying with DuckDB, object storage with MinIO, and a transactional
lakehouse with Delta Lake.

## The story, in five steps

| # | Topic | Where |
|---|-------|-------|
| — | Setup: reproducible environment | [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json) |
| 1 | Raw data | [notebooks/01_raw_data.ipynb](notebooks/01_raw_data.ipynb) |
| 2 | Curation: Parquet & partitioning | [notebooks/02_parquet_and_partitioning.ipynb](notebooks/02_parquet_and_partitioning.ipynb) |
| 3 | Querying: DuckDB | [notebooks/03_duckdb_queries.ipynb](notebooks/03_duckdb_queries.ipynb) |
| 4 | Object storage: MinIO (S3-compatible) | [notebooks/04_object_storage_minio.ipynb](notebooks/04_object_storage_minio.ipynb) |
| 5 | Lakehouse: Delta Lake & ACID | [notebooks/05_lakehouse_delta.ipynb](notebooks/05_lakehouse_delta.ipynb) |

The five notebooks build a data lake outward from a single CSV file, each
step motivated by a limitation left by the previous one.

`01_raw_data.ipynb` generates that CSV: a flat export with no schema
enforcement, no partitioning, and no query engine — the starting point any
data lake effort shares.

`02_parquet_and_partitioning.ipynb` addresses the two costs of leaving the
data in that form: a CSV must be parsed as text on every read, and any query
can only be answered by scanning the file in full. Converting to Parquet (a
columnar, compressed format with an embedded schema) removes the parsing
cost; partitioning by year and month — encoding `jahr=.../monat=...` into
the folder structure — lets a query engine skip files outside a filter
without opening them.

`03_duckdb_queries.ipynb` introduces that query engine, DuckDB, and shows
what the partitioning from step 2 buys: on the raw CSV, every query scans
the whole file; on the partitioned Parquet dataset, DuckDB skips whole files
that a filter rules out (predicate pushdown) and reads only the columns a
query references (column pruning) — neither optimization is available on
CSV.

`04_object_storage_minio.ipynb` moves the same files onto object storage
(MinIO, standing in for S3), because a production data lake, unlike a
folder on local disk, needs storage and compute to scale and be operated
independently. The notebook shows that the query itself is unchanged apart
from its path prefix (`lake/...` becomes `s3://...`): DuckDB, the compute
layer, communicates with MinIO, the storage layer, purely over the S3
protocol.

By this point the lake is partitioned, columnar, and served over the
network — fast to query, but still just files.

Plain files (CSV, Parquet, or partitioned Parquet in a bucket) provide no
notion of a "transaction" (a set of database operations that must succeed
or fail together, as a single unit). A write that fails partway through
leaves a partially written file, and a concurrent reader may observe that
inconsistent state. A database avoids this by wrapping every write in a
transaction and guaranteeing four properties for it, such that a reader
never observes an intermediate, inconsistent state — the acronym **ACID**:

- **Atomicity** — a transaction is applied in full or not at all; there is
  no state in which only part of a write, e.g. 3 of 5 new rows, has taken
  effect.
- **Consistency** — every transaction moves the table from one valid state
  to another valid state; the schema and all constraints continue to hold.
- **Isolation** — concurrent transactions cannot observe one another's
  unfinished work; every reader sees a single, complete, consistent
  snapshot.
- **Durability** — once a transaction is confirmed, its effects persist
  even if the system subsequently crashes.

`05_lakehouse_delta.ipynb` demonstrates how Delta Lake restores these
guarantees using nothing more than a folder of JSON files (`_delta_log/`):
each write is recorded as a single atomic,
durable log entry; a reader only ever sees the files listed by a fully
written log entry (isolation and consistency); and because prior data files
are never deleted, loading an earlier log state is the entire mechanism
behind "time travel".

## Getting started

1. On GitHub, click **Code → Create codespace on main**.
2. Wait while the container builds and `pip install -r requirements.txt` runs automatically.
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
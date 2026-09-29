#!/usr/bin/env bash
# Stop the local MinIO object store started via start_minio.sh.
set -euo pipefail

cd "$(dirname "$0")/../docker"
docker compose down

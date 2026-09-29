#!/usr/bin/env bash
# Start the local MinIO object store used in step 4 of the course.
set -euo pipefail

cd "$(dirname "$0")/../docker"
docker compose up -d
echo ""
echo "MinIO is starting."
echo "  API:     http://localhost:9000"
echo "  Console: http://localhost:9001  (user: minioadmin / password: minioadmin)"
echo ""
echo "In Codespaces, open the 'Ports' tab and click the forwarded 9001 link."

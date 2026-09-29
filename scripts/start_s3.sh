#!/usr/bin/env bash
# Start the local S3-compatible object store (moto) used in step 4 of the course.
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p .s3-server

if curl -s -o /dev/null http://localhost:9000/moto-api/; then
    echo "S3 server is already running on http://localhost:9000"
    exit 0
fi

nohup python -m moto.server -H 0.0.0.0 -p 9000 > .s3-server/server.log 2>&1 &
echo $! > .s3-server/server.pid

for _ in $(seq 1 20); do
    if curl -s -o /dev/null http://localhost:9000/moto-api/; then
        echo ""
        echo "S3 server (moto) is running."
        echo "  S3 API:    http://localhost:9000"
        echo "  Dashboard: http://localhost:9000/moto-api/"
        echo ""
        echo "In Codespaces, open the 'Ports' tab and click the forwarded 9000 link,"
        echo "then append /moto-api/ to the URL."
        echo "Data is kept in memory only and is lost when the server stops."
        exit 0
    fi
    sleep 0.5
done

echo "S3 server did not start. See .s3-server/server.log" >&2
exit 1

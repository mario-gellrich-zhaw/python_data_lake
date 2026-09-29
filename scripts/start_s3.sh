#!/usr/bin/env bash
# Start the local S3-compatible object store (moto) used in step 4 of the course.
set -euo pipefail

# Port 5000 is moto's default. Do not use 9000+: VS Code's Jupyter extension
# starts notebook kernels on ports 9000 and up.
PORT=5000

cd "$(dirname "$0")/.."
mkdir -p .s3-server

if curl -sf -o /dev/null "http://localhost:$PORT/moto-api/"; then
    echo "S3 server is already running on http://localhost:$PORT"
    exit 0
fi

if ss -ltn | grep -q ":$PORT\b"; then
    echo "Port $PORT is used by another program:" >&2
    ss -ltnp | grep ":$PORT\b" >&2
    exit 1
fi

setsid nohup python -m moto.server -H 0.0.0.0 -p "$PORT" > .s3-server/server.log 2>&1 &
echo $! > .s3-server/server.pid

for _ in $(seq 1 20); do
    if curl -sf -o /dev/null "http://localhost:$PORT/moto-api/"; then
        echo ""
        echo "S3 server (moto) is running."
        echo "  S3 API:    http://localhost:$PORT"
        echo "  Dashboard: http://localhost:$PORT/moto-api/"
        echo ""
        echo "In Codespaces, open the 'Ports' tab and click the forwarded $PORT link,"
        echo "then append /moto-api/ to the URL."
        echo "Data is kept in memory only and is lost when the server stops."
        exit 0
    fi
    sleep 0.5
done

echo "S3 server did not start. See .s3-server/server.log" >&2
exit 1

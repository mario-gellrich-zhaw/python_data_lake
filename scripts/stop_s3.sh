#!/usr/bin/env bash
# Stop the local S3 server started via start_s3.sh.
set -euo pipefail

cd "$(dirname "$0")/.."
PID_FILE=.s3-server/server.pid

if [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "S3 server stopped."
else
    echo "S3 server was not running."
fi
rm -f "$PID_FILE"

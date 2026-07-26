#!/usr/bin/env bash
set -euo pipefail

cd "${MISE_PROJECT_ROOT}"
mkdir -p .pitchfork/clickhouse-data .pitchfork/clickhouse-tmp .pitchfork/clickhouse-user-files .pitchfork/clickhouse-format-schemas

if curl --fail --silent http://127.0.0.1:8123/ping >/dev/null 2>&1; then
  echo "ClickHouse already running on port 8123"
  exit 0
fi

if [[ -f .pitchfork/clickhouse.pid ]] && ! kill -0 "$(cat .pitchfork/clickhouse.pid)" 2>/dev/null; then
  mv .pitchfork/clickhouse.pid .pitchfork/clickhouse.pid.stale
fi

pitchfork start clickhouse

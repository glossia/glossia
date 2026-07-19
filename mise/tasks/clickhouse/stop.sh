#!/usr/bin/env bash
set -euo pipefail

cd "${MISE_PROJECT_ROOT}"
pitchfork supervisor start >/dev/null 2>&1 || true
pitchfork stop clickhouse || true

if [[ -f .pitchfork/clickhouse.pid ]]; then
  pid="$(cat .pitchfork/clickhouse.pid)"
  if kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}"
    echo "Stopped ClickHouse (${pid})"
  fi
fi

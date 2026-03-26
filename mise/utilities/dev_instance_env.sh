#!/usr/bin/env bash
# Generates directory-scoped development environment variables so that
# multiple worktrees / checkouts can run side-by-side without port or
# database collisions.
#
# Only app-level ports (Phoenix, test server) are scoped. Infrastructure
# services (PostgreSQL, ClickHouse, Daytona) keep their default ports
# since they are shared across checkouts. Database *names* are scoped
# to avoid data collisions.
#
# Sourced automatically by mise via mise.toml.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTANCE_FILE="${PROJECT_ROOT}/.glossia-dev-instance"

# Allow explicit override via environment variable.
if [ -z "${GLOSSIA_DEV_INSTANCE:-}" ]; then
  if [ -f "$INSTANCE_FILE" ]; then
    GLOSSIA_DEV_INSTANCE="$(cat "$INSTANCE_FILE" 2>/dev/null || true)"
  fi

  # Validate: must be a number between 100 and 999.
  if ! [[ "${GLOSSIA_DEV_INSTANCE:-}" =~ ^[1-9][0-9]{2}$ ]]; then
    # Generate a deterministic suffix from the project root path.
    GLOSSIA_DEV_INSTANCE=$(( ( $(printf '%s' "$PROJECT_ROOT" | cksum | cut -d' ' -f1) % 900 ) + 100 ))
    echo "$GLOSSIA_DEV_INSTANCE" > "$INSTANCE_FILE"
  fi
fi

export GLOSSIA_DEV_INSTANCE

# App ports (scoped)
export GLOSSIA_SERVER_PORT=$(( 4050 + GLOSSIA_DEV_INSTANCE ))
export GLOSSIA_SERVER_URL="http://localhost:${GLOSSIA_SERVER_PORT}"
export GLOSSIA_TEST_PORT=$(( 4002 + GLOSSIA_DEV_INSTANCE ))

# Database names (scoped)
export GLOSSIA_DB_SUFFIX="${GLOSSIA_DEV_INSTANCE}"

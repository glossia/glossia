#!/usr/bin/env bash
set -euo pipefail

app_dir="${MISE_PROJECT_ROOT}/app"
cd "${app_dir}"

# ClickHouse has to be listening before the repos are created: `mix setup`
# creates, migrates, and seeds both the PostgreSQL and the ClickHouse repo,
# and verifies each one connects.
mise run clickhouse:start

# `mix setup` is the single entry point: dependencies, the user-agent database,
# the repos, and the JavaScript bundles a fresh clone has none of.
mix setup

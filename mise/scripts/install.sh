#!/usr/bin/env bash
set -euo pipefail

app_dir="${MISE_PROJECT_ROOT}/app"
cd "${app_dir}"

mix deps.get
mise run clickhouse:start

mix ecto.create --repo Glossia.Repo
mix ecto.migrate --repo Glossia.Repo

mix ecto.create --repo Glossia.IngestRepo
mix ecto.migrate --repo Glossia.IngestRepo

mix run priv/repo/seeds.exs

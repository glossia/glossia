#!/usr/bin/env bash
set -euo pipefail

namespace="${GLOSSIA_K8S_NAMESPACE:-glossia}"
monitoring_namespace="${GLOSSIA_K8S_MONITORING_NAMESPACE:-monitoring}"
cert_manager_namespace="${GLOSSIA_K8S_CERT_MANAGER_NAMESPACE:-cert-manager}"
networking_namespace="${GLOSSIA_K8S_NETWORKING_NAMESPACE:-networking}"
postgres_user="${GLOSSIA_K8S_POSTGRES_USER:-glossia}"
postgres_db="${GLOSSIA_K8S_POSTGRES_DB:-glossia_prod}"
clickhouse_db="${GLOSSIA_K8S_CLICKHOUSE_DB:-glossia}"
postgres_host="${GLOSSIA_K8S_POSTGRES_HOST:-glossia-postgres-rw.${namespace}.svc.cluster.local}"
clickhouse_host="${GLOSSIA_K8S_CLICKHOUSE_HOST:-glossia-clickhouse-clickhouse-headless.${namespace}.svc.cluster.local}"

require_env() {
  local name="$1"

  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
}

urlencode() {
  python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to render Kubernetes secrets." >&2
  exit 1
fi

require_env POSTGRES_PASSWORD
require_env SECRET_KEY_BASE
require_env METRICS_BEARER_TOKEN
require_env OPS_AUTH_PASSWORD
require_env SMTP_HOST
require_env SMTP_PORT
require_env SMTP_USERNAME
require_env SMTP_PASSWORD
require_env GF_SECURITY_ADMIN_PASSWORD

postgres_user_encoded="$(urlencode "${postgres_user}")"
postgres_password_encoded="$(urlencode "${POSTGRES_PASSWORD}")"
database_url="ecto://${postgres_user_encoded}:${postgres_password_encoded}@${postgres_host}/${postgres_db}"
clickhouse_url="http://${clickhouse_host}:8123/${clickhouse_db}"

app_secret_args=(
  create secret generic glossia-app-env
  --namespace "${namespace}"
  --dry-run=client
  -o yaml
  --from-literal="GLOSSIA_DATABASE_URL=${database_url}"
  --from-literal="GLOSSIA_CLICKHOUSE_URL=${clickhouse_url}"
  --from-literal="GLOSSIA_SECRET_KEY_BASE=${SECRET_KEY_BASE}"
  --from-literal="GLOSSIA_METRICS_BEARER_TOKEN=${METRICS_BEARER_TOKEN}"
  --from-literal="GLOSSIA_OPS_AUTH_PASSWORD=${OPS_AUTH_PASSWORD}"
  --from-literal="GLOSSIA_SMTP_HOST=${SMTP_HOST}"
  --from-literal="GLOSSIA_SMTP_PORT=${SMTP_PORT}"
  --from-literal="GLOSSIA_SMTP_USERNAME=${SMTP_USERNAME}"
  --from-literal="GLOSSIA_SMTP_PASSWORD=${SMTP_PASSWORD}"
)

for mapping in \
  "GLOSSIA_ENCRYPTION_KEY:ENCRYPTION_KEY" \
  "GLOSSIA_SENTRY_DSN:SENTRY_DSN" \
  "GLOSSIA_SENTRY_DSN_JS:SENTRY_DSN_JS" \
  "GLOSSIA_GITHUB_CLIENT_ID:GITHUB_CLIENT_ID" \
  "GLOSSIA_GITHUB_CLIENT_SECRET:GITHUB_CLIENT_SECRET" \
  "GLOSSIA_GITHUB_WEBHOOK_SECRET:GITHUB_WEBHOOK_SECRET" \
  "GLOSSIA_GITHUB_APP_ID:GITHUB_APP_ID" \
  "GLOSSIA_GITHUB_APP_PRIVATE_KEY:GITHUB_APP_PRIVATE_KEY" \
  "GLOSSIA_GITHUB_APP_SLUG:GITHUB_APP_SLUG" \
  "GLOSSIA_GITLAB_CLIENT_ID:GITLAB_CLIENT_ID" \
  "GLOSSIA_GITLAB_CLIENT_SECRET:GITLAB_CLIENT_SECRET" \
  "GLOSSIA_GITLAB_WEBHOOK_SECRET:GITLAB_WEBHOOK_SECRET" \
  "GLOSSIA_S3_ACCESS_KEY_ID:S3_ACCESS_KEY_ID" \
  "GLOSSIA_S3_SECRET_ACCESS_KEY:S3_SECRET_ACCESS_KEY" \
  "GLOSSIA_S3_ENDPOINT:S3_ENDPOINT" \
  "GLOSSIA_S3_REGION:S3_REGION" \
  "GLOSSIA_S3_BUCKET:S3_BUCKET"
do
  IFS=":" read -r secret_key source_name <<<"${mapping}"
  value="${!source_name:-}"

  if [[ -n "$value" ]]; then
    app_secret_args+=(--from-literal="${secret_key}=${value}")
  fi
done

kubectl "${app_secret_args[@]}"
printf -- "---\n"

kubectl create secret generic glossia-postgres-app \
  --namespace "${namespace}" \
  --type kubernetes.io/basic-auth \
  --dry-run=client \
  -o yaml \
  --from-literal="username=${postgres_user}" \
  --from-literal="password=${POSTGRES_PASSWORD}"
printf -- "---\n"

kubectl create secret generic grafana-admin \
  --namespace "${monitoring_namespace}" \
  --dry-run=client \
  -o yaml \
  --from-literal="admin-user=admin" \
  --from-literal="admin-password=${GF_SECURITY_ADMIN_PASSWORD}"
printf -- "---\n"

kubectl create secret generic grafana-datasource-env \
  --namespace "${monitoring_namespace}" \
  --dry-run=client \
  -o yaml \
  --from-literal="GRAFANA_POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"

if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  cert_manager_secret_args=(
    create secret generic cloudflare-api-token
    --namespace "${cert_manager_namespace}"
    --dry-run=client
    -o yaml
    --from-literal="api-token=${CLOUDFLARE_API_TOKEN}"
  )

  if [[ -n "${CLOUDFLARE_ZONE_ID:-}" ]]; then
    cert_manager_secret_args+=(--from-literal="CLOUDFLARE_ZONE_ID=${CLOUDFLARE_ZONE_ID}")
  fi

  printf -- "---\n"
  kubectl "${cert_manager_secret_args[@]}"

  cloudflare_secret_args=(
    create secret generic cloudflare-api-token
    --namespace "${networking_namespace}"
    --dry-run=client
    -o yaml
    --from-literal="CF_API_TOKEN=${CLOUDFLARE_API_TOKEN}"
  )

  if [[ -n "${CLOUDFLARE_ZONE_ID:-}" ]]; then
    cloudflare_secret_args+=(--from-literal="CLOUDFLARE_ZONE_ID=${CLOUDFLARE_ZONE_ID}")
  fi

  printf -- "---\n"
  kubectl "${cloudflare_secret_args[@]}"
fi

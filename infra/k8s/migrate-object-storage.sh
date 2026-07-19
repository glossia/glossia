#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  migrate-object-storage.sh <target> <copy|check|size|sync> [destination-bucket-confirmation]

Targets:
  production-app
  production-releases
  observability-mimir
  observability-loki
  observability-tempo

The current Kubernetes context must point at the target workload cluster.
The sync mode deletes destination objects that are absent from the source and
therefore requires the destination bucket name as the third argument.
EOF
}

target="${1:-}"
mode="${2:-}"
confirmation="${3:-}"

if [[ -z "$target" || -z "$mode" ]]; then
  usage
  exit 1
fi

case "$target" in
  production-app)
    source_namespace=glossia
    source_secret=glossia-s3
    source_access_key_field=AWS_ACCESS_KEY_ID
    source_secret_key_field=AWS_SECRET_ACCESS_KEY
    source_gateway_namespace=platform
    source_gateway_service=rook-ceph-rgw-glossia-s3
    source_bucket=glossia-production
    destination_namespace=glossia
    destination_secret=glossia-object-storage
    destination_access_key_field=ACCESS_KEY_ID
    destination_secret_key_field=SECRET_ACCESS_KEY
    destination_bucket=glossia-ai-production
    ;;
  production-releases)
    source_namespace=platform
    source_secret=glossia-releases
    source_access_key_field=AWS_ACCESS_KEY_ID
    source_secret_key_field=AWS_SECRET_ACCESS_KEY
    source_gateway_namespace=platform
    source_gateway_service=rook-ceph-rgw-glossia-releases-s3
    source_bucket=releases.glossia.ai
    destination_namespace=platform
    destination_secret=glossia-releases-object-storage
    destination_access_key_field=AWS_ACCESS_KEY_ID
    destination_secret_key_field=AWS_SECRET_ACCESS_KEY
    destination_bucket=glossia-ai-releases
    ;;
  observability-mimir)
    source_namespace=observability
    source_secret=rook-ceph-object-user-glossia-store-mimir
    source_access_key_field=AccessKey
    source_secret_key_field=SecretKey
    source_gateway_namespace=observability
    source_gateway_service=rook-ceph-rgw-glossia-store
    source_bucket=glossia-mimir
    destination_namespace=observability
    destination_secret=glossia-observability-object-storage
    destination_access_key_field=AccessKey
    destination_secret_key_field=SecretKey
    destination_bucket=glossia-ai-mimir
    ;;
  observability-loki)
    source_namespace=observability
    source_secret=rook-ceph-object-user-glossia-store-loki
    source_access_key_field=AccessKey
    source_secret_key_field=SecretKey
    source_gateway_namespace=observability
    source_gateway_service=rook-ceph-rgw-glossia-store
    source_bucket=glossia-loki
    destination_namespace=observability
    destination_secret=glossia-observability-object-storage
    destination_access_key_field=AccessKey
    destination_secret_key_field=SecretKey
    destination_bucket=glossia-ai-loki
    ;;
  observability-tempo)
    source_namespace=observability
    source_secret=rook-ceph-object-user-glossia-store-tempo
    source_access_key_field=AccessKey
    source_secret_key_field=SecretKey
    source_gateway_namespace=observability
    source_gateway_service=rook-ceph-rgw-glossia-store
    source_bucket=glossia-tempo
    destination_namespace=observability
    destination_secret=glossia-observability-object-storage
    destination_access_key_field=AccessKey
    destination_secret_key_field=SecretKey
    destination_bucket=glossia-ai-tempo
    ;;
  *)
    usage
    exit 1
    ;;
esac

case "$mode" in
  copy|check|size)
    ;;
  sync)
    if [[ "$confirmation" != "$destination_bucket" ]]; then
      echo "Refusing destination deletion. Pass '$destination_bucket' as the third argument." >&2
      exit 1
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac

# shellcheck source=./lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

require_commands kubectl rclone base64

temporary_directory="$(mktemp -d)"
port_forward_pid=""

cleanup() {
  if [[ -n "$port_forward_pid" ]] && kill -0 "$port_forward_pid" 2>/dev/null; then
    kill "$port_forward_pid" 2>/dev/null || true
    wait "$port_forward_pid" 2>/dev/null || true
  fi

  unset RCLONE_CONFIG_SOURCE_ACCESS_KEY_ID
  unset RCLONE_CONFIG_SOURCE_SECRET_ACCESS_KEY
  unset RCLONE_CONFIG_DESTINATION_ACCESS_KEY_ID
  unset RCLONE_CONFIG_DESTINATION_SECRET_ACCESS_KEY
  rm -rf -- "$temporary_directory"
}

trap cleanup EXIT INT TERM

export RCLONE_CONFIG_SOURCE_TYPE=s3
export RCLONE_CONFIG_SOURCE_PROVIDER=Ceph
export RCLONE_CONFIG_SOURCE_ACCESS_KEY_ID="$(
  read_kubernetes_secret "$source_namespace" "$source_secret" "$source_access_key_field"
)"
export RCLONE_CONFIG_SOURCE_SECRET_ACCESS_KEY="$(
  read_kubernetes_secret "$source_namespace" "$source_secret" "$source_secret_key_field"
)"
export RCLONE_CONFIG_SOURCE_REGION=us-east-1
export RCLONE_CONFIG_SOURCE_FORCE_PATH_STYLE=true

export RCLONE_CONFIG_DESTINATION_TYPE=s3
export RCLONE_CONFIG_DESTINATION_PROVIDER=Other
export RCLONE_CONFIG_DESTINATION_ACCESS_KEY_ID="$(
  read_kubernetes_secret \
    "$destination_namespace" \
    "$destination_secret" \
    "$destination_access_key_field"
)"
export RCLONE_CONFIG_DESTINATION_SECRET_ACCESS_KEY="$(
  read_kubernetes_secret \
    "$destination_namespace" \
    "$destination_secret" \
    "$destination_secret_key_field"
)"
export RCLONE_CONFIG_DESTINATION_ENDPOINT=https://fsn1.your-objectstorage.com
export RCLONE_CONFIG_DESTINATION_REGION=fsn1
export RCLONE_CONFIG_DESTINATION_FORCE_PATH_STYLE=true

migration_port="${MIGRATION_PORT:-18080}"
port_forward_log="$temporary_directory/port-forward.log"

kubectl -n "$source_gateway_namespace" port-forward \
  "service/$source_gateway_service" \
  "$migration_port:80" >"$port_forward_log" 2>&1 &
port_forward_pid=$!

for _attempt in {1..30}; do
  if grep -q "Forwarding from" "$port_forward_log"; then
    break
  fi

  if ! kill -0 "$port_forward_pid" 2>/dev/null; then
    cat "$port_forward_log" >&2
    exit 1
  fi

  sleep 1
done

if ! grep -q "Forwarding from" "$port_forward_log"; then
  cat "$port_forward_log" >&2
  echo "Timed out while opening the source object storage connection." >&2
  exit 1
fi

export RCLONE_CONFIG_SOURCE_ENDPOINT="http://127.0.0.1:$migration_port"

common_options=(
  --size-only
  --fast-list
  --transfers 8
  --checkers 16
  --metadata
  --stats 30s
)

source_remote="source:$source_bucket"
destination_remote="destination:$destination_bucket"

case "$mode" in
  copy)
    rclone copy "$source_remote" "$destination_remote" "${common_options[@]}"
    rclone check "$source_remote" "$destination_remote" --size-only --one-way
    ;;
  check)
    rclone check "$source_remote" "$destination_remote" --size-only --one-way
    ;;
  size)
    echo "Source: $source_bucket"
    rclone size "$source_remote" --fast-list
    echo "Destination: $destination_bucket"
    rclone size "$destination_remote" --fast-list
    ;;
  sync)
    rclone sync "$source_remote" "$destination_remote" "${common_options[@]}"
    rclone check "$source_remote" "$destination_remote" --size-only --one-way
    ;;
esac

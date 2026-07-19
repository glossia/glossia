#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  restore-compact-observability.sh <glitchtip-object-key> <grafana-object-key>

The current Kubernetes context must point at the production cluster. Before
running this command, install the compact observability release with the
GlitchTip and Grafana replica counts set to zero.

The command streams both archives from the existing off-cluster backup bucket.
It does not write credentials or backup contents to the local filesystem.
EOF
}

glitchtip_object_key="${1:-}"
grafana_object_key="${2:-}"

if [[ -z "$glitchtip_object_key" || -z "$grafana_object_key" ]]; then
  usage
  exit 1
fi

for command_name in aws base64 gzip jq kubectl pg_restore psql; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 1
  fi
done

namespace=observability
backup_secret_namespace=glossia
backup_secret_name=glossia-db-backup
backup_bucket=glossia-production-db-backups
backup_endpoint=https://bb7ccb20a20a58b2d5242d0277c750fe.eu.r2.cloudflarestorage.com
database_cluster=glitchtip-postgres
database_service=glitchtip-postgres-rw
database_name=glitchtip
database_port="${OBSERVABILITY_RESTORE_DATABASE_PORT:-15432}"
grafana_deployment=observability-grafana
grafana_claim=observability-grafana
temporary_directory="$(mktemp -d)"
port_forward_log="$temporary_directory/database-port-forward.log"
port_forward_pid=""
grafana_restore_pod=""

cleanup() {
  if [[ -n "$port_forward_pid" ]] && kill -0 "$port_forward_pid" 2>/dev/null; then
    kill "$port_forward_pid" 2>/dev/null || true
    wait "$port_forward_pid" 2>/dev/null || true
  fi

  if [[ -n "$grafana_restore_pod" ]]; then
    kubectl -n "$namespace" delete pod "$grafana_restore_pod" \
      --ignore-not-found --wait=false >/dev/null 2>&1 || true
  fi

  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_DEFAULT_REGION
  unset AWS_PAGER
  unset PGPASSWORD
  unset backup_access_key_id
  unset backup_secret_access_key
  unset backup_region
  unset database_username
  unset database_password

  if [[ -f "$port_forward_log" ]]; then
    unlink "$port_forward_log"
  fi
  rmdir "$temporary_directory" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

read_kubernetes_secret() {
  local secret_namespace="$1"
  local secret_name="$2"
  local field="$3"

  kubectl -n "$secret_namespace" get secret "$secret_name" \
    -o "jsonpath={.data.${field}}" | base64 --decode
}

assert_scaled_to_zero() {
  local deployment_name="$1"
  local replicas

  replicas="$(
    kubectl -n "$namespace" get deployment "$deployment_name" \
      -o jsonpath='{.spec.replicas}'
  )"
  if [[ "$replicas" != "0" ]]; then
    echo "Refusing restore: deployment/$deployment_name has $replicas replicas." >&2
    exit 1
  fi
}

assert_scaled_to_zero glitchtip-web
assert_scaled_to_zero "$grafana_deployment"

kubectl -n "$namespace" wait \
  --for=condition=Ready \
  "cluster.postgresql.cnpg.io/$database_cluster" \
  --timeout=10m

backup_access_key_id="$(
  read_kubernetes_secret \
    "$backup_secret_namespace" "$backup_secret_name" ACCESS_KEY_ID
)"
backup_secret_access_key="$(
  read_kubernetes_secret \
    "$backup_secret_namespace" "$backup_secret_name" SECRET_ACCESS_KEY
)"
backup_region="$(
  read_kubernetes_secret \
    "$backup_secret_namespace" "$backup_secret_name" REGION
)"
database_username="$(
  read_kubernetes_secret "$namespace" glitchtip-app username
)"
database_password="$(
  read_kubernetes_secret "$namespace" glitchtip-app password
)"

export AWS_ACCESS_KEY_ID="$backup_access_key_id"
export AWS_SECRET_ACCESS_KEY="$backup_secret_access_key"
export AWS_DEFAULT_REGION="$backup_region"
export AWS_PAGER=""
export PGPASSWORD="$database_password"

aws_command=(
  aws
  --endpoint-url "$backup_endpoint"
  --region "$backup_region"
)

for object_key in "$glitchtip_object_key" "$grafana_object_key"; do
  "${aws_command[@]}" s3api head-object \
    --bucket "$backup_bucket" \
    --key "$object_key" >/dev/null
done

kubectl -n "$namespace" port-forward \
  "service/$database_service" \
  "$database_port:5432" >"$port_forward_log" 2>&1 &
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
  echo "Timed out while opening the database connection." >&2
  exit 1
fi

echo "Restoring GlitchTip database"
"${aws_command[@]}" s3 cp \
  "s3://$backup_bucket/$glitchtip_object_key" - \
  --no-progress |
  pg_restore \
    --host 127.0.0.1 \
    --port "$database_port" \
    --username "$database_username" \
    --dbname "$database_name" \
    --clean \
    --if-exists \
    --no-owner \
    --no-privileges \
    --exit-on-error

restored_table_count="$(
  psql \
    --host 127.0.0.1 \
    --port "$database_port" \
    --username "$database_username" \
    --dbname "$database_name" \
    --tuples-only \
    --no-align \
    --command="select count(*) from information_schema.tables where table_schema = 'public';"
)"
if [[ "$restored_table_count" -eq 0 ]]; then
  echo "GlitchTip restore produced no public tables." >&2
  exit 1
fi
echo "GlitchTip restore verified: $restored_table_count public tables"

kill "$port_forward_pid" 2>/dev/null || true
wait "$port_forward_pid" 2>/dev/null || true
port_forward_pid=""

echo "Verifying Grafana archive"
"${aws_command[@]}" s3 cp \
  "s3://$backup_bucket/$grafana_object_key" - \
  --no-progress | gzip -t

grafana_restore_pod="grafana-restore-$(date -u +%Y%m%d%H%M%S)"
jq -n \
  --arg namespace "$namespace" \
  --arg pod_name "$grafana_restore_pod" \
  --arg claim_name "$grafana_claim" \
  '{
    apiVersion: "v1",
    kind: "Pod",
    metadata: {
      namespace: $namespace,
      name: $pod_name,
      labels: {
        "app.kubernetes.io/name": "grafana-restore",
        "app.kubernetes.io/part-of": "glossia"
      }
    },
    spec: {
      restartPolicy: "Never",
      nodeSelector: {
        "node.cluster.x-k8s.io/pool": "stateful"
      },
      tolerations: [
        {
          key: "node.cluster.x-k8s.io/pool",
          operator: "Equal",
          value: "stateful",
          effect: "NoSchedule"
        }
      ],
      containers: [
        {
          name: "restore",
          image: "alpine:3.22",
          command: ["sh", "-c", "sleep 3600"],
          securityContext: {
            allowPrivilegeEscalation: false,
            capabilities: {drop: ["ALL"]},
            runAsUser: 0,
            seccompProfile: {type: "RuntimeDefault"}
          },
          volumeMounts: [
            {name: "grafana", mountPath: "/data"}
          ]
        }
      ],
      volumes: [
        {
          name: "grafana",
          persistentVolumeClaim: {claimName: $claim_name}
        }
      ]
    }
  }' | kubectl apply -f -

kubectl -n "$namespace" wait \
  --for=condition=Ready "pod/$grafana_restore_pod" --timeout=5m

echo "Restoring Grafana data"
"${aws_command[@]}" s3 cp \
  "s3://$backup_bucket/$grafana_object_key" - \
  --no-progress |
  kubectl -n "$namespace" exec -i "$grafana_restore_pod" -- \
    tar -xzf - -C /data

kubectl -n "$namespace" exec "$grafana_restore_pod" -- \
  chown -R 472:472 /data

grafana_entry_count="$(
  kubectl -n "$namespace" exec "$grafana_restore_pod" -- \
    find /data -mindepth 1 -maxdepth 2 -print | wc -l | tr -d ' '
)"
if [[ "$grafana_entry_count" -eq 0 ]]; then
  echo "Grafana restore produced no files." >&2
  exit 1
fi

kubectl -n "$namespace" delete pod "$grafana_restore_pod" --wait=true
grafana_restore_pod=""

echo "Grafana restore verified: $grafana_entry_count entries"
echo "Restore complete. Start the release without the zero-replica overrides."

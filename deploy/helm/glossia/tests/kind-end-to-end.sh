#!/usr/bin/env bash
set -euo pipefail

cluster_name="${KIND_CLUSTER_NAME:-glossia-chart-test}"
namespace="${KIND_NAMESPACE:-glossia}"
release="${HELM_RELEASE:-glossia}"
resource_name="${RESOURCE_NAME:-glossia}"
chart_dir="${CHART_DIR:-deploy/helm/glossia}"
values_file="${VALUES_FILE:-deploy/helm/glossia/values-kind-test.yaml}"
created_cluster=false

cleanup() {
  if [ "${created_cluster}" = "true" ] && [ "${KEEP_KIND_CLUSTER:-false}" != "true" ]; then
    kind delete cluster --name "${cluster_name}" >/dev/null 2>&1 || true
  fi
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local description="$3"

  if [ "${actual}" != "${expected}" ]; then
    echo "::error::${description}: expected '${expected}', got '${actual}'"
    exit 1
  fi
}

deployment_env_value() {
  local name="$1"

  kubectl -n "${namespace}" get deployment "${resource_name}" \
    -o jsonpath="{.spec.template.spec.containers[?(@.name=='web')].env[?(@.name=='${name}')].value}"
}

trap cleanup EXIT

if kind get clusters | grep -Fxq "${cluster_name}"; then
  echo "::error::kind cluster '${cluster_name}' already exists. Set KIND_CLUSTER_NAME to a unique value."
  exit 1
fi

created_cluster=true
kind create cluster --name "${cluster_name}" --wait 120s
kubectl config use-context "kind-${cluster_name}"

kubectl create namespace "${namespace}"

kubectl -n "${namespace}" create secret generic glossia-app-env \
  --from-literal=GLOSSIA_DATABASE_URL=ecto://postgres:postgres@postgres.example.internal/glossia \
  --from-literal=GLOSSIA_CLICKHOUSE_URL=http://clickhouse.example.internal:8123/glossia \
  --from-literal=GLOSSIA_SECRET_KEY_BASE=kind-test-secret-key-base-kind-test-secret-key-base-kind-test-secret \
  --from-literal=GLOSSIA_METRICS_BEARER_TOKEN=kind-test-metrics-token \
  --from-literal=GLOSSIA_OPS_AUTH_PASSWORD=kind-test-ops-password \
  --from-literal=GLOSSIA_SMTP_HOST=smtp.example.internal \
  --from-literal=GLOSSIA_SMTP_USERNAME=kind-test-smtp-user \
  --from-literal=GLOSSIA_SMTP_PASSWORD=kind-test-smtp-password \
  --from-literal=RELEASE_COOKIE=kind_test_release_cookie

helm upgrade --install "${release}" "${chart_dir}" \
  --namespace "${namespace}" \
  --values "${values_file}"

kubectl -n "${namespace}" get serviceaccount "${resource_name}" >/dev/null
kubectl -n "${namespace}" get role "${resource_name}-flame" >/dev/null
kubectl -n "${namespace}" get rolebinding "${resource_name}-flame" >/dev/null
kubectl -n "${namespace}" get deployment "${resource_name}" >/dev/null

for verb in create get list delete patch; do
  kubectl auth can-i "${verb}" pods \
    --namespace "${namespace}" \
    --as "system:serviceaccount:${namespace}:${resource_name}" \
    | grep -qx "yes"
done

assert_equals "0" \
  "$(kubectl -n "${namespace}" get deployment "${resource_name}" -o jsonpath='{.spec.replicas}')" \
  "deployment replica count"

assert_equals "${resource_name}" \
  "$(kubectl -n "${namespace}" get deployment "${resource_name}" -o jsonpath='{.spec.template.spec.serviceAccountName}')" \
  "deployment service account"

assert_equals "agent" \
  "$(kubectl -n "${namespace}" get deployment "${resource_name}" -o jsonpath='{.spec.template.metadata.labels.app\.kubernetes\.io/component}')" \
  "deployment pod component label"

assert_equals "agent" \
  "$(kubectl -n "${namespace}" get service "${resource_name}" -o jsonpath='{.spec.selector.app\.kubernetes\.io/component}')" \
  "service component selector"

assert_equals "agent" \
  "$(kubectl -n "${namespace}" get service "${resource_name}-headless" -o jsonpath='{.spec.selector.app\.kubernetes\.io/component}')" \
  "headless service component selector"

assert_equals "k8s" "$(deployment_env_value GLOSSIA_FLAME_BACKEND)" "FLAME backend"
assert_equals "2" "$(deployment_env_value GLOSSIA_FLAME_MAX)" "FLAME maximum runners"
assert_equals "kata-qemu" \
  "$(deployment_env_value GLOSSIA_FLAME_RUNTIME_CLASS_NAME)" \
  "FLAME runner runtime class"

helm uninstall "${release}" --namespace "${namespace}"

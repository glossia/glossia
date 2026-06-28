#!/usr/bin/env bash

glossia_e2e_safe_name() {
  printf "%s" "$1" \
    | tr "[:upper:]" "[:lower:]" \
    | sed -E "s/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g" \
    | cut -c 1-16
}

glossia_e2e_run_id() {
  local run_id="${GLOSSIA_E2E_RUN_ID:-}"

  if [ -z "${run_id}" ]; then
    run_id="$(glossia_e2e_safe_name "$(date +%s)-$$")"
  fi

  if [ -z "${run_id}" ]; then
    run_id="local-$$"
  fi

  printf "%s" "${run_id}"
}

glossia_e2e_cluster_name() {
  if [ -n "${KIND_CLUSTER_NAME:-}" ]; then
    printf "%s" "${KIND_CLUSTER_NAME}"
  else
    printf "glossia-chart-e2e-%s" "$(glossia_e2e_run_id)"
  fi
}

glossia_e2e_kubernetes_context() {
  printf "%s" "${KUBECTL_CONTEXT:-kind-${KIND_CLUSTER_NAME}}"
}

glossia_e2e_kubectl() {
  kubectl --context "$(glossia_e2e_kubernetes_context)" "$@"
}

glossia_e2e_create_cluster() {
  local cluster_name
  cluster_name="$(glossia_e2e_cluster_name)"

  if kind get clusters 2>/dev/null | grep -Fxq "${cluster_name}"; then
    echo "::error::kind cluster '${cluster_name}' already exists. Set KIND_CLUSTER_NAME to a unique value." >&2
    return 1
  fi

  kind create cluster --name "${cluster_name}" --wait "${KIND_WAIT:-120s}" >/dev/null
  GLOSSIA_E2E_CLUSTER_CREATED=true
}

glossia_e2e_delete_cluster() {
  if [ "${GLOSSIA_E2E_CLUSTER_CREATED:-false}" != "true" ]; then
    return 0
  fi

  if [ "${KEEP_KIND_CLUSTER:-false}" = "true" ]; then
    return 0
  fi

  kind delete cluster --name "$(glossia_e2e_cluster_name)" >/dev/null 2>&1 || true
  GLOSSIA_E2E_CLUSTER_CREATED=false
}

glossia_e2e_require_cluster() {
  if [ -z "${KIND_CLUSTER_NAME:-}" ]; then
    echo "::error::KIND_CLUSTER_NAME is required. Run deploy/helm/glossia/e2e/kind.sh to create the shared test cluster." >&2
    return 1
  fi

  if ! kind get clusters 2>/dev/null | grep -Fxq "${KIND_CLUSTER_NAME}"; then
    echo "::error::kind cluster '${KIND_CLUSTER_NAME}' does not exist." >&2
    return 1
  fi
}

glossia_e2e_install_release() {
  set -euo pipefail

  local suffix="$1"
  local run_id
  run_id="$(glossia_e2e_run_id)"

  GLOSSIA_E2E_NAMESPACE="glossia-e2e-${suffix}-${run_id}"
  GLOSSIA_E2E_RELEASE="glossia-${suffix}-${run_id}"
  GLOSSIA_E2E_RESOURCE_NAME="${RESOURCE_NAME:-glossia}"
  export GLOSSIA_E2E_NAMESPACE GLOSSIA_E2E_RELEASE GLOSSIA_E2E_RESOURCE_NAME

  glossia_e2e_require_cluster

  glossia_e2e_kubectl create namespace "${GLOSSIA_E2E_NAMESPACE}" >/dev/null

  glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" create secret generic glossia-app-env \
    --from-literal=GLOSSIA_DATABASE_URL=ecto://postgres:postgres@postgres.example.internal/glossia \
    --from-literal=GLOSSIA_CLICKHOUSE_URL=http://clickhouse.example.internal:8123/glossia \
    --from-literal=GLOSSIA_SECRET_KEY_BASE=kind-test-secret-key-base-kind-test-secret-key-base-kind-test-secret \
    --from-literal=GLOSSIA_METRICS_BEARER_TOKEN=kind-test-metrics-token \
    --from-literal=GLOSSIA_OPS_AUTH_PASSWORD=kind-test-ops-password \
    --from-literal=GLOSSIA_SMTP_HOST=smtp.example.internal \
    --from-literal=GLOSSIA_SMTP_USERNAME=kind-test-smtp-user \
    --from-literal=GLOSSIA_SMTP_PASSWORD=kind-test-smtp-password \
    --from-literal=RELEASE_COOKIE=kind_test_release_cookie >/dev/null

  helm upgrade --install "${GLOSSIA_E2E_RELEASE}" "${CHART_DIR:-deploy/helm/glossia}" \
    --kube-context "$(glossia_e2e_kubernetes_context)" \
    --namespace "${GLOSSIA_E2E_NAMESPACE}" \
    --values "${VALUES_FILE:-deploy/helm/glossia/values-e2e.yaml}" >/dev/null
}

glossia_e2e_uninstall_release() {
  if [ -n "${GLOSSIA_E2E_RELEASE:-}" ] && [ -n "${GLOSSIA_E2E_NAMESPACE:-}" ]; then
    helm uninstall "${GLOSSIA_E2E_RELEASE}" \
      --kube-context "$(glossia_e2e_kubernetes_context)" \
      --namespace "${GLOSSIA_E2E_NAMESPACE}" >/dev/null 2>&1 || true
    glossia_e2e_kubectl delete namespace "${GLOSSIA_E2E_NAMESPACE}" --wait=true >/dev/null 2>&1 || true
  fi
}

glossia_e2e_assert_equals() {
  local expected="$1"
  local actual="$2"
  local description="$3"

  if [ "${actual}" != "${expected}" ]; then
    echo "::error::${description}: expected '${expected}', got '${actual}'" >&2
    return 1
  fi
}

glossia_e2e_deployment_env_value() {
  local name="$1"

  glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get deployment "${GLOSSIA_E2E_RESOURCE_NAME}" \
    -o jsonpath="{.spec.template.spec.containers[?(@.name=='web')].env[?(@.name=='${name}')].value}"
}

glossia_e2e_assert_deployment() {
  glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get serviceaccount "${GLOSSIA_E2E_RESOURCE_NAME}" >/dev/null
  glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get deployment "${GLOSSIA_E2E_RESOURCE_NAME}" >/dev/null

  glossia_e2e_assert_equals "0" \
    "$(glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get deployment "${GLOSSIA_E2E_RESOURCE_NAME}" -o jsonpath='{.spec.replicas}')" \
    "deployment replica count" || return 1

  glossia_e2e_assert_equals "${GLOSSIA_E2E_RESOURCE_NAME}" \
    "$(glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get deployment "${GLOSSIA_E2E_RESOURCE_NAME}" -o jsonpath='{.spec.template.spec.serviceAccountName}')" \
    "deployment service account" || return 1

  glossia_e2e_assert_equals "agent" \
    "$(glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get deployment "${GLOSSIA_E2E_RESOURCE_NAME}" -o jsonpath='{.spec.template.metadata.labels.app\.kubernetes\.io/component}')" \
    "deployment pod component label" || return 1

  echo "deployment ok"
}

glossia_e2e_assert_runner_permissions() {
  glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get role "${GLOSSIA_E2E_RESOURCE_NAME}-flame" >/dev/null
  glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get rolebinding "${GLOSSIA_E2E_RESOURCE_NAME}-flame" >/dev/null

  for verb in create get list delete patch; do
    glossia_e2e_assert_equals "yes" \
      "$(glossia_e2e_kubectl auth can-i "${verb}" pods \
        --namespace "${GLOSSIA_E2E_NAMESPACE}" \
        --as "system:serviceaccount:${GLOSSIA_E2E_NAMESPACE}:${GLOSSIA_E2E_RESOURCE_NAME}")" \
      "service account can ${verb} pods" || return 1
  done

  echo "runner permissions ok"
}

glossia_e2e_assert_service_selectors() {
  glossia_e2e_assert_equals "agent" \
    "$(glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get service "${GLOSSIA_E2E_RESOURCE_NAME}" -o jsonpath='{.spec.selector.app\.kubernetes\.io/component}')" \
    "service component selector" || return 1

  glossia_e2e_assert_equals "agent" \
    "$(glossia_e2e_kubectl -n "${GLOSSIA_E2E_NAMESPACE}" get service "${GLOSSIA_E2E_RESOURCE_NAME}-headless" -o jsonpath='{.spec.selector.app\.kubernetes\.io/component}')" \
    "headless service component selector" || return 1

  echo "service selectors ok"
}

glossia_e2e_assert_runner_configuration() {
  glossia_e2e_assert_equals "k8s" "$(glossia_e2e_deployment_env_value GLOSSIA_FLAME_BACKEND)" "runner backend" || return 1
  glossia_e2e_assert_equals "2" "$(glossia_e2e_deployment_env_value GLOSSIA_FLAME_MAX)" "maximum runners" || return 1
  glossia_e2e_assert_equals "kata-qemu" \
    "$(glossia_e2e_deployment_env_value GLOSSIA_FLAME_RUNTIME_CLASS_NAME)" \
    "runner runtime class" || return 1

  echo "runner configuration ok"
}

glossia_e2e_main() {
  set -euo pipefail

  export GLOSSIA_E2E_RUN_ID="${GLOSSIA_E2E_RUN_ID:-$(glossia_e2e_run_id)}"
  export KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-$(glossia_e2e_cluster_name)}"

  cleanup() {
    local status=$?
    set +e
    glossia_e2e_delete_cluster
    exit "${status}"
  }

  trap cleanup EXIT

  glossia_e2e_create_cluster
  shellspec --jobs "${SHELLSPEC_JOBS:-4}" deploy/helm/glossia/e2e
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  glossia_e2e_main "$@"
fi

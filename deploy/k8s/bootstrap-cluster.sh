#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

kubectl apply -f deploy/k8s/manifests/base/namespaces.yaml

kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/artifacts/main/manifests/operator-manifest.yaml
kubectl rollout status deployment/cnpg-controller-manager -n cnpg-system --timeout=10m

kubectl apply -f https://github.com/ClickHouse/clickhouse-operator/releases/latest/download/clickhouse-operator.yaml
kubectl wait --for=condition=Available deployment -n clickhouse-operator-system -l app.kubernetes.io/name=clickhouse-operator --timeout=10m

if kubectl -n cert-manager get secret cloudflare-api-token >/dev/null 2>&1; then
  kubectl apply -f deploy/k8s/manifests/base/cluster-issuer-cloudflare-dns01.yaml
else
  kubectl apply -f deploy/k8s/manifests/base/cluster-issuer-http01.yaml
fi

kubectl apply -f deploy/k8s/manifests/data/postgres-cluster.yaml
kubectl apply -f deploy/k8s/manifests/data/clickhouse-cluster.yaml

if kubectl -n networking get secret cloudflare-api-token >/dev/null 2>&1; then
  helm_args=()
  cloudflare_zone_id_b64="$(kubectl -n networking get secret cloudflare-api-token -o jsonpath='{.data.CLOUDFLARE_ZONE_ID}')"

  if [[ -n "${cloudflare_zone_id_b64}" ]]; then
    cloudflare_zone_id="$(printf '%s' "${cloudflare_zone_id_b64}" | base64 --decode)"
    helm_args+=(--set-string "extraArgs.zone-id-filter=${cloudflare_zone_id}")
  fi

  helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ >/dev/null 2>&1 || true
  helm repo update external-dns

  helm upgrade --install external-dns external-dns/external-dns \
    --namespace networking \
    --version 1.20.0 \
    --values deploy/k8s/helm-values/external-dns.yaml \
    "${helm_args[@]}"
else
  echo "Skipping external-dns install because networking/cloudflare-api-token is missing."
fi

helm repo add grafana-community https://grafana-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update grafana-community

helm upgrade --install grafana grafana-community/grafana \
  --namespace monitoring \
  --values deploy/k8s/helm-values/grafana.yaml

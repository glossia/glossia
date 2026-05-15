#!/usr/bin/env bash
# Bootstrap the Glossia app-level resources on an existing Kubernetes
# cluster.
#
# Platform-level bootstrap (CAPI + caph mgmt cluster, Cilium, HCCM,
# hcloud-csi, cert-manager / ingress-nginx / external-dns / ESO,
# CNPG operator, ClickHouse operator) lives in the `glossia/infra`
# repo — see infra/k8s/onboarding.md for the runbook. This script
# only handles resources that belong to the app's release lifecycle.
#
# Run order from a clean cluster (after the infra-side bootstrap):
#   1. ./deploy/k8s/bootstrap-cluster.sh   # this script
#   2. trigger the GitHub Actions deploy.yml workflow

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

kubectl apply -f deploy/k8s/manifests/base/namespaces.yaml

kubectl apply -f deploy/k8s/manifests/data/postgres-cluster.yaml
kubectl apply -f deploy/k8s/manifests/data/clickhouse-cluster.yaml

helm repo add grafana-community https://grafana-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update grafana-community

helm upgrade --install grafana grafana-community/grafana \
  --namespace monitoring \
  --values deploy/k8s/helm-values/grafana.yaml

# glossia-observability

Self-hosted observability stack for the dedicated `glossia-observability`
Hetzner cluster. Bundles:

| Component | Subchart | Role |
|---|---|---|
| Rook-Ceph (cluster + RGW) | `rook-ceph-cluster` | In-cluster S3 object store backing Mimir/Loki/Tempo |
| Mimir | `mimir-distributed` | Prometheus-compatible metrics store, S3-backed |
| Loki | `loki` (SimpleScalable) | Log store, S3-backed |
| Tempo | `tempo-distributed` | OTLP-native traces store, S3-backed |
| Grafana | `grafana` | UI + datasources pre-pointed at the three above |

Receives metrics/logs/traces pushed from other Glossia workload clusters
via Grafana Alloy (`deploy/helm/glossia-alloy`). Lives in a separate
failure domain from production so dashboards survive a production
outage.

## Pre-install (one-time, in this order)

1. **Provision the cluster** per `infra/k8s/onboarding.md` §B.8 — apply
   `infra/k8s/clusters/cluster-observability.yaml`, fetch its
   kubeconfig, install Cilium / HCCM / hcloud-csi, install the platform
   chart with `infra/helm/platform/values-observability.yaml`, install the
   `onepassword` ClusterSecretStore with
   `VAULT_NAME=glossia-observability`.
2. **Install the Rook-Ceph operator** as a separate Helm release. The
   operator owns the CRDs (`CephCluster`, `CephObjectStore`, etc.) that
   this chart's CRs depend on; bundling it as a subchart would race the
   CRDs against the CRs at install time.
   ```bash
   helm repo add rook-release https://charts.rook.io/release
   helm upgrade --install rook-ceph rook-release/rook-ceph \
     --version v1.16.4 \
     -n rook-ceph --create-namespace \
     -f infra/helm/observability/rook-operator-values-observability.yaml
   ```
   Wait for the operator Deployment to be Ready:
   ```bash
   kubectl -n rook-ceph rollout status deploy/rook-ceph-operator --timeout=5m
   ```
3. **Populate 1Password** vault `glossia-observability` with:
   - Item `kubernetes` — fields `GF_SECURITY_ADMIN_USER`,
     `GF_SECURITY_ADMIN_PASSWORD` (Grafana root login).
   - Item `push-endpoints-auth` — single field `htpasswd` holding the
     full htpasswd content for every workload cluster shipping to
     this observability cluster. One line per token, e.g.:
     ```
     glossia-production:$2y$10$abc...
     glossia-staging:$2y$10$xyz...
     ```
     Generate each line with `htpasswd -B -n <cluster-name>` locally
     (B = bcrypt). Store the matching **plain** tokens in each
     workload cluster's own vault (item
     `push-token-<cluster-name>`, field `token`) so its Alloy install
     can consume them.

## Install

```bash
helm repo add rook-release https://charts.rook.io/release
helm repo add grafana https://grafana.github.io/helm-charts
helm dependency update infra/helm/observability

helm upgrade --install observability infra/helm/observability \
  -n observability --create-namespace \
  -f infra/helm/observability/values-hetzner.yaml
```

First install takes ~15 min: Ceph mons + OSDs need to bootstrap, RGW
needs to provision its pools, then Mimir/Loki/Tempo come up. Monitor:

```bash
kubectl -n rook-ceph get pods -w
kubectl -n observability get pods -w
```

## Verify

```bash
# Ceph health
kubectl -n observability exec deploy/rook-ceph-tools -- ceph status

# RGW reachable + tenant creds resolvable
kubectl -n observability get secret \
  rook-ceph-object-user-glossia-store-mimir \
  rook-ceph-object-user-glossia-store-loki \
  rook-ceph-object-user-glossia-store-tempo

# Observability stack readiness
kubectl -n observability get pods,hpa

# Grafana
curl -fsS https://grafana.glossia.ai/api/health

# Push path (basic-auth round-trip)
curl -fsS -u glossia-production:<plain-token> \
  https://mimir.glossia.ai/ready
```

End-to-end test: install `deploy/helm/glossia-alloy` on the
`glossia-production` cluster, wait 5 minutes, then run
`up{job="glossia"}` in Grafana. Series should appear.

## Storage scaling

Bucket capacity for Mimir/Loki/Tempo scales by growing the Ceph OSD
PVCs (Hetzner volumes resize online up to 10 TiB) or by adding OSDs.

- **Grow existing OSDs** (no downtime): bump
  `rook-ceph-cluster.cephClusterSpec.storage.storageClassDeviceSets[0]
  .volumeClaimTemplates[0].spec.resources.requests.storage` in
  `values.yaml`, `helm upgrade`. The Hetzner CSI resizes each volume
  online; Ceph picks up the new size automatically.
- **Add more OSDs** (one per Ceph node): bump `count`. Requires
  enough headroom on existing nodes; if not, add a new
  MachineDeployment replica to
  `infra/k8s/clusters/cluster-observability.yaml` first.

Retention bounds (Mimir 30d / Loki 14d / Tempo 7d) cap accumulation.
Tune them in `values.yaml` if you need longer.

## Teardown

```bash
helm -n observability uninstall observability
helm -n rook-ceph uninstall rook-ceph
# CRDs + OSD PVCs survive uninstall by design (Rook safety). Clean up
# with kubectl delete pvc,crd ... if you really mean it.
```

# Consolidate production and observability

This runbook moves observability into the production Kubernetes cluster and
reduces the steady-state infrastructure to three CX53 workers, one production
control-plane server, and one management server. It keeps the dedicated
control-plane server so application workloads cannot starve cluster
administration during a traffic or telemetry spike.

The migration is blue-green at the worker-pool level. Three new workers are
created before any old worker is removed. The separate observability cluster
remains the rollback target until the shared deployment has been healthy for
seven days.

## Expected cost

The estimate uses Hetzner's July 2026 prices and the current volume inventory.
The compact observability profile adds approximately 70 gibibytes of direct
block storage after the 700 gibibytes of Ceph backing volumes are removed.

| Resource | Monthly cost |
|---|---:|
| Three CX53 workers | €88.47 |
| Existing CPX22 production control plane | €19.49 |
| Replacement CX23 management server | €5.49 |
| Approximately 660 gibibytes of block storage | €37.75 |
| One ingress load balancer | €7.49 |
| Hetzner Object Storage | €6.49 |
| Five public Internet addresses | €2.50 |
| **Expected steady state** | **€167.68** |

Before the management server is rebuilt on CX23, the expected total is
€181.68. Rebuilding that server is intentionally last because the existing
management cluster controls every worker transition.

The transition temporarily adds three CX53 workers while retaining the old
workers. The full-month equivalent peaks near €552, but Hetzner bills servers
hourly when they are removed before the monthly cap. Keep the overlap short,
but never remove the old pools before validation passes.

## Safety conditions

Do not retire a cluster, worker pool, Ceph volume, or database volume until all
of these conditions hold:

1. The source has a verified off-cluster backup.
2. The destination has served production reads and writes successfully.
3. The old resource has remained available for rollback for seven days.
4. A second operator has reviewed the exact resource names being removed.

The checked-in migration flags remain `false` by default. Merging the
preparation does not move a workload or remove a server.

## 1. Finish the object-storage migration

Complete `infra/k8s/object-storage-migration.md` through the production and
observability object cutovers. Do not continue until these lines are present in
`infra/k8s/object-storage-migration-state`:

```text
production_object_storage=true
observability_object_storage=true
```

Ceph can remain present during the next steps. The compact observability
release will not use it.

## 2. Add the combined workers

Change the `workload-cluster-production` path in
`infra/k8s/mgmt/flux/workload-clusters.yaml` to:

```yaml
path: ./infra/k8s/clusters/profiles/consolidation-production
```

Commit the change and wait for the three `md-combined` machines and nodes to
become ready. The transition profile only adds workers. It does not replace or
remove either existing pool.

On the management cluster:

```bash
kubectl -n org-glossia get machines \
  -l cluster.x-k8s.io/cluster-name=glossia-production -w
```

On the production cluster:

```bash
kubectl get nodes -o wide
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory
```

Confirm that all three CX53 nodes are ready and that total allocatable memory
is sufficient with one of them excluded. If the Kubernetes Metrics Server is
available, also inspect current use with `kubectl top nodes`.

## 3. Add the observability secret store to production

Create a second read-only Infisical machine identity secret in the production
cluster. Use the existing observability project identity, but a distinct
Kubernetes Secret name:

```bash
kubectl -n infisical create secret generic \
  infisical-observability-universal-auth \
  --from-literal=clientId='<client identifier>' \
  --from-literal=clientSecret='<client secret>'

kubectl apply -f \
  infra/k8s/mgmt/bootstrap/infisical-secretstore-observability-shared-cluster.yaml

kubectl wait --for=condition=Ready \
  clustersecretstore/infisical-observability --timeout=2m
```

Do not store either credential in Git.

## 4. Restore compact observability into production

Back up the GlitchTip PostgreSQL database and the Grafana persistent data from
the observability cluster. Stop the telemetry writers and perform the final
object synchronization described in the object-storage runbook.

Install the compact release into production without public ingresses while the
database and Grafana data are restored:

```bash
helm dependency update infra/helm/observability
helm upgrade --install observability infra/helm/observability \
  --namespace observability \
  --create-namespace \
  --values infra/helm/observability/values-hetzner.yaml \
  --values infra/helm/observability/values-object-storage-hetzner.yaml \
  --values infra/helm/observability/values-compact-hetzner.yaml \
  --set ingress.enabled=false \
  --timeout 30m
```

The compact profile starts one replica of each observability component, keeps
metrics for seven days, logs for three days, and traces for two days. Local
state uses direct Hetzner block volumes:

- Mimir: 20 gibibytes across its ingester, store gateway, and compactor.
- Loki: 15 gibibytes across its writer and backend.
- Tempo: 10 gibibytes for its ingester.
- Grafana: 5 gibibytes.
- GlitchTip PostgreSQL: 20 gibibytes.

Restore the database and Grafana data, then verify recent and historical
queries directly through local port forwards before exposing the ingresses.

## 5. Cut traffic over

Delete the old observability ingresses during the maintenance window so the
old and new clusters cannot compete over the same records. Then set all three
observability flags to `true`:

```text
observability_object_storage=true
observability_ceph_removed=true
observability_on_production=true
```

Commit the flags. The infrastructure workflow will target the production
cluster, apply the object-storage and compact overlays, and enable the public
ingresses there.

Verify all public endpoints, application telemetry delivery, Grafana queries,
and GlitchTip event ingestion. Keep the old cluster and its volumes intact for
seven days.

## 6. Remove the old production worker pools

After the shared deployment has remained healthy, change the production Flux
path to:

```yaml
path: ./infra/k8s/clusters/profiles/compact-production
```

The final profile retains `md-combined` and removes `md-app` and
`md-stateful`. Watch every drain and confirm both PostgreSQL replicas remain
healthy before allowing the next worker to disappear.

The production control-plane server is not resized by this profile. Its
address is the cluster bootstrap endpoint, so replacing it without first
introducing a stable private endpoint could prevent replacement nodes from
joining.

## 7. Retire the observability cluster

After the seven-day rollback window:

1. Remove the `workload-cluster-observability` Flux reconciliation object so it
   cannot recreate the cluster.
2. Take one final database backup and object comparison.
3. Delete the `glossia-observability` Cluster resource from the management
   cluster.
4. Verify the exact detached volumes in the Hetzner Console before deleting
   the four 100-gibibyte Ceph volumes.
5. Rebuild the management server on CX23 only after its etcd backup has been
   restored successfully in a rehearsal.

## Rollback

Before the old observability cluster is retired, rollback consists of deleting
the new ingresses, restoring the old ingresses, setting
`observability_on_production=false`, and reconciling the infrastructure
workflow. If new telemetry has been written only to Hetzner Object Storage, the
old observability services can read the same buckets after their object-storage
overlay is restored.

Do not switch object writers back to Ceph without first synchronizing the
Hetzner objects as described in the object-storage runbook.

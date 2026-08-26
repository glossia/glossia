# Node rollout runbook

Draining or replacing worker nodes on the production cluster (a machine-type
change, a Kubernetes upgrade, a size change, CAPI remediation) evicts pods,
and several stateful workloads have PodDisruptionBudgets that can block those
evictions. This runbook lists the pre-flight checks and the per-workload steps
that keep a rollout from stalling. Skipping them once froze the production
rollout for over a day.

The ClusterClass now sets `deletion.nodeDrainTimeoutSeconds: 600`
(`infra/k8s/clusters/clusterclass-glossia.yaml`), so a blocked drain degrades
and self-heals in ten minutes instead of hanging forever. The steps
below avoid the ten-minute stall (and the disruption it causes) entirely.

## 0. Pre-flight

Confirm the target machine type is actually purchasable before changing any
`hcloudWorkerMachineType`. The `cx` line is frequently out of stock in fsn1;
targeting an unavailable type makes CAPI drain healthy nodes to replace them
with machines it can never create.

```
HCLOUD_TOKEN=<token> hcloud datacenter describe fsn1-dc14 \
  | sed -n '/Available/,/Supported/p'
```

List every PodDisruptionBudget and look for `ALLOWED DISRUPTIONS = 0`. Each of
those blocks the drain of whatever node holds its pod.

```
kubectl get pdb -A -o wide
```

## 1. CloudNativePG Postgres (glossia-postgres, glitchtip-postgres)

CNPG generates a `<cluster>-primary` PDB with `minAvailable: 1` selecting the
primary, so draining the primary's node always blocks. Put each Postgres
cluster into maintenance for the rollout, which relaxes the PDB and lets CNPG
move instances:

```
kubectl cnpg maintenance set --reusePVC -A            # needs the cnpg plugin
# or, declaratively on each Cluster:
kubectl patch cluster.postgresql.cnpg.io glossia-postgres -n glossia --type merge \
  -p '{"spec":{"nodeMaintenanceWindow":{"inProgress":true,"reusePVC":true}}}'
```

Unset it after the rollout:

```
kubectl cnpg maintenance unset -A
# or set nodeMaintenanceWindow.inProgress back to false
```

Note: raising `instances` from 2 to 3 does NOT remove the block. At any
instance count the primary PDB is `minAvailable: 1` over one primary, so it is
always zero-disruption. Maintenance mode is the supported path.

## 2. ClickHouse Keeper (glossia-keeper)

`glossia-keeper` runs one replica with an operator-generated PDB of
`maxUnavailable: 0`, so its pod is unevictable. Until Keeper runs three
replicas (see `deploy/helm/glossia/values.yaml: keeperReplicas`), move its pod
off the draining node by hand; the StatefulSet reschedules it and ClickHouse
reconnects:

```
kubectl delete pod glossia-keeper-keeper-0-0 -n glossia
```

A direct `delete pod` bypasses the eviction API and therefore the PDB, which
is safe here because the pod is rescheduled immediately onto another node.

## 3. Single-replica app workloads

Any Deployment with one replica behind a `minAvailable: 1` PDB is unevictable.
The glossia app is guarded at the chart level (its PDB only renders when
`replicaCount > 1`), but third-party workloads deployed from other repos are
not. Before draining, scale any such workload to two replicas, or delete its
pod directly if a brief single-pod gap is acceptable.

## 4. If a machine is stuck deleting

CAPI keeps failed MachineSets around. If a rollout stalls, a MachineSet
pinned to an unavailable type may be holding a replica slot its machine can
never fill. Scale that MachineSet to zero to free the slot:

```
kubectl get machineset -n org-glossia
kubectl scale machineset <stuck-set> -n org-glossia --replicas=0
```

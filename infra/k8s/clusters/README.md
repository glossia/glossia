# Glossia ClusterClass + Cluster CRs

Self-hosted Kubernetes manifests for the Glossia workload clusters,
reconciled by our own management cluster running CAPI + caph
(`cluster-api-provider-hetzner`).

## Why a ClusterClass

ClusterClass is CAPI's native templating layer. We author one
`ClusterClass` (`glossia-hcloud`) that defines the reusable shape — HA
control plane, worker-pool variables, network config,
`KubeadmControlPlaneTemplate`, `HCloudMachineTemplate` — and per-cluster
`Cluster` CRs reference it via `topology.classRef.name`, only specifying
what differs (replica counts, machine types per pool, labels). Adding
a new (e.g. per-tenant) cluster is a `cp cluster-<env>.yaml
cluster-<tenant>.yaml` plus a name change. Kubernetes minor bumps are a
`topology.version:` edit on each Cluster CR.

## Layout

```
clusters/
├── README.md                   this file
├── clusterclass-glossia.yaml   the glossia-hcloud ClusterClass
└── cluster-production.yaml     per-cluster Cluster CRs in topology mode
```

## Variables exposed by the ClusterClass

- `region` (required) — Hetzner location (`fsn1`, `nbg1`, `hel1`, `ash`, `hil`).
- `hcloudControlPlaneMachineType` / `hcloudWorkerMachineType` (required) — server type per pool.
- `hcloudControlPlaneMachineImageName` / `hcloudWorkerMachineImageName` (default `ubuntu-24.04`).
- `hcloudSSHKeyName` (required) — SSH keys to embed on every node.
- `clusterEndpointHost` / `clusterEndpointPort` / `clusterLoadBalancerType` — optional kube-apiserver LB config.
- `clusterLoadBalancerExtraServices` — extra ports forwarded by the apiserver LB.
- `hcloudPlacementGroups` — optional placement groups; default `[]`.
- `hcloudNetwork` — optional Hetzner Cloud Network attachment; default disabled.
- `hcloudControlPlanePlacementGroupName` / `hcloudWorkerMachinePlacementGroupName` — optional per-pool placement-group pinning.

For per-pool overrides (e.g. a stateful pool that wants a different
machine type from `md-0`), set `variables.overrides` on the
`MachineDeployment` entry — see the inline comments on
`cluster-production.yaml`.

## Image strategy

Hetzner-published Ubuntu images plus cloud-init that installs
containerd + runc + kubelet at first boot (~2–3 min cold start). Simple
to reason about; no Packer pipeline. If scaling latency becomes
painful, a pre-baked image can be introduced without changing the
ClusterClass shape.

## Adapting from caph upstream

`clusterclass-glossia.yaml` was forked from caph's `cluster-class.yaml`
release asset. To diff against a new caph release:

```bash
gh release download <tag> --repo syself/cluster-api-provider-hetzner \
  --pattern 'cluster-class*.yaml' --pattern 'cluster-template-hcloud*.yaml'
```

Adaptations to be aware of when porting upstream changes:

- Bare-metal `MachineDeployment` class + bare-metal templates dropped (we only run cloud servers).
- All five resources scoped to the `org-glossia` namespace (otherwise `topology.classRef` lookup fails because Cluster CRs live in `org-glossia`).
- `initConfiguration.skipPhases: [addon/kube-proxy]` on the KCP because Cilium replaces kube-proxy.
- `hcloudPlacementGroups` variable defaults to `[]` (otherwise the patch errors at render time).
- `hcloudControlPlanePlacementGroupName` / `hcloudWorkerMachinePlacementGroupName` patches split into separate `enabledIf` definitions: caph rejects empty-string `placementGroupName` with "Placement group does not exist", so we only emit the patch when the variable is non-empty.
- `KUBERNETES_VERSION` and `CONTAINERD` in `preKubeadmCommands` ported from the flat `cluster-template-hcloud.yaml`. The reference ClusterClass uses an old `cri-containerd-cni-` bundle that's no longer published for containerd 2.x.
- `containerd.service` systemd unit added to both KCP and worker `files:` blocks. The plain `containerd-` tarball doesn't ship one (only the older `cri-containerd-cni-` bundle did). Without this, `systemctl start containerd` finds no unit and PLEG never goes healthy.
- `containerRuntimeEndpoint`, `staticPodPath`, `cgroupDriver`, `clusterDNS`, `clusterDomain`, **`authentication.x509.clientCAFile`** added to the kubelet `KubeletConfiguration` shipped via the `files:` block. Critical: kubelet is invoked with two `--config` flags (kubeadm's default + ours via `kubeletExtraArgs`) and the second OVERRIDES the first, so any field omitted here gets cleared. Without `clientCAFile`, kubelet rejects the kube-apiserver's client cert as Unauthorized → `kubectl exec`, `kubectl port-forward`, and KCP's etcd health check all fail; KCP then refuses to scale the control plane to 3 replicas.
- `resolvConf` set to `/run/systemd/resolve/resolv.conf` (not `/etc/resolv.conf`, which is a stub at 127.0.0.53 unreachable across pod network namespaces). Without this CoreDNS upstream resolution AND any pod with `dnsPolicy=Default` fails to resolve external names — in particular HCCM crashes on startup trying to resolve `api.hetzner.cloud`.

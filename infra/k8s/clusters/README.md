# Glossia ClusterClass and workload Cluster resources

Self-hosted Kubernetes manifests for the Glossia workload clusters,
reconciled by our own management cluster running
[Cluster Application Programming Interface](https://cluster-api.sigs.k8s.io/)
and
[Cluster Application Programming Interface Provider Hetzner](https://github.com/syself/cluster-api-provider-hetzner).

## Why a ClusterClass

ClusterClass is the native templating layer from
[Cluster Application Programming Interface](https://cluster-api.sigs.k8s.io/).
We author one `ClusterClass` (`glossia-hcloud`) that defines the
reusable shape: highly available control plane, worker-pool variables,
network config, `KubeadmControlPlaneTemplate`, and
`HCloudMachineTemplate`. Per-cluster `Cluster` resources reference it
via `topology.classRef.name`, only specifying what differs, such as
replica counts, machine types per pool, and labels. Adding a new
cluster means copying one workload directory, changing
`metadata.name`, and adding a matching Flux `Kustomization`.
Kubernetes minor bumps are a `topology.version:` edit on each
`Cluster` resource.

## Layout

```
clusters/
├── README.md                         this file
├── clusterclass-glossia.yaml         the glossia-hcloud ClusterClass
└── workloads/
    ├── observability/
    │   ├── cluster.yaml              glossia-observability Cluster resource
    │   └── kustomization.yaml
    └── production/
        ├── cluster.yaml              glossia-production Cluster resource
        └── kustomization.yaml
```

## Reconciliation

[Flux](https://fluxcd.io/) reconciles each workload directory through
the resources in [`../mgmt/flux`](../mgmt/flux). The
`ClusterClass` remains outside Flux because template fields are often
immutable and still need the explicit management-cluster apply path in
the onboarding runbook.

The Flux `Kustomization` objects use `prune: false` and
`deletionPolicy: Orphan`, so removing a file from git cannot tear down
live infrastructure by accident. Intentional cluster removal stays a
separate break-glass operation.

The `profiles/` directory contains staged production topology changes. The
consolidation profile adds three combined CX53 workers without removing the
current pools. The compact profile retains those workers and removes the old
pools after observability has moved. Follow
[`../cluster-consolidation.md`](../cluster-consolidation.md); never switch
directly from the base topology to the compact profile.

## Variables exposed by the ClusterClass

- `region` (required) — Hetzner location (`fsn1`, `nbg1`, `hel1`, `ash`, `hil`).
- `hcloudControlPlaneMachineType` / `hcloudWorkerMachineType` (required) — server type per pool.
- `hcloudControlPlaneMachineImageName` / `hcloudWorkerMachineImageName` (default `ubuntu-24.04`).
- `hcloudSSHKeyName` (required) — SSH keys to embed on every node.
- `clusterEndpointHost` / `clusterEndpointPort` / `clusterLoadBalancerType` — optional Kubernetes control-plane load balancer config.
- `clusterLoadBalancerEnabled` — controls whether fresh clusters create a provider-managed Kubernetes control-plane load balancer. Hetzner marks this field immutable after the cluster infrastructure object is created. Existing clusters must keep their original value, move `spec.controlPlaneEndpoint` plus the in-cluster discovery data to the firewalled control-plane server, and verify Tailscale access. Deleting a provider-managed load balancer while this value remains enabled makes the provider recreate it or report the infrastructure as unavailable.
- `clusterLoadBalancerExtraServices` — extra ports forwarded by the Kubernetes control-plane load balancer.
- `hcloudPlacementGroups` — optional placement groups; default `[]`.
- `hcloudNetwork` — optional Hetzner Cloud Network attachment; default disabled.
- `hcloudControlPlanePlacementGroupName` / `hcloudWorkerMachinePlacementGroupName` — optional per-pool placement-group pinning.

For per-pool overrides (e.g. a stateful pool that wants a different
machine type from `md-0`), set `variables.overrides` on the
`MachineDeployment` entry — see the inline comments on
`workloads/production/cluster.yaml`.

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
- All five resources scoped to the `org-glossia` namespace (otherwise `topology.classRef` lookup fails because `Cluster` resources live in `org-glossia`).
- `initConfiguration.skipPhases: [addon/kube-proxy]` on the KCP because Cilium replaces kube-proxy.
- `hcloudPlacementGroups` variable defaults to `[]` (otherwise the patch errors at render time).
- `hcloudControlPlanePlacementGroupName` / `hcloudWorkerMachinePlacementGroupName` patches split into separate `enabledIf` definitions: caph rejects empty-string `placementGroupName` with "Placement group does not exist", so we only emit the patch when the variable is non-empty.
- `KUBERNETES_VERSION` and `CONTAINERD` in `preKubeadmCommands` ported from the flat `cluster-template-hcloud.yaml`. The reference ClusterClass uses an old `cri-containerd-cni-` bundle that's no longer published for containerd 2.x.
- `containerd.service` systemd unit added to both KCP and worker `files:` blocks. The plain `containerd-` tarball doesn't ship one (only the older `cri-containerd-cni-` bundle did). Without this, `systemctl start containerd` finds no unit and PLEG never goes healthy.
- `containerRuntimeEndpoint`, `staticPodPath`, `cgroupDriver`, `clusterDNS`, `clusterDomain`, **`authentication.x509.clientCAFile`** added to the kubelet `KubeletConfiguration` shipped via the `files:` block. Critical: kubelet is invoked with two `--config` flags (kubeadm's default + ours via `kubeletExtraArgs`) and the second OVERRIDES the first, so any field omitted here gets cleared. Without `clientCAFile`, kubelet rejects the kube-apiserver's client cert as Unauthorized → `kubectl exec`, `kubectl port-forward`, and KCP's etcd health check all fail; KCP then refuses to scale the control plane to 3 replicas.
- `resolvConf` set to `/run/systemd/resolve/resolv.conf` (not `/etc/resolv.conf`, which is a stub at 127.0.0.53 unreachable across pod network namespaces). Without this CoreDNS upstream resolution AND any pod with `dnsPolicy=Default` fails to resolve external names — in particular HCCM crashes on startup trying to resolve `api.hetzner.cloud`.

## Staged security maintenance (November 2026)

These are **prepared targets, not evidence of a completed upgrade**. Do not
merge this patch set as one unattended rollout: Flux watches `main`, and
application changes can publish images that image automation deploys. Obtain
separate approval for deployment, then release the phases below independently.
No existing-node maintenance is performed by editing the onboarding examples.

### Preconditions and order

1. Restore authenticated access to production through the approved Tailscale
   path. The audit could read management but could not reach production;
   do not open its public API firewall as an upgrade workaround. Record live
   node, Cilium, ingress, Grafana and database versions before proceeding.
2. Verify recoverable management etcd and application database backups, access
   to Talos recovery credentials, and the current endpoint/firewall plan.
   Management and workload topologies have single control planes: schedule
   their API outages explicitly and never replace them simultaneously.
3. Contain ingress admission and update the platform chart independently.
   Chart 4.15.1 ships controller 1.15.1; admission webhooks are disabled as
   temporary containment. This removes admission validation, not ingress
   routing. Verify the old webhook registration, admission Service/listener
   and certificate-patch Jobs are gone after the approved Helm upgrade.
   ingress-nginx is retired; this is a bridge to a supported ingress, not a
   long-term supported destination.
4. Rebuild the application with the patched OTP/Debian base and reviewed Hex
   lock. Run both editions' checks, scan the resulting immutable images, then
   authorize application rollout separately from cluster maintenance. The
   prepared dependencies do **not** resolve every Hex advisory; see below.
5. Upgrade management Talos to **1.13.12**, preserving the installed schematic
   and extensions. Take an etcd snapshot first and verify API/Flux/Cluster API
   recovery afterwards. This updates containerd to **2.2.10**, but does not
   upgrade Kubernetes. Upgrade management Kubernetes separately, one minor at
   a time, to **1.35.10** after checking Talos/provider support.
6. Refresh Flux to **2.9.5** using the generated components. Its public webhook
   policy permits only port **9292**, not the internal event port. Management
   uses Flannel; verify a policy-enforcement engine is installed and test
   isolation from another namespace. A NetworkPolicy object alone is not
   proof of enforcement. Update the Tailscale proxy to **1.104.5** in a
   separate step, retaining another working administrative access path.
7. Upgrade Cilium to **1.19.9** before the workload Kubernetes upgrade. The
   [1.19 support matrix](https://docs.cilium.io/en/v1.19/network/kubernetes/compatibility/)
   includes both Kubernetes **1.34** and **1.35**; rehearse the Cilium minor
   upgrade with the actual installed configuration first. Preserve live
   endpoint, IPAM, encryption and routing values, including the firewalled
   API port **6443** after endpoint cutover; do not replay a fresh-bootstrap
   command against an existing cluster. Render first; then check Cilium,
   Envoy, DNS, network policies, external ingress and storage connectivity.
8. Apply the ClusterClass change through its explicit maintenance path before
   releasing either Cluster topology change. Kubeadm bootstrap templates can
   be immutable: use new template names and update their references where
   required, rather than deleting resources used by live Machines. All three
   bootstrap paths target containerd **2.2.10**, runc **1.3.6**, and Kubernetes
   **1.35.10**. A bootstrap edit is not an in-place runtime update. Upgrade
   control planes first and roll worker pools individually, respecting Pod
   disruption budgets, database quorum, local volumes and spare capacity.
   Release autoscaler **1.35.2** with the workload minor upgrade. Confirm
   every replacement's live runtime and current Ubuntu security kernel;
   drain/reboot retained nodes separately if they were not replaced.
9. Upgrade Grafana to **12.4.14** only after backing up its persistent database
   and checking plugins and intermediate-major migration notes against the
   live version. An image rollback is not a database-migration rollback.
   Production PostgreSQL versions were not verified; select a patched image
   on each database's **existing major**, rather than forcing an unverified
   major upgrade through the application chart's operator-selected default.

### Unresolved application advisory gates

The Hex registry audit remains nonzero; do not describe these patches as a
clean security scan or deploy them on that assumption.

- **Boruta 2.3.5:** JWT assertion-expiry, dynamic-registration and remote-key
  fetching advisories remain. Tested resolution to 2.3.8 requires Nebulex 3,
  while its `Boruta.Cache` still references `Nebulex.Adapters.Replicated`,
  removed from that package. The lock retains Nebulex 2 and Boruta 2.3.5 rather
  than shipping a known boot-breaking update. A compatible upstream fix or
  narrowly reviewed backport and OAuth regression tests are required.
- **Hackney 1.25.0:** the consolidated fix is 4.9.0 or newer, but UAInspector,
  ExAws and Swoosh currently constrain it to 1.x. Custom-CA pinning and SOCKS5
  timeout paths need deployment-configuration review; no application-owned
  custom Hackney CA/SOCKS configuration was found. Do not force a major
  override across these consumers. Normal public-root TLS is not CA pinning.
- **Ecto/Decimal:** closing the query-cache and numeric-allocation advisories
  requires the coordinated Ecto 3.14 / ClickHouse adapter / Decimal 3 upgrade;
  the locked ClickHouse adapter restricts Ecto to 3.13. No affected dynamic
  JSON-path or Ecto splice query was found in application source. This is a
  remaining review item, not a blanket exploitability exclusion.
- Cloak AES-CTR and Cloak.Ecto PBKDF2 advisories require those ciphers/types;
  the vault uses AES-GCM. Swoosh's flagged Graph adapter is not the configured
  production mail adapter. Retain these qualifications instead of suppressing
  the registry audit globally.

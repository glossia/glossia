# Management-cluster Flux sync

This directory is the root passed to `flux bootstrap github` for the
management cluster:

```bash
mise exec -- flux bootstrap github \
  --owner=glossia \
  --repository=glossia \
  --branch=main \
  --path=infra/k8s/mgmt/flux
```

Flux creates and maintains its own generated manifests in the nested
`flux-system/` directory. The sibling YAML files in this directory
declare the management-cluster resources that Flux should also keep in
sync.

Do not add a root `kustomization.yaml` here unless it includes both the
generated `flux-system/` directory and every sibling manifest. With no
root Kustomize file, Flux applies the plain manifests under this path
and still lets its generated `flux-system/kustomization.yaml` manage the
controller installation.

The workload cluster reconciler deliberately watches only
`infra/k8s/clusters/workloads/*`. The shared `ClusterClass` remains on
the explicit apply path in the onboarding runbook because its templates
contain immutable fields.

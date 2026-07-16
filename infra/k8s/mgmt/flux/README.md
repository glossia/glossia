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

Flux's generated controller and sync manifests are checked in under the
nested `flux-system/` directory before bootstrap. This lets the bootstrap
command install the reviewed version without adding a direct commit to
`main`. The sibling YAML files in this directory declare the
management-cluster resources that Flux should also keep in sync.

The source uses the existing Glossia GitHub App through
[Flux GitHub provider authentication](https://fluxcd.io/flux/components/source/gitrepositories/#github).
Keep `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_OWNER`, and
`GITHUB_APP_PRIVATE_KEY` in the production Infisical project under
`/flux-system`. The Infra workflow restores the `flux-system` Secret before
asking Flux to reconcile, so accidental Secret deletion does not permanently
stop repository reconciliation.

Do not add a root `kustomization.yaml` here unless it includes both the
generated `flux-system/` directory and every sibling manifest. With no
root Kustomize file, Flux applies the plain manifests under this path
and still lets its generated `flux-system/kustomization.yaml` manage the
controller installation.

The workload cluster reconciler deliberately watches only
`infra/k8s/clusters/workloads/*`. The shared `ClusterClass` remains on
the explicit apply path in the onboarding runbook because its templates
contain immutable fields.

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

## Production release flow

The `App` workflow validates application changes on `main`. After it succeeds,
the `Publish Production Image` workflow builds the same revision and publishes
the immutable revision tag, the mutable `main` tag, and a traceable run tag to
the [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).
The publishing runner does not connect to a workload cluster.

Flux reads the private image repository with the `ghcr-glossia` Secret. The
Infra workflow restores that Secret from `GHCR_PULL_USERNAME` and
`GHCR_PULL_TOKEN` in the production Infisical project under `/kubernetes`.
This keeps the credential out of Git without requiring the management cluster
to run the External Secrets Operator. The image policy watches the `main` tag,
and image automation commits its new digest into
`infra/k8s/workload-apps/glossia-production`. The workload platform and
application Kustomizations then reconcile remote `HelmRelease` resources
through `glossia-production-kubeconfig` in the `org-glossia` namespace.

The GitHub App behind the `flux-system` source must have permission to read and
write repository contents so
[Flux image automation](https://fluxcd.io/flux/components/image/imageupdateautomations/)
can push the digest commit to `main`.

# Migrate object storage to Hetzner

This runbook moves the application files, command-line releases, metrics, logs,
and traces from the two self-hosted Ceph clusters to
[Hetzner Object Storage](https://docs.hetzner.com/storage/object-storage/overview/).
It keeps database backups in Cloudflare R2 so a Hetzner account incident cannot
remove both the primary data and every backup.

The migration is deliberately split from Ceph deletion. Do not delete a Ceph
cluster until its consumers have used Hetzner successfully for at least seven
days and a final comparison has passed.

## Expected cost reduction

The July 2026 invoice has 700 gibibytes of Ceph backing volumes at €0.0572 per
gibibyte-month, or €40.04 per month. Hetzner Object Storage has one account-wide
base charge, regardless of the number of buckets. The current base charge is
€6.49 per month and includes up to one terabyte of storage and roughly one
terabyte of outgoing traffic. Internal traffic in Hetzner's `eu-central`
network zone and object operations are free.

| State | Monthly bill | Reduction |
|---|---:|---:|
| Current | €455.63 | €0.00 |
| Production Ceph removed, observability Ceph retained for block volumes | €444.96 | €10.67 |
| Both Ceph clusters removed after block-volume migration | €422.08 | €33.55 |

The second saving requires moving Grafana and GlitchTip PostgreSQL block
volumes off Ceph. Moving only the object data does not make the observability
Ceph volumes removable.

The object-storage change also releases memory and processor capacity. The
separate [cluster consolidation runbook](cluster-consolidation.md) replaces
the duplicated worker pools with three combined CX53 workers and moves the
undersized observability deployment into production. Together, the storage
and cluster changes reduce the expected steady-state bill to €167.68 per
month.

## 1. Create buckets and keys

Create these buckets in Falkenstein through the
[Hetzner Console](https://console.hetzner.com/):

| Bucket | Visibility | Credential set |
|---|---|---|
| `glossia-ai-production` | Private | application |
| `glossia-ai-releases` | Public | releases |
| `glossia-ai-mimir` | Private | observability |
| `glossia-ai-loki` | Private | observability |
| `glossia-ai-tempo` | Private | observability |

Bucket names are globally unique in Hetzner. If one is unavailable, update the
matching values overlay and this runbook before copying data.

Create three key pairs and restrict each one with bucket policies:

- The application key can access only `glossia-ai-production`.
- The release key can write only `glossia-ai-releases`. Public access grants
  anonymous object downloads but not object listing.
- The observability key can access only the three observability buckets.

Hetzner keys are project-wide unless bucket policies restrict them. Follow
[Hetzner's key restriction guide](https://docs.hetzner.com/storage/object-storage/faq/s3-credentials/)
and store the generated values immediately because the secret key cannot be
viewed again.

Store the key pairs in Infisical:

```bash
infisical secrets set \
  ACCESS_KEY_ID='<application access key>' \
  SECRET_ACCESS_KEY='<application secret key>' \
  --path /glossia-object-storage --env prod

infisical secrets set \
  AWS_ACCESS_KEY_ID='<release access key>' \
  AWS_SECRET_ACCESS_KEY='<release secret key>' \
  --path /glossia-releases-object-storage --env prod

```

The release fields retain their existing `AWS_` names because the release
workflow reads them directly. Keep the destination credentials in the
separate `/glossia-releases-object-storage` path during the copy so the
existing `/glossia-releases` path continues to authenticate against Ceph.

The observability secrets live in the separate `glossia-observability`
Infisical project. Select that project in the Infisical command-line client or
Console, then create `/observability/object-storage` with `ACCESS_KEY_ID` and
`SECRET_ACCESS_KEY` there.

Do not replace the `/glossia-releases` credentials or endpoint fields until
the release bucket has been copied and verified.

## 2. Project destination credentials into Kubernetes

Render and apply only the destination ExternalSecret resources before copying.
This does not change any workload endpoint.

With `KUBECONFIG` pointing at production:

```bash
helm dependency update deploy/helm/glossia
helm template glossia deploy/helm/glossia \
  --namespace glossia \
  --values deploy/values-production.yaml \
  --values deploy/values-object-storage-hetzner.yaml \
  --show-only templates/external-secrets/object-storage.yaml \
  | kubectl apply -f -

helm dependency update infra/helm/platform
helm template platform infra/helm/platform \
  --namespace platform \
  --values infra/helm/platform/values-hetzner.yaml \
  --values infra/helm/platform/values-object-storage-hetzner.yaml \
  --show-only templates/external-object-storage-release-secret.yaml \
  | kubectl apply -f -

kubectl -n glossia wait \
  --for=condition=Ready externalsecret/glossia-object-storage \
  --timeout=2m
kubectl -n platform wait \
  --for=condition=Ready externalsecret/glossia-releases-object-storage \
  --timeout=2m
```

With `KUBECONFIG` pointing at observability:

```bash
helm dependency update infra/helm/observability
helm template observability infra/helm/observability \
  --namespace observability \
  --values infra/helm/observability/values-hetzner.yaml \
  --values infra/helm/observability/values-object-storage-hetzner.yaml \
  --show-only templates/external-secrets/object-storage.yaml \
  | kubectl apply -f -

kubectl -n observability wait \
  --for=condition=Ready externalsecret/glossia-observability-object-storage \
  --timeout=2m
```

## 3. Install the migration tool

The repository pins [rclone](https://rclone.org/) through mise:

```bash
mise install rclone
```

The migration script reads both credential sets from Kubernetes without
printing either. It opens a temporary port forward to the current cluster's
Ceph gateway.

## 4. Make initial copies

Point `KUBECONFIG` at the production cluster and copy its two buckets:

```bash
mise exec -- infra/k8s/migrate-object-storage.sh production-app copy
mise exec -- infra/k8s/migrate-object-storage.sh production-releases copy
```

Point `KUBECONFIG` at the observability cluster and copy its three buckets:

```bash
mise exec -- infra/k8s/migrate-object-storage.sh observability-mimir copy
mise exec -- infra/k8s/migrate-object-storage.sh observability-loki copy
mise exec -- infra/k8s/migrate-object-storage.sh observability-tempo copy
```

Each copy ends with a one-way comparison of every source object by path and
size. Content hashes are not used because multipart object hashes are not
portable between Ceph and Hetzner.

## 5. Cut over production

Schedule a short maintenance window. Stop the application so no object changes
can occur during the final synchronization:

```bash
kubectl -n glossia scale deployment/glossia --replicas=0
mise exec -- infra/k8s/migrate-object-storage.sh \
  production-app sync glossia-ai-production
```

Apply the application overlay and wait for the deployment:

```bash
helm upgrade --install glossia deploy/helm/glossia \
  --namespace glossia \
  --values deploy/values-production.yaml \
  --values deploy/values-object-storage-hetzner.yaml
kubectl -n glossia rollout status deployment/glossia --timeout=10m
```

At the same time, change `production_object_storage` to `true` in
`infra/k8s/object-storage-migration-state` and commit it. The production
deployment workflow reads this flag and will keep applying both production
overlays on every later deployment. Without the flag, the next deployment
would intentionally return the application to Ceph.

For releases, first run the final synchronization while no release workflow is
active. Then copy the Hetzner access key and secret key into
`/glossia-releases` as `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, and set
these remaining fields on that path:

```text
RELEASE_ENDPOINT=https://fsn1.your-objectstorage.com
RELEASE_BUCKET=glossia-ai-releases
RELEASE_REGION=fsn1
RELEASE_PREFIX=cli
```

Apply the public proxy overlay:

```bash
mise exec -- infra/k8s/migrate-object-storage.sh \
  production-releases sync glossia-ai-releases

helm upgrade --install platform infra/helm/platform \
  --namespace platform \
  --values infra/helm/platform/values-hetzner.yaml \
  --values infra/helm/platform/values-object-storage-hetzner.yaml

curl --fail --location \
  https://releases.glossia.ai/cli/versions.txt >/dev/null
```

Keep Ceph running during the verification window. After seven successful days,
change `production_ceph_removed` to `true` in the migration state file and
commit it. The production workflow then applies
`infra/helm/platform/values-remove-ceph.yaml` together with both platform
overlays. Remove only the three 100-gibibyte Ceph volumes after confirming the
Ceph resources are gone.

## 6. Cut over observability

The final synchronization needs a maintenance window because compactors can
replace objects while data is being copied. Record replica counts, pause the
Mimir, Loki, and Tempo writers, allow their graceful shutdown to finish, and
run the three final synchronizations. Then deploy with the additional overlay:

```bash
helm upgrade --install observability infra/helm/observability \
  --namespace observability \
  --values infra/helm/observability/values-hetzner.yaml \
  --values infra/helm/observability/values-object-storage-hetzner.yaml \
  --timeout 30m
```

Verify recent and historical metrics, logs, and traces in Grafana. Keep the
Ceph cluster because Grafana, GlitchTip PostgreSQL, and write-ahead log volumes
still use its block storage. Their migration to direct Hetzner volumes is a
separate operation with separate backups and rollback steps.

Change `observability_object_storage` to `true` in
`infra/k8s/object-storage-migration-state` and commit it with the cutover. The
infrastructure workflow will keep applying the observability overlay on later
deployments.

If the observability cluster is being consolidated into production, stop here
with Ceph intact and continue with `infra/k8s/cluster-consolidation.md`. That
runbook restores Grafana and GlitchTip PostgreSQL onto direct Hetzner volumes
in the production cluster before it enables `observability_ceph_removed` and
`observability_on_production`.

## 7. Roll back

Do not write new data to both destinations during rollback. Stop the affected
writers, copy the Hetzner bucket back to Ceph with the source and destination
roles reversed, remove the Hetzner values overlay, and restart the workloads.
Because Ceph remains intact for at least seven days, a configuration-only
rollback is possible before any new Hetzner-only writes occur.

Reset the matching migration-state flag to `false` during a rollback so future
deployment workflows do not reapply the Hetzner overlay.

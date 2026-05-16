# Glossia Helm chart

Self-installable Helm chart for [Glossia](https://glossia.ai). Bundles the
web app, a Postgres cluster (CloudNativePG), and a ClickHouse cluster
(Altinity Operator) in one release. Each datastore can be disabled if you
prefer to bring your own.

## Prerequisites

The chart consumes operators rather than installing them. Your cluster
needs whichever of these match the components you enable:

| When you enable… | Install in the cluster first |
|---|---|
| `postgres.enabled` (default `true`) | [CloudNativePG operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) |
| `clickhouse.enabled` (default `true`) | [ClickHouse Kubernetes operator](https://github.com/ClickHouse/clickhouse-operator) — the **official** `clickhouse.com/v1alpha1` operator (`ClickHouseCluster` + `KeeperCluster`), distinct from Altinity's `clickhouse.altinity.com` one |
| `ingress.enabled` | An ingress controller matching `ingress.className` (e.g. `ingress-nginx`) |
| `ingress.tls` with cert-manager annotation | [cert-manager](https://cert-manager.io/) + a `ClusterIssuer` you reference |
| `externalSecrets.enabled` | [External Secrets Operator](https://external-secrets.io/) + a `SecretStore` / `ClusterSecretStore` you reference |
| `backups.enabled` + `backups.postgres.enabled` | [CNPG Barman Cloud plugin](https://cloudnative-pg.io/plugin-barman-cloud/) installed cluster-wide |
| `backups.enabled` (either DB) | A reachable, **dedicated** S3-compatible bucket + credentials |

## Install

```bash
helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=v1.2.3 \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

You will also need a Secret named `glossia-app-env` (key `secrets.envSecretName`)
with at minimum:

| Key | Purpose |
|---|---|
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix session signing key |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer token guarding `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth for `/ops` dashboards |
| `GLOSSIA_SMTP_*` | Outbound email |

…and (when `postgres.enabled`) a basic-auth Secret named `glossia-postgres-app`
with `username` + `password` keys for the application Postgres user.

Provision both manually, with sealed-secrets, sops, or any other tooling —
or let the chart create them from your secret backend by enabling the
External Secrets integration below.

## External Secrets Operator

When `externalSecrets.enabled=true` the chart emits `ExternalSecret` CRs
that pull from the configured store. For example, against a 1Password
`ClusterSecretStore` named `onepassword`:

```yaml
externalSecrets:
  enabled: true
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword
  appEnv:
    itemKey: glossia                # 1Password item title
    fields:
      GLOSSIA_SECRET_KEY_BASE: SECRET_KEY_BASE
      GLOSSIA_METRICS_BEARER_TOKEN: METRICS_BEARER_TOKEN
      # … one entry per field you want surfaced in glossia-app-env
  postgres:
    itemKey: glossia
    passwordField: POSTGRES_PASSWORD
  imagePullSecret:
    enabled: true                   # only needed for private registries
    name: ghcr-pull-secret
    registry: ghcr.io
    itemKey: glossia
    usernameField: GHCR_PULL_USERNAME
    passwordField: GHCR_PULL_TOKEN
```

`GLOSSIA_DATABASE_URL` and `GLOSSIA_CLICKHOUSE_URL` are computed from
`postgres.*` / `clickhouse.*` and the password fetched from the postgres
item — you do not list them in `appEnv.fields`.

## BYO Postgres / ClickHouse

Set `postgres.enabled=false` (or `clickhouse.enabled=false`) and point the
app at your existing instance:

```yaml
postgres:
  enabled: false
  host: pg.internal.example.com:5432
  database: glossia_prod
  user: glossia
  appSecretName: glossia-postgres-app   # provision this yourself
clickhouse:
  enabled: false
  host: clickhouse.internal.example.com
  port: 8123
  database: glossia
```

## Backups

`backups.enabled` turns on off-cluster backups for the bundled databases,
to a **dedicated** S3-compatible bucket. Keep that bucket and its
credentials separate from the app's own object storage — a compromise or
fat-fingered lifecycle policy on one should not be able to destroy the
backups of the other.

```yaml
backups:
  enabled: true
  s3:
    bucket: my-glossia-db-backups
    prefix: glossia
    endpointURL: https://s3.eu-central-1.example.com   # blank → AWS
    region: eu-central-1
  secretName: glossia-db-backup   # keys: ACCESS_KEY_ID, SECRET_ACCESS_KEY
  postgres:
    schedule: "0 0 3 * * *"       # CNPG cron — SIX fields (secs first)
    retentionPolicy: "30d"
  clickhouse:
    schedule: "30 3 * * *"        # standard five-field K8s cron
    keepRemote: 30
```

- **Postgres** uses the CNPG **Barman Cloud plugin** (install it
  cluster-wide; see prerequisites). The chart emits an `ObjectStore` and
  a `ScheduledBackup`, and adds the plugin to the `Cluster`'s
  `spec.plugins` as the WAL archiver — so you get base backups *and*
  continuous WAL archiving (PITR), not just snapshots.
- **ClickHouse** has no native backup, so the chart runs a
  `clickhouse-backup` `CronJob` (`create_remote`, retained via
  `BACKUPS_TO_KEEP_REMOTE`).

Provide `backups.secretName` yourself (keys `ACCESS_KEY_ID`,
`SECRET_ACCESS_KEY`), or let the External Secrets integration create it
from a dedicated backend item:

```yaml
externalSecrets:
  enabled: true
  backup:
    itemKey: glossia-db-backups-keys   # a SEPARATE item from appEnv
    accessKeyIdField: access_key_id
    secretAccessKeyField: secret_access_key
```

## Upgrades

Schema migrations and ClickHouse database creation run as `pre-install` /
`pre-upgrade` Helm hooks (`helm.sh/hook-weight: -10` for ClickHouse init,
`0` for Ecto migrations). A failed migration aborts the upgrade — the
running pods keep serving the previous release until the next attempt.

## Values reference

See [`values.yaml`](values.yaml) for the full default set with inline
documentation.

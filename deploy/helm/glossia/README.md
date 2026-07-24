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
| `backups.enabled` (either database) | A reachable, **dedicated** [Amazon Simple Storage Service](https://aws.amazon.com/s3/)-compatible bucket and credentials |
| `objectStorage.enabled` | A reachable [Amazon Simple Storage Service](https://aws.amazon.com/s3/)-compatible bucket and a Secret containing its credentials |
| `objectStorage.rook.enabled` | A Rook and Ceph `ObjectBucketClaim` Secret with `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` |
| `smolanalytics.enabled` | A default storage class, or an explicit `smolanalytics.persistence.storageClass` |
| `hermes.enabled` | `smolanalytics.enabled=true`, a [Slack Socket Mode](https://api.slack.com/apis/connections/socket) application, a [Together](https://docs.together.ai/docs/quickstart) key, and a read-only [Grafana service account](https://grafana.com/docs/grafana/latest/administration/service-accounts/) token |

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
| `RELEASE_COOKIE` | Erlang distribution cookie shared by the parent pod and FLAME runners |
| `GLOSSIA_SMTP_*` | Outbound email, unless `mailRelay.enabled=true` supplies the relay settings |

…and (when `postgres.enabled`) a basic-auth Secret named `glossia-postgres-app`
with `username` + `password` keys for the application Postgres user.

Provision both manually, with sealed-secrets, sops, or any other tooling —
or let the chart create them from your secret backend by enabling the
External Secrets integration below.

## FLAME runners

Glossia uses [FLAME, Fleeting Lambda Application for Modular Execution](https://hexdocs.pm/flame/FLAME.html),
to start short-lived runner pods from the same release image as the parent
deployment. The parent pod starts a `FLAME.Pool`; when a runner boots, the
application detects it with `FLAME.Parent.get/0` and starts only the process
tree needed by runner work. There is no separate image or explicit mode flag.

The chart configures the parent pod with the service account, pod metadata, and
distributed Erlang settings that the [FLAME Kubernetes backend](https://hexdocs.pm/flame_k8s_backend/FLAMEK8sBackend.html)
requires. Runner pods inherit the parent image and pull secrets, but Glossia
does not mount the service account token in runner pods, scrubs application
secrets from the runner environment, and uses distinct labels so Glossia
services only route traffic to the parent pods.

Configure runner capacity and isolation under `flame`:

```yaml
flame:
  min: 0
  max: 10
  maxConcurrency: 1
  k8s:
    runtimeClassName: kata-qemu
    resources:
      requests:
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: "2"
        memory: 4Gi
```

`flame.k8s.runtimeClassName` is optional and should match the runtime class
installed in the cluster for [Kata Containers](https://katacontainers.io/). Set
`flame.serviceAccount.create=false` and `flame.rbac.create=false` only when you
provide an equivalent service account with pod management permissions in the
release namespace.

### Local end-to-end test

Run the lightweight [kind, Kubernetes in Docker](https://kind.sigs.k8s.io/)
chart test with [ShellSpec](https://shellspec.info/) before changing
runner-related templates:

```bash
bash deploy/helm/glossia/e2e/kind.sh
```

The runner creates one shared local cluster, runs the ShellSpec files under
`deploy/helm/glossia/e2e` in parallel, and gives each spec file its own
namespace and Helm release. The tests install the chart with `values-e2e.yaml`,
verify the FLAME runner permissions and service selectors, and then delete the
cluster.

## External Secrets Operator

When `externalSecrets.enabled=true` the chart emits `ExternalSecret` resources
that pull from the configured store. For example, against the Infisical
`ClusterSecretStore`:

```yaml
externalSecrets:
  enabled: true
  secretStoreRef:
    kind: ClusterSecretStore
    name: infisical
  appEnv:
    itemKey: /kubernetes            # Infisical folder path
    fields:
      GLOSSIA_SECRET_KEY_BASE: SECRET_KEY_BASE
      GLOSSIA_METRICS_BEARER_TOKEN: METRICS_BEARER_TOKEN
      # … one entry per field you want surfaced in glossia-app-env
  postgres:
    itemKey: /kubernetes
    passwordField: POSTGRES_PASSWORD
  imagePullSecret:
    enabled: true                   # only needed for private registries
    name: ghcr-pull-secret
    registry: ghcr.io
    itemKey: /kubernetes
    usernameField: GHCR_PULL_USERNAME
    passwordField: GHCR_PULL_TOKEN
```

`GLOSSIA_DATABASE_URL` and `GLOSSIA_CLICKHOUSE_URL` are computed from
`postgres.*` / `clickhouse.*` and the password fetched from the postgres
folder. You do not list them in `appEnv.fields`.

## Cluster Mail Relay

Set `mailRelay.enabled=true` when the cluster platform chart provides a
shared [Simple Mail Transfer Protocol](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol)
relay. The app pods submit mail to that in-cluster service without provider
credentials:

```yaml
mailRelay:
  enabled: true
  host: mail-relay.platform.svc.cluster.local
  port: 587
  tls: never
  auth: always
```

In this mode, remove `GLOSSIA_SMTP_HOST`, `GLOSSIA_SMTP_PORT`,
and the provider-backed `GLOSSIA_SMTP_USERNAME` and
`GLOSSIA_SMTP_PASSWORD` mappings from `externalSecrets.appEnv.fields`. The
relay owns the upstream provider credentials in the platform namespace; the
app should only receive the separate `MAIL_RELAY_USERNAME` and
`MAIL_RELAY_PASSWORD` credentials used to authenticate to the in-cluster relay.

On Hetzner clusters, the platform chart also installs a Kubernetes
[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
that only lets the Glossia app pods and GlitchTip pods connect to the relay.
It also installs a Cilium
[fully qualified domain name policy](https://docs.cilium.io/en/stable/security/dns/)
that limits the relay to Domain Name System lookups and outbound submission to
the configured provider host and port. Workload clusters also enable Cilium
[WireGuard transparent encryption](https://docs.cilium.io/en/stable/security/network/encryption-wireguard/)
for node-to-node pod traffic.

## Hermes, Slack, observability, and analytics

Enable `smolanalytics` and Hermes together to collect Glossia product events
and ask questions about them from Slack:

```yaml
smolanalytics:
  enabled: true
  persistence:
    storageClass: hcloud-volumes
    size: 20Gi
  ingress:
    enabled: true
    hosts:
      - host: analytics.example.com
        paths:
          - path: /
            pathType: Prefix

hermes:
  enabled: true
  persistence:
    storageClass: hcloud-volumes
  model:
    provider: custom:together
    default: MiniMaxAI/MiniMax-M3
    baseURL: https://api.together.ai/v1
    apiKeyEnvironmentVariable: TOGETHER_API_KEY
  observability:
    grafanaURL: http://observability-grafana.observability.svc.cluster.local
```

The default model is
[MiniMax M3](https://docs.together.ai/docs/serverless-models), which Together
recommends as a mid-size general-purpose model and supports the tool calls
Hermes needs for analytics and observability. The endpoint is Together's
[OpenAI-compatible chat endpoint](https://docs.together.ai/docs/inference/openai-compatibility);
the key remains in a Kubernetes Secret and is only exposed to the Hermes
container as `TOGETHER_API_KEY`.

The integration uses the
[Model Context Protocol](https://modelcontextprotocol.io/) to give Hermes two
read-only toolsets:

- The [smolanalytics](https://github.com/Arjun0606/smolanalytics) report tools
  answer questions about events, trends, funnels, retention, sessions, and
  instrumentation health. Mutation and import tools are omitted from the
  Hermes allowlist.
- The [Grafana Model Context Protocol server](https://github.com/grafana/mcp-grafana)
  can inspect dashboards, metrics, logs, and traces. It runs beside Hermes,
  listens only on the pod loopback address, uses a Grafana Viewer service
  account, and starts with writes disabled.

Hermes receives no terminal, file, browser, or web toolsets in Slack. The chart
also enables hard tool-loop limits and gives the bot a production-specific
instruction file that requires evidence, explicit time windows, and
privacy-preserving answers.

Glossia sends its existing domain events through an `analytics` background
queue. A user action only adds a durable job to the Glossia database; delivery
to smolanalytics happens out of band and is retried. The payload includes the
event name, opaque account and user identifiers, the deployment environment,
and a small allowlist of resource properties. Descriptions, email addresses,
and content are not forwarded.

smolanalytics is intentionally deployed as one writer with a `Recreate`
strategy and one persistent volume claim. Do not scale this deployment
horizontally. Its public write key can only ingest events, while the secret
read key protects reports and the protocol endpoint. The dashboard has a
separate password.

### Configure credentials

When the External Secrets integration is disabled, provision these three
Kubernetes Secrets before installing the chart:

| Secret | Required keys |
|---|---|
| `glossia-smolanalytics` | `SMOLANALYTICS_WRITE_KEY`, `SMOLANALYTICS_READ_KEY`, `SMOLANALYTICS_PASSWORD` |
| `glossia-hermes` | `TOGETHER_API_KEY`, `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN`, `SLACK_ALLOWED_USERS`, `API_SERVER_KEY` |
| `glossia-grafana-mcp` | `GRAFANA_SERVICE_ACCOUNT_TOKEN` |

Generate independent random values for both smolanalytics keys, its dashboard
password, and `API_SERVER_KEY`. Never reuse the ingestion key as the report
key. `SLACK_ALLOWED_USERS` is a comma-separated list of Slack member
identifiers; Hermes rejects everyone else. Set it to `*` when every member of
the installed Slack workspace should be allowed to talk to the bot.

With the External Secrets integration enabled, map the remote fields instead:

```yaml
externalSecrets:
  smolanalytics:
    itemKey: /glossia
    writeKeyField: SMOLANALYTICS_WRITE_KEY
    readKeyField: SMOLANALYTICS_READ_KEY
    passwordField: SMOLANALYTICS_PASSWORD
  hermes:
    itemKey: /glossia
    apiKeyField: TOGETHER_API_KEY
    slackBotTokenField: SLACK_BOT_TOKEN
    slackAppTokenField: SLACK_APP_TOKEN
    slackAllowedUsersField: SLACK_ALLOWED_USERS
    apiServerKeyField: HERMES_API_SERVER_KEY
  grafanaMcp:
    itemKey: /glossia
    serviceAccountTokenField: GRAFANA_SERVICE_ACCOUNT_TOKEN
```

Set `hermes.slackHomeChannelEnabled=true` and provide
`SLACK_HOME_CHANNEL` in the Hermes Secret when the bot should also post to a
dedicated Slack home channel. With External Secrets enabled, set
`externalSecrets.hermes.slackHomeChannelField` to the matching remote field.

Create the Grafana service account with the `Viewer` role and store its token
under the configured field. The application-level read-only role and the
bridge's write-disable flag are deliberately both required.

Follow the
[Hermes Slack setup guide](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/messaging/slack.md)
to create the Slack application. Enable Socket Mode, create the application
token with `connections:write`, install the bot into the workspace, subscribe
to the message and mention events listed in that guide, and invite the bot to
the channels where it should answer. Store the resulting `xapp-` application
token, `xoxb-` bot token, and member allowlist in the Hermes Secret.

### Verify the deployment

After installation, wait for both workloads:

```bash
kubectl -n glossia rollout status deployment/glossia-smolanalytics
kubectl -n glossia rollout status deployment/glossia-hermes
kubectl -n glossia get pods -l app.kubernetes.io/component=assistant
kubectl -n glossia get pods -l app.kubernetes.io/component=analytics
```

Sign in to the smolanalytics dashboard and confirm that Glossia events arrive.
Then ask Hermes questions that exercise each source, for example:

- “What changed in project creation and translation completion over the last
  seven days?”
- “Did the translation failure increase line up with errors or slow traces in
  Grafana?”
- “Show the conversion from project creation to the first completed
  translation, and state the exact filters you used.”

## Object Storage

By default, provide `GLOSSIA_S3_ACCESS_KEY_ID`,
`GLOSSIA_S3_SECRET_ACCESS_KEY`, `GLOSSIA_S3_ENDPOINT`,
`GLOSSIA_S3_REGION`, and `GLOSSIA_S3_BUCKET` in `secrets.envSecretName`.

For a provider-managed bucket, enable the provider-neutral mode. The following
example uses [Hetzner Object Storage](https://docs.hetzner.com/storage/object-storage/overview/):

```yaml
objectStorage:
  enabled: true
  endpointURL: https://fsn1.your-objectstorage.com
  region: fsn1
  bucketName: glossia-ai-production
  secretName: glossia-object-storage

externalSecrets:
  objectStorage:
    enabled: true
    itemKey: /glossia-object-storage
    accessKeyIdField: ACCESS_KEY_ID
    secretAccessKeyField: SECRET_ACCESS_KEY
```

The destination Secret contains `ACCESS_KEY_ID` and `SECRET_ACCESS_KEY` by
default. Set `objectStorage.accessKeyIdKey` and
`objectStorage.secretAccessKeyKey` when an existing Secret uses other names.

When the platform chart provisions an in-cluster Rook and Ceph
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-compatible
bucket, enable the Rook mode instead. It reads credentials from the Secret
created by the `ObjectBucketClaim` and sets the endpoint/bucket values
directly:

```yaml
objectStorage:
  rook:
    enabled: true
    endpointURL: http://rook-ceph-rgw-glossia-s3.platform.svc.cluster.local
    region: us-east-1
    bucketName: glossia-production
    bucketSecretName: glossia-s3
```

Use the internal Rook Ceph Object Gateway service endpoint here when the bucket
is private to the cluster. The app proxies user-facing uploads through its own
routes, so browsers do not need to reach the object gateway directly.

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
    region: auto                   # "" to omit; "auto" suits R2
  secretName: glossia-db-backup    # keys: ACCESS_KEY_ID, SECRET_ACCESS_KEY[, REGION]
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
`SECRET_ACCESS_KEY`, and `REGION` when `s3.region` is set — the CNPG
plugin only takes the region via a secret ref), or let the External
Secrets integration create it from a dedicated backend folder (it injects
`REGION` from `s3.region` for you; the backend folder only needs the two
keys):

```yaml
externalSecrets:
  enabled: true
  backup:
    itemKey: /glossia-db-backups-keys
    accessKeyIdField: ACCESS_KEY_ID
    secretAccessKeyField: SECRET_ACCESS_KEY
```

## Upgrades

Schema migrations and ClickHouse database creation run as `pre-install` /
`pre-upgrade` Helm hooks (`helm.sh/hook-weight: -10` for ClickHouse init,
`0` for Ecto migrations). A failed migration aborts the upgrade — the
running pods keep serving the previous release until the next attempt.

## Values reference

See [`values.yaml`](values.yaml) for the full default set with inline
documentation.

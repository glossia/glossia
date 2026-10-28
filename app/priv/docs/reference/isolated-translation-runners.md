%{
  title: "Isolated translation runners",
  summary: "Enterprise execution requirements, placement, lifecycle, and isolation controls.",
  category: "reference",
  section: "translation",
  edition: "enterprise",
  order: 10
}
---

Each translation session runs in a separate Kubernetes Job that survives web
deployments. Project setup uses sandbox Pods. A managed FLAME pool provides
additional runner capacity, separate from translation Jobs.

## Requirements

- The Enterprise image and permission for production use under the Enterprise License.
- A Kubernetes cluster. Outside Kubernetes, translations fall back to local
  execution **without isolation**.
- A scheduling service account allowed to read its Pod and Deployment, create
  and delete Jobs, and manage setup sandbox Pods in its namespace.
- Network access from translation Jobs to PostgreSQL, ClickHouse, GitHub, and
  the configured model provider. Cross-replica progress also requires BEAM
  clustering and a shared release cookie.
- `kubectl` in the application image, with in-cluster API access, for setup
  commands and file transfer.
- For microVM isolation, nodes with Kata installed and a matching RuntimeClass.

## Execution and isolation

Jobs inherit the scheduling web Pod's image, environment, environment sources,
and image-pull secrets. They keep that image for the session and are not owned
by the web Pod, so a web rollout does not delete them.

A Job starts database connections, PubSub, progress ingestion, and translation,
but no HTTP server, Oban queues, or runner pool. Its container has no mounted
Kubernetes service-account token. Cancelling a session also deletes its Job.

Failed Pods have at most two Job retries. Work can resume from published files
and durable checkpoints, but uninterrupted execution and exactly-once external
commands are not guaranteed.

**A separate Pod is not a microVM.** Without a configured Kata RuntimeClass,
workloads use ordinary containers and share the node's kernel. Jobs also inherit
application credentials: isolation does not make repository commands
credential-free. A missing RuntimeClass or unmatched node placement prevents
work from starting.

## Configuration

### Translation Jobs

| Environment variable | Default | Purpose |
|---|---|---|
| `GLOSSIA_TRANSLATION_JOB_TTL_SECONDS_AFTER_FINISHED` | `3600` | Retention of finished Jobs before Kubernetes cleans them up. |
| `GLOSSIA_TRANSLATION_JOB_ACTIVE_DEADLINE_SECONDS` | `86400` | Maximum Job lifetime, including scheduling and retries, in seconds. |
| `GLOSSIA_TRANSLATION_JOB_RESOURCES_JSON` | `{}` | Kubernetes resource requests and limits for the translation container. |

### Placement

Translation Jobs, managed runners, and setup sandbox Pods share placement
settings. These must match the target cluster; the edition does not enable a
RuntimeClass automatically.

| Environment variable | Default | Purpose |
|---|---|---|
| `GLOSSIA_MANAGED_APP_CONTAINER_NAME` | `web` | Application container to inherit from the scheduling Pod. |
| `GLOSSIA_MANAGED_RUNTIME_CLASS_NAME` | Unset | RuntimeClass, for example `kata-qemu`. Unset uses the cluster's default runtime. |
| `GLOSSIA_MANAGED_NODE_SELECTOR_JSON` | `{"glossia.io/managed-runner":"true"}` | Nodes eligible to run these workloads. |
| `GLOSSIA_MANAGED_TOLERATIONS_JSON` | `[]` | Tolerations for eligible nodes. |
| `GLOSSIA_MANAGED_AFFINITY_JSON` | `{}` | Kubernetes affinity rules. |
| `GLOSSIA_MANAGED_RESOURCES_JSON` | `{}` | Resource requests and limits for the FLAME pool, separate from translation Job resources. |

### Managed pool

Pool settings limit FLAME workers, **not translation Jobs**. Kubernetes quotas,
resources, and placement govern translation Job capacity.

| Environment variable | Default | Purpose |
|---|---|---|
| `GLOSSIA_MANAGED_MIN` | `2` | Pre-warmed FLAME workers. |
| `GLOSSIA_MANAGED_MAX` | `20` | Maximum FLAME workers. |
| `GLOSSIA_MANAGED_MAX_CONCURRENCY` | `2` | Concurrent calls per FLAME worker. |
| `GLOSSIA_MANAGED_IDLE_SHUTDOWN_MS` | `300000` | Idle worker shutdown delay. |
| `GLOSSIA_MANAGED_TIMEOUT_MS` | `3600000` | Pool call timeout. |
| `GLOSSIA_MANAGED_BOOT_TIMEOUT_MS` | `180000` | Worker boot timeout. |

## Engine-release recovery

Set an immutable `GLOSSIA_ENGINE_IMAGE` and configure
`GLOSSIA_ENGINE_DEPLOYMENT` to enable rollout checks before continuing eligible
engine-related failures on a newer release. See
[Translation recovery](/docs/explanation/translation-recovery#recovery-after-an-engine-release)
for eligibility and retry bounds. Community retains provider recovery and durable
progress, but does not inspect Kubernetes rollouts.

%{
  title: "Isolated translation runners",
  summary: "Enterprise execution requirements, placement, lifecycle, and isolation controls.",
  category: "reference",
  section: "translation",
  edition: "enterprise",
  order: 10
}
---

Isolated translation runners execute each translation session as a detached
Kubernetes Job. They also provide a managed FLAME runner pool and a
Kubernetes-backed adapter for project-setup sandboxes. The implementations and
their tests live under `ee/` and are absent from Community builds.

## Requirements

- An Enterprise build and permission for production use under the Enterprise License.
- A Kubernetes cluster. Outside a cluster, the Enterprise translation launcher
  falls back to local execution; it does not provide isolation there.
- A scheduling service account allowed to read its Pod and Deployment, create
  and delete Jobs, and manage setup sandbox Pods in its namespace.
- Network access from translation Jobs to PostgreSQL, ClickHouse, GitHub, and
  the configured model provider. Progress delivery across replicas also needs
  the existing BEAM clustering configuration and a shared release cookie.
- For setup sandbox command execution and file transfer, `kubectl` in the
  application release image with access to the in-cluster API.
- For microVM isolation, nodes with Kata installed and a matching RuntimeClass.

## Translation Job lifecycle

The Job inherits the scheduling web Pod's application image, environment,
environment sources, and image-pull secrets. It has no owner reference to the
web Pod, so a web rollout does not garbage-collect the Job. It runs the image
selected at launch rather than switching engine versions mid-session.

The Job starts database connections, PubSub, progress ingestion, and the
translation task. It does not serve HTTP, consume Oban queues, or start another
runner pool. Its container has no mounted Kubernetes service-account token.
Cancelling a session deletes its detached Job as well as marking the session
cancelled.

Failed Pods have a Job backoff limit of two retries. The application can resume
from published files and durable checkpoints. This is bounded recovery, not a
guarantee of uninterrupted execution or exactly-once external commands.

## Job settings

| Environment variable | Default | Purpose |
|---|---|---|
| `GLOSSIA_TRANSLATION_JOB_TTL_SECONDS_AFTER_FINISHED` | `3600` | Retention of finished Jobs before Kubernetes cleans them up. |
| `GLOSSIA_TRANSLATION_JOB_ACTIVE_DEADLINE_SECONDS` | `86400` | Maximum Job lifetime, including scheduling and retries, in seconds. |
| `GLOSSIA_TRANSLATION_JOB_RESOURCES_JSON` | `{}` | Kubernetes resource requests and limits for the translation container. |

## Placement and isolation

Translation Jobs, managed runners, and setup sandbox Pods share placement
settings. RuntimeClass and node placement must match the target cluster.

| Environment variable | Default | Purpose |
|---|---|---|
| `GLOSSIA_MANAGED_APP_CONTAINER_NAME` | `web` | Application container to inherit from the scheduling Pod. |
| `GLOSSIA_MANAGED_RUNTIME_CLASS_NAME` | Unset | RuntimeClass, for example `kata-qemu`. Unset uses the cluster's default runtime. |
| `GLOSSIA_MANAGED_NODE_SELECTOR_JSON` | `{"glossia.io/managed-runner":"true"}` | Nodes eligible to run these workloads. |
| `GLOSSIA_MANAGED_TOLERATIONS_JSON` | `[]` | Tolerations for eligible nodes. |
| `GLOSSIA_MANAGED_AFFINITY_JSON` | `{}` | Kubernetes affinity rules. |
| `GLOSSIA_MANAGED_RESOURCES_JSON` | `{}` | Resource requests and limits for the FLAME pool, separate from translation Job resources. |

No RuntimeClass is enabled by the edition alone. Without Kata, the workloads
use ordinary containers and share the node's kernel. A missing RuntimeClass
or nodes that do not match placement settings prevent work from starting.

The translation Job inherits application credentials needed to perform its
work. Isolation does not remove those credentials or establish a credential-free
execution boundary for arbitrary repository commands.

## Managed pool

| Environment variable | Default | Purpose |
|---|---|---|
| `GLOSSIA_MANAGED_MIN` | `2` | Pre-warmed FLAME workers. |
| `GLOSSIA_MANAGED_MAX` | `20` | Maximum FLAME workers. |
| `GLOSSIA_MANAGED_MAX_CONCURRENCY` | `2` | Concurrent calls per FLAME worker. |
| `GLOSSIA_MANAGED_IDLE_SHUTDOWN_MS` | `300000` | Idle worker shutdown delay. |
| `GLOSSIA_MANAGED_TIMEOUT_MS` | `3600000` | Pool call timeout. |
| `GLOSSIA_MANAGED_BOOT_TIMEOUT_MS` | `180000` | Worker boot timeout. |

The pool is separate from detached translation Jobs. Its capacity settings do
not limit the number of translation Jobs; Kubernetes quotas, resources, and
placement govern Job capacity.

## Engine-release recovery

With an immutable `GLOSSIA_ENGINE_IMAGE` and a configured
`GLOSSIA_ENGINE_DEPLOYMENT`, Enterprise verifies Deployment rollout status before
continuing eligible engine-related failures on a newer release. See
[Translation recovery](/docs/explanation/translation-recovery#recovery-after-an-engine-release)
for eligibility and retry bounds. Local Community execution retains provider
recovery and durable progress but does not inspect Kubernetes rollouts.

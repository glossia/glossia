%{
  title: "Self-host Glossia",
  summary: "Install Glossia on your own Kubernetes cluster with the bundled Helm chart, so your team runs the language OS on its own infrastructure.",
  category: "how-to",
  order: 2
}
---

Glossia is open source under the [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). You can self-host it, modify it, and run it for your organization's internal use. The one thing the license does not permit is offering it to third parties as a hosted or SaaS product that competes with the hosted service at glossia.ai.

This guide gets you from an empty Kubernetes cluster to a running Glossia instance.

## Before you start

You'll need:

- A Kubernetes cluster you can install Helm charts on (v1.28 or newer)
- `helm` and `kubectl` locally
- A domain you can point at the cluster ingress
- An OpenID Connect provider or SMTP relay for authentication (Glossia supports both)

The Helm chart bundles Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) and ClickHouse (via the [official operator](https://github.com/ClickHouse/clickhouse-operator)) so you don't need external databases. If you'd rather bring your own, both can be disabled in `values.yaml`.

## Install the operators

Install whichever operators match the components you plan to enable. At minimum:

- [CloudNativePG operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) for the app database
- [ClickHouse Kubernetes operator](https://github.com/ClickHouse/clickhouse-operator) for the analytics database
- An ingress controller (for example [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) if you want automatic TLS

## Install the Glossia chart

Clone the repository, then install the chart:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Provide the app secrets

Create a Kubernetes Secret named `glossia-app-env` with at least these keys:

| Key | Purpose |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Phoenix session signing key |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Bearer token guarding `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth for `/ops` dashboards |
| `RELEASE_COOKIE` | Erlang distribution cookie shared by every pod |
| `GLOSSIA_SMTP_*` | Outbound email settings |

You can provision these directly, use [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), or wire the chart to your secret manager via the [External Secrets Operator](https://external-secrets.io/) integration described in the chart README.

## What lives in the chart

- The Glossia web application
- Postgres for application data (optional, on by default)
- ClickHouse for analytics (optional, on by default)
- Background workers for translation jobs, which run as Kubernetes Jobs so they outlive rolling deploys

## Where to go next

- The [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) has the full reference for every value, plus notes on backups, object storage, and observability.
- [Configure a model provider](/docs/how-to/configure-a-model-provider) once the instance is running so translations can call an LLM.
- Report issues or suggest improvements at the [GitHub repository](https://github.com/glossia/glossia).

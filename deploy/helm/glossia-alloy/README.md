# glossia-alloy

Workload-cluster observability shipper. Deploys Grafana Alloy as a
node DaemonSet and a singleton event Deployment:

* **Metrics** — scrapes the Glossia app's `/metrics`, kube-state-metrics,
  kubelet, cAdvisor, and host-level Unix metrics; remote_writes to
  `https://mimir.glossia.ai/api/v1/push`.
* **Logs** — tails pod logs through the Kubernetes application
  programming interface with `loki.source.kubernetes`, restricted to
  pods on the same node as each Alloy replica, and pushes to
  `https://loki.glossia.ai/loki/api/v1/push`.
* **Events** — streams Kubernetes events once into Loki with the
  `integrations/kubernetes/eventhandler` job label.

Both endpoints are protected by Hypertext Transfer Protocol
(https://developer.mozilla.org/en-US/docs/Web/HTTP) basic
authentication; the same per-workload token in `glossia-push-creds`
Secret authenticates both.

**Tracing is not shipped by this chart.** The app's OpenTelemetry client
wiring (`app/config/runtime.exs`) sends traces directly when
`OTEL_EXPORTER_OTLP_ENDPOINT` is set. Cross-cluster trace export uses
the same push endpoint credentials via `OTEL_EXPORTER_OTLP_HEADERS`.

## Pre-install (one-time, per workload cluster)

1. **1Password** (in this workload cluster's vault, e.g.
   `glossia-production`): add item `push-token-glossia-production` with
   fields `USERNAME` (e.g. `glossia-production`) and `TOKEN` (a random
   high-entropy string). Generate the matching bcrypt'd htpasswd line
   with `htpasswd -B -n <USERNAME>` and append it to the observability cluster's
   `push-endpoints-auth` 1Password item htpasswd field.
2. The app's `kubernetes` 1Password item must already have
   `METRICS_BEARER_TOKEN` (it does — used by the app chart's appEnv
   ExternalSecret).
3. Domain Name System (https://www.cloudflare.com/learning/dns/what-is-dns/)
   records for the Mimir and Loki observability hostnames must resolve.
   Tempo also needs a record for app trace export.

## Install

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm dependency update deploy/helm/glossia-alloy

helm upgrade --install alloy deploy/helm/glossia-alloy \
  -n observability --create-namespace \
  -f deploy/values-alloy-production.yaml
```

## Verify

```bash
# DaemonSet healthy (one Alloy per node) and event Deployment healthy
kubectl -n observability rollout status ds/alloy
kubectl -n observability rollout status deploy/alloy-alloy-events

# Alloy logs — should show successful scrapes and remote_write 200s
kubectl -n observability logs ds/alloy --tail=50
kubectl -n observability logs deploy/alloy-alloy-events --tail=50

# Push round-trip from the cluster
kubectl -n observability exec ds/alloy -- \
  wget -q -O- --user=$(kubectl -n observability get secret \
    glossia-push-creds -o jsonpath='{.data.USERNAME}' | base64 -d) \
  --password=$(kubectl -n observability get secret \
    glossia-push-creds -o jsonpath='{.data.TOKEN}' | base64 -d) \
  https://mimir.glossia.ai/ready
```

End-to-end: open `https://grafana.glossia.ai`, query `up{job="glossia"}`.
You should see one series per Glossia pod, value 1.

## Wiring traces (app-side, separate from this chart)

After Alloy is running, the app should export traces directly to Tempo.
`deploy/values-production.yaml` sets `OTEL_EXPORTER_OTLP_ENDPOINT` and
pulls `OTEL_EXPORTER_OTLP_HEADERS` from the app environment
ExternalSecret. Store the header value in 1Password as
`authorization=Basic <base64-of-user:pass>`.

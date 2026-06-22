# Tailscale Operator

This chart installs the Tailscale Kubernetes operator and a dedicated
Kubernetes control-plane proxy for a workload cluster. The proxy gives
operators and automation a tailnet-only path to Kubernetes while keeping
existing Kubernetes ServiceAccount tokens as the authentication layer.

The setup here uses Tailscale's `noauth` mode, which means Tailscale provides
the private network path and Kubernetes still validates the original bearer
token.

## Prerequisites

Create a Tailscale Open Authorization (https://oauth.net/2/) client with
write access for auth keys and the tags used by the cluster proxies:

- `tag:glossia-k8s-production`
- `tag:glossia-k8s-observability`

Store the credentials in 1Password item `tailscale-operator` in the
`glossia-production` vault:

- `client-id`
- `client-secret`

Create a separate GitHub Actions Open Authorization client that can mint
`tag:glossia-github-actions`, then store it as production environment secrets
`TS_OAUTH_CLIENT_ID` and `TS_OAUTH_SECRET`.

Keep `infra/tailscale/policy.hujson` mirrored into the Tailscale Access
controls page. It allows operators and `tag:glossia-github-actions` to connect
to the proxy tags on Transmission Control Protocol port 443.

## Install

```bash
helm dependency build infra/helm/tailscale-operator

helm upgrade --install tailscale-operator infra/helm/tailscale-operator \
  --namespace tailscale \
  --create-namespace \
  --values infra/helm/tailscale-operator/values-production.yaml

helm upgrade --install tailscale-operator infra/helm/tailscale-operator \
  --namespace tailscale \
  --create-namespace \
  --values infra/helm/tailscale-operator/values-observability.yaml
```

Wait for each proxy:

```bash
kubectl wait proxygroup glossia-production-kube \
  --for=condition=ProxyGroupReady=true \
  --timeout=5m

kubectl get proxygroup glossia-production-kube -o jsonpath='{.status.url}'
```

## Kubeconfig Cutover

After the proxy reports a `https://*.ts.net` address, rewrite the cluster's
kubeconfig to use that address as `clusters[].cluster.server` and remove
`clusters[].cluster.certificate-authority-data`. The proxy certificate is
issued for the tailnet name, while the existing ServiceAccount token remains
the Kubernetes credential.

Once the production and automation kubeconfigs use the proxy and GitHub
Actions joins the tailnet before deployment, the remaining public Kubernetes
control-plane exposure can be retired.

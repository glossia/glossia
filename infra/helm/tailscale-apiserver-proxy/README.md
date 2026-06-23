# Tailscale Kubernetes Application Programming Interface Server Proxy

This chart runs one Tailscale proxy in a workload cluster. The proxy joins
the Glossia tailnet, persists its node identity in a Kubernetes Secret, and
forwards incoming tailnet traffic to the in-cluster Kubernetes service at
`10.128.0.1:443`.

The Kubernetes
[Application Programming Interface server](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
is the cluster control-plane service that `kubectl` talks to.

The proxy does not replace Kubernetes authentication. `kubectl` still uses
the existing token and certificate authority from the kubeconfig. The
kubeconfig server points at the Tailscale name, and `tls-server-name` stays
set to `kubernetes` so certificate verification still matches the
Kubernetes server certificate.

## Prerequisites

Mirror `infra/tailscale/policy.hujson` into the Tailscale access controls.
Then create one tagged, pre-approved auth key for each long-running proxy:

- `tag:glossia-k8s-production` for production.
- `tag:glossia-k8s-observability` for observability.

Store the production key in 1Password item
`tailscale-apiserver-proxy-production`, field `authkey`, in the
`glossia-production` vault. Store the observability key in
`tailscale-apiserver-proxy-observability`, field `authkey`.

The key is only needed for the first join. After the proxy writes its
Tailscale state Secret, `TS_AUTH_ONCE=true` keeps restarts from consuming a
new key. If the state Secret is deleted, create and store a fresh key before
the next restart.

GitHub Actions uses a separate reusable, ephemeral, pre-approved auth key
tagged `tag:glossia-github-actions`, stored as the production environment
secret `TAILSCALE_AUTHKEY`.

## Install

```bash
kubectl create namespace tailscale --dry-run=client -o yaml | kubectl apply -f -
kubectl label --overwrite namespace tailscale \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged

helm upgrade --install tailscale-apiserver-proxy \
  infra/helm/tailscale-apiserver-proxy \
  --namespace tailscale \
  --values infra/helm/tailscale-apiserver-proxy/values-production.yaml
```

Use `values-observability.yaml` when installing into the observability
cluster.

## Verify

```bash
kubectl -n tailscale rollout status deployment/tailscale-apiserver-proxy --timeout=5m
tailscale ping glossia-production-kube
```

Then rewrite the cluster kubeconfig to use
`https://glossia-production-kube.tail96f99b.ts.net:443` as the server and
`tls-server-name: kubernetes`.

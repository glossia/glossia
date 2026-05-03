%{
  title: "Deploy on Hetzner Kubernetes",
  summary: "Provision a Hetzner-hosted Kubernetes cluster, run Postgres, ClickHouse, and Grafana in-cluster, and deploy Glossia from GitHub Actions.",
  category: "how-to",
  order: 3
}
---

This guide sets up a Kubernetes deployment path for Glossia on Hetzner Cloud. It keeps **Postgres**, **ClickHouse**, and **Grafana** inside the cluster and uses GitHub Actions to roll out the application.

The repository now includes five pieces:

1. `infra/terraform/hetzner/` provisions the Hetzner cluster with [`kube-hetzner`](https://registry.terraform.io/modules/kube-hetzner/kube-hetzner/hcloud/latest).
2. `deploy/k8s/manifests/` defines the in-cluster Postgres and ClickHouse resources plus the shared namespaces and TLS issuers.
3. `deploy/k8s/bootstrap-cluster.sh` installs the operators and Grafana.
4. `deploy/helm/glossia/` deploys the Phoenix app, initializes the ClickHouse database, and runs release migrations.
5. `deploy/1password/kubernetes-production.env.tpl` and `deploy/1password/load-kubernetes-env.sh` map the Kubernetes deploy secrets to 1Password secret references.

## 1. Provision the cluster

You do not need to keep real secrets in the repository checkout.

Recommended:

- keep the Hetzner API token in your shell environment or 1Password
- keep any local Terraform variable file untracked
- write the generated kubeconfig outside the repository if you prefer

The Terraform folder ignores `terraform.tfvars`, `*.auto.tfvars`, state files, and the sample `glossia_kubeconfig.yaml` output.

Copy the example variables file and adjust it for your environment:

```bash
cp infra/terraform/hetzner/terraform.tfvars.example infra/terraform/hetzner/terraform.tfvars
```

That file is local-only and should stay uncommitted.

The defaults assume:

- A single Hetzner location for the whole cluster (`fsn1`)
- Three control plane nodes
- A general-purpose worker pool for the app
- A tainted `stateful` worker pool for Postgres, ClickHouse, and Grafana

Keeping the cluster in a single location is intentional. Hetzner volumes are attached in the location chosen when the workload is first scheduled, so the stateful workloads in this setup should stay in one location unless you intentionally redesign the storage story.

Apply the cluster:

```bash
cd infra/terraform/hetzner
export TF_VAR_hcloud_token=your_hetzner_token
terraform init
terraform apply
```

If you would rather avoid storing even the token in `terraform.tfvars`, leave `hcloud_token` out of the file and provide it only through `TF_VAR_hcloud_token`.

Export the kubeconfig once Terraform finishes:

```bash
terraform output -raw kubeconfig > glossia_kubeconfig.yaml
```

If you do not want the kubeconfig written inside the repo checkout, write it somewhere under your home directory instead:

```bash
mkdir -p ~/.config/glossia
terraform output -raw kubeconfig > ~/.config/glossia/hetzner-kubeconfig.yaml
```

You will also need the ingress IP if you plan to create DNS records manually:

```bash
terraform output ingress_public_ipv4
```

Without automatic DNS management, point these DNS records at that IP:

- `glossia.ai`
- `data.glossia.ai`

If you use different hostnames, update:

- `deploy/k8s/helm-values/glossia-production.yaml`
- `deploy/k8s/helm-values/grafana.yaml`
- `deploy/k8s/manifests/base/cluster-issuer-http01.yaml`
- `deploy/k8s/manifests/base/cluster-issuer-cloudflare-dns01.yaml`

If your DNS is hosted in Cloudflare, you can skip the manual record creation and let Kubernetes manage those records automatically with ExternalDNS. See the Cloudflare token step below.

## 2. Put the deployment secrets in 1Password

The preferred setup is a **1Password service account** scoped to a single vault used by this deploy path.

Create:

- a vault named `glossia-production`
- an item in that vault named `kubernetes`
- a GitHub production environment secret named `OP_SERVICE_ACCOUNT_TOKEN`

The item should contain the required fields below. Optional fields can be omitted entirely; the loader skips any optional 1Password field that does not exist yet.

- `K8S_KUBECONFIG_B64`
- `POSTGRES_PASSWORD`
- `SECRET_KEY_BASE`
- `METRICS_BEARER_TOKEN`
- `OPS_AUTH_PASSWORD`
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `GF_SECURITY_ADMIN_PASSWORD`

The same item can also include optional integration fields such as `SENTRY_DSN`, `GITHUB_*`, `GITLAB_*`, `S3_*`, and the optional `GHCR_PULL_USERNAME` / `GHCR_PULL_TOKEN`. You can omit optional fields you do not use.

To let Kubernetes manage `glossia.ai` and `data.glossia.ai` in Cloudflare, also add:

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ZONE_ID` if the token is restricted to the `glossia.ai` zone

The recommended token shape is a Cloudflare API token scoped to the `glossia.ai` zone with Zone DNS edit and Zone read privileges. If you scope the token to only that zone, also set `CLOUDFLARE_ZONE_ID` so ExternalDNS can limit its API requests to the same zone.

Create the kubeconfig field value with:

```bash
base64 < glossia_kubeconfig.yaml | tr -d '\n'
```

## 3. Bootstrap the cluster services

The supported path uses 1Password.

It expects:

- `kubectl`
- `helm`
- the 1Password CLI (`op`)
- access to the `glossia-production/kubernetes` item described above

Render the Kubernetes secrets from 1Password, then install the operators and Grafana:

```bash
kubectl apply -f deploy/k8s/manifests/base/namespaces.yaml
./deploy/1password/load-kubernetes-env.sh -- ./deploy/k8s/render-secrets.sh | kubectl apply -f -
./deploy/k8s/bootstrap-cluster.sh
```

If `CLOUDFLARE_API_TOKEN` is present, the bootstrap script also installs ExternalDNS and switches cert-manager to Cloudflare-backed `DNS-01` validation. From that point on, the `glossia.ai` and `data.glossia.ai` records are managed from the Kubernetes ingresses instead of by hand, and TLS no longer depends on HTTP challenge routing through Traefik.

That bootstrap installs:

- CloudNativePG for PostgreSQL
- The official ClickHouse Operator
- ExternalDNS for Cloudflare, when a Cloudflare API token is provided
- A Cloudflare-backed `DNS-01` Let's Encrypt issuer, when a Cloudflare API token is provided
- A single Grafana instance with Postgres and ClickHouse datasources
- A three-instance Postgres cluster
- A single-replica ClickHouse + Keeper pair

The ClickHouse layout is intentionally conservative to keep the starting cluster affordable. If analytics throughput or availability requirements grow, scale the `KeeperCluster` and `ClickHouseCluster` manifests together.

## 4. Configure GitHub Actions

The production deploy and bootstrap workflows use 1Password only.

Recommended GitHub production environment secrets:

1. `OP_SERVICE_ACCOUNT_TOKEN`

If your `ghcr.io` image stays private, add `GHCR_PULL_USERNAME` and `GHCR_PULL_TOKEN` to the same 1Password item.

## 5. Run the first bootstrap from GitHub

After `OP_SERVICE_ACCOUNT_TOKEN` exists, run the **Bootstrap Kubernetes Cluster** workflow once. It performs the same steps as the local bootstrap path:

- creates namespaces
- renders secrets from 1Password
- installs the operators
- applies the Postgres and ClickHouse manifests
- installs Grafana

## 6. Deploy the app

Once the cluster is bootstrapped, the normal **Deploy Production** workflow will:

1. build the app image from `app/Dockerfile`
2. push it to `ghcr.io`
3. render the Kubernetes secrets from 1Password
4. optionally create the GHCR pull secret
5. run `helm upgrade --install` for `deploy/helm/glossia`

The Helm release also:

- creates the ClickHouse database if it does not exist yet
- runs `/app/bin/migrate` before each install or upgrade
- exposes the web app through Traefik

## 7. Notes and follow-up

- The app runtime now enables Loki logging and OTLP exporting only when those endpoints are explicitly configured. The Kubernetes path starts without that full observability stack.
- The Terraform wrapper supports `etcd_s3_backup`, which is the fastest disaster-recovery improvement to turn on after the first successful rollout.
- Even with 1Password in place, GitHub still needs the `OP_SERVICE_ACCOUNT_TOKEN` secret because that is how the workflow authenticates to 1Password.
- Postgres and ClickHouse backups are not yet automated in this repository. Add those before treating the cluster as your only production environment.

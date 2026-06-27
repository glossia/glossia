# Onboarding — Glossia on self-hosted CAPI on Hetzner

End-to-end runbook for standing up the Glossia infrastructure from
zero: bootstrap the management cluster, then bring up a workload
cluster (e.g. `glossia-production`) and deploy onto it.

We run a **management cluster** (a single-node Talos VM in Hetzner
project `glossia-mgmt`) hosting
[Cluster Application Programming Interface](https://cluster-api.sigs.k8s.io/)
(CAPI) v1.13 + Cluster Application Programming Interface Provider
Hetzner v1.1. Operators reach `talosctl` only via Tailscale.
Workload clusters live in a separate Hetzner project
(`glossia-workloads`); each is described as a `Cluster` custom resource
against the shared `glossia-hcloud` ClusterClass and is applied to the
mgmt cluster. Workload Kubernetes control-plane access should be cut
over to the Tailscale proxy in §B.4 before the public Hetzner endpoint
is closed.

---

## Prerequisites

- A Hetzner Cloud account. Recommended layout is **two projects**:
  - `glossia-mgmt` — hosts the management VM only.
  - `glossia-workloads` — hosts every workload cluster's nodes + LBs.
  Two API tokens (read/write) saved to 1Password as
  `hetzner-glossia-mgmt` and `hetzner-glossia-workloads`.

  The split is so a leaked workload-project token can't reach the
  mgmt VM. A single-project setup (one token reused for both) works
  too — the runbook calls out where it differs. Splitting later is
  a Secret rotation, not a re-bootstrap.
- A Cloudflare account with an API token scoped to `Zone.DNS:Edit` on
  `glossia.ai` and `l10n.md`, saved to 1Password as
  `cloudflare-glossia-dns`.
- A Tailscale tenant with admin access (one-time bootstrap below).
- An S3-compatible bucket for hourly etcd snapshots
  (`glossia-mgmt-etcd-snapshots`) with bucket-scoped access keys saved
  to 1Password as `glossia-mgmt-etcd-snapshots-keys`.
- 1Password vault `glossia-production`. All k8s-related items
  (Hetzner tokens, Talos / kubeconfigs, SSH keys, S3 keys, Cloudflare
  token, etc.) live here. A Service Account scoped to this vault
  is needed by ESO on workload clusters (see Part B).
  The `kubernetes` item must include `SMTP_HOST`, `SMTP_PORT`,
  `SMTP_USERNAME`, and `SMTP_PASSWORD`; the platform chart uses them to
  configure the cluster [Simple Mail Transfer Protocol](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol)
  relay. It must also include `MAIL_RELAY_USERNAME` and
  `MAIL_RELAY_PASSWORD`, which are separate client credentials for services
  submitting to the relay. Keep the provider host and port aligned with the
  Cilium
  [fully qualified domain name policy](https://docs.cilium.io/en/stable/security/dns/)
  in `infra/helm/platform/values-hetzner.yaml`; relay egress is denied
  everywhere else.
- CLI tools installed via mise:
  ```bash
  mise use -g kubectl helm clusterctl talosctl jq
  ```
- The 1Password CLI (`op`) authenticated to the desktop app
  (Settings → Developer → Connect with 1Password CLI + biometric unlock).
- `hcloud-upload-image` for the Talos snapshot upload step:
  ```bash
  curl -sL https://github.com/apricote/hcloud-upload-image/releases/latest/download/hcloud-upload-image_$(uname -s)_$(uname -m | sed 's/x86_64/amd64/').tar.gz | tar -xz -C /tmp
  ```

---

## Part A — Bootstrap the management cluster

One-time. Skip to Part B once the mgmt cluster is up.

### A.1 SSH key + Talos snapshot + VM

```bash
export HCLOUD_TOKEN=$(op read 'op://glossia-production/hetzner-glossia-mgmt/credential')

# 1. SSH keypair (ed25519). The private half is stashed in 1Password,
#    the public half is uploaded to Hetzner so cloud-init embeds it
#    on every VM.
ssh-keygen -t ed25519 -f ~/.ssh/glossia-ops -N '' -C 'glossia-ops'
op document create ~/.ssh/glossia-ops --vault glossia-production \
  --title 'ssh-glossia-ops (private key)'
op document create ~/.ssh/glossia-ops.pub --vault glossia-production \
  --title 'ssh-glossia-ops (public key)'

curl -sX POST https://api.hetzner.cloud/v1/ssh_keys \
  -H "Authorization: Bearer $HCLOUD_TOKEN" -H "Content-Type: application/json" \
  -d "$(jq -n --arg key "$(cat ~/.ssh/glossia-ops.pub)" '{name:"glossia-ops", public_key:$key}')"

# 2. Hetzner firewall: tcp/6443 world (CI hits the apiserver),
#    tcp/50000 operator-only (talosctl; tightened to tailnet in §A.6),
#    icmp world.
OPERATOR_IP=$(curl -s https://api.ipify.org)/32
curl -sX POST https://api.hetzner.cloud/v1/firewalls \
  -H "Authorization: Bearer $HCLOUD_TOKEN" -H "Content-Type: application/json" \
  -d "$(jq -n --arg op "$OPERATOR_IP" '{
    name:"glossia-mgmt", labels:{role:"mgmt"},
    rules:[
      {direction:"in",protocol:"tcp",port:"6443",source_ips:["0.0.0.0/0","::/0"],description:"kube-apiserver"},
      {direction:"in",protocol:"tcp",port:"50000",source_ips:[$op],description:"talosctl"},
      {direction:"in",protocol:"icmp",source_ips:["0.0.0.0/0","::/0"],description:"ping"}
    ]
  }')"
# Stash the firewall id; needed when creating the server.

# 3. Talos image → Hetzner snapshot. factory.talos.dev returns a
#    pre-baked hcloud-ready raw image; hcloud-upload-image spins up a
#    short-lived rescue helper, dd's the image to a fresh disk, and
#    snapshots it. The schematic with empty customization is fine —
#    Talos's hcloud platform support is built-in.
SCHEMATIC=$(curl -sX POST https://factory.talos.dev/schematics \
  -H 'Content-Type: application/json' -d '{"customization":{}}' | jq -r '.id')
TALOS_VER=v1.13.0
/tmp/hcloud-upload-image upload \
  --image-url "https://factory.talos.dev/image/$SCHEMATIC/$TALOS_VER/hcloud-amd64.raw.xz" \
  --architecture x86 --compression xz --location fsn1 \
  --description "Talos $TALOS_VER hcloud-amd64" \
  --labels "os=talos,version=$TALOS_VER,arch=amd64,platform=hcloud"
# Note the resulting image id — needed when creating the server.

# 4. Provision the mgmt VM. cpx22 (2 vCPU / 4 GB / 80 GB, ~€8/mo gross)
#    is the current intel SKU; cpx21 (the older AMD line) is end-of-sale
#    and Hetzner will reject new orders for it.
curl -sX POST https://api.hetzner.cloud/v1/servers \
  -H "Authorization: Bearer $HCLOUD_TOKEN" -H "Content-Type: application/json" \
  -d '{
    "name":"glossia-mgmt", "server_type":"cpx22", "location":"fsn1",
    "image": <SNAPSHOT_ID>, "ssh_keys":["glossia-ops"],
    "firewalls":[{"firewall": <FIREWALL_ID>}],
    "labels":{"role":"mgmt","cluster":"glossia-mgmt"},
    "start_after_create": true
  }' | jq '.server | {id, name, status, ipv4:.public_net.ipv4.ip}'
```

### A.2 Bootstrap Talos + Kubernetes

```bash
MGMT_IP=<public IPv4 from §A.1 step 4>
WORK=$(mktemp -d /tmp/glossia-talos.XXXXXX) && chmod 700 "$WORK"

talosctl gen config glossia-mgmt "https://${MGMT_IP}:6443" \
  --output-dir "$WORK" \
  --kubernetes-version 1.34.6 \
  --install-disk /dev/sda

talosctl --talosconfig "$WORK/talosconfig" config endpoint "$MGMT_IP"
talosctl --talosconfig "$WORK/talosconfig" config node "$MGMT_IP"

# Apply controlplane config in maintenance mode. --insecure skips
# client-cert verification; only valid before machine config is present.
talosctl --talosconfig "$WORK/talosconfig" apply-config \
  --insecure --nodes "$MGMT_IP" --file "$WORK/controlplane.yaml"

# Wait for the API to require client certs (= config applied), then
# bootstrap etcd and fetch the kubeconfig.
until talosctl --talosconfig "$WORK/talosconfig" version 2>&1 | grep -q "Server:"; do sleep 5; done
talosctl --talosconfig "$WORK/talosconfig" bootstrap
until curl -sk --max-time 3 "https://${MGMT_IP}:6443/livez" >/dev/null 2>&1; do sleep 5; done
talosctl --talosconfig "$WORK/talosconfig" kubeconfig "$WORK/kubeconfig"
chmod 600 "$WORK/kubeconfig"

# Single-node mgmt cluster: lift the control-plane NoSchedule taint so
# CAPI controllers / cert-manager / etc. can land. Persisted via Talos
# machine config so a reboot doesn't bring it back.
cat > /tmp/allow-cp-scheduling.yaml <<'YAML'
cluster:
  allowSchedulingOnControlPlanes: true
YAML
talosctl --talosconfig "$WORK/talosconfig" patch mc \
  --patch @/tmp/allow-cp-scheduling.yaml
rm /tmp/allow-cp-scheduling.yaml

# Stash configs in 1Password — these are the cluster's keys to the
# kingdom. controlplane.yaml carries the cluster CA + secrets; needed
# to rebuild the VM if it dies. Each `op document create` triggers a
# Touch ID prompt; approve them as they pop up.
op document create "$WORK/talosconfig" --vault glossia-production \
  --title 'talosconfig: glossia-mgmt'
op document create "$WORK/kubeconfig" --vault glossia-production \
  --title 'kubeconfig: glossia-mgmt'
op document create "$WORK/controlplane.yaml" --vault glossia-production \
  --title 'talos-controlplane: glossia-mgmt'

rm -rf "$WORK"
```

### A.3 Install CAPI + caph

```bash
op document get "kubeconfig: glossia-mgmt" --vault glossia-production --out-file ~/.kube/glossia-mgmt.yaml
chmod 600 ~/.kube/glossia-mgmt.yaml
export KUBECONFIG=~/.kube/glossia-mgmt.yaml
export HCLOUD_TOKEN=$(op read 'op://glossia-production/hetzner-glossia-mgmt/credential')

# CLUSTER_TOPOLOGY=true enables the ClusterTopology feature gate on
# capi-controller-manager + capi-kubeadm-control-plane-controller-manager.
# Without it, ClusterClass / topology-mode Cluster CRs are rejected by
# the validation webhooks ("can be set only if the ClusterTopology
# feature flag is enabled"). caph + cert-manager are pulled by name.
CLUSTER_TOPOLOGY=true clusterctl init --infrastructure hetzner

# Talos enforces strict PodSecurity by default. CAPI controllers don't
# satisfy `restricted` (no runAsNonRoot, no seccompProfile, etc.), so
# their namespaces have to be flipped to `privileged`. This is the
# upstream-supported posture for CAPI on Talos.
for ns in capi-system capi-kubeadm-bootstrap-system \
          capi-kubeadm-control-plane-system caph-system cert-manager; do
  kubectl label --overwrite ns "$ns" \
    pod-security.kubernetes.io/enforce=privileged \
    pod-security.kubernetes.io/audit=privileged \
    pod-security.kubernetes.io/warn=privileged
done

# Re-run init — clusterctl is idempotent and reconciles the previously-
# rejected caph Deployment now that the namespace allows it.
CLUSTER_TOPOLOGY=true clusterctl init --infrastructure hetzner

kubectl get pods -A
# Expect capi-system, capi-kubeadm-bootstrap-system,
# capi-kubeadm-control-plane-system, caph-system all Running.
```

### A.4 Create the org namespace + Hetzner Secret + ClusterClass

```bash
# Token: if you've split into a `glossia-workloads` Hetzner project,
# read its token here so a leak in a workload cluster can't reach the
# mgmt VM. Single-project setup uses the mgmt token for both.
HCLOUD_TOKEN_WORKLOADS=$(op read 'op://glossia-production/hetzner-glossia-workloads/credential' 2>/dev/null \
  || op read 'op://glossia-production/hetzner-glossia-mgmt/credential')

kubectl create namespace org-glossia
kubectl -n org-glossia create secret generic hetzner \
  --from-literal=hcloud="$HCLOUD_TOKEN_WORKLOADS" \
  --from-literal=hcloud-ssh-key-name=glossia-ops

# If using two projects: also upload the glossia-ops public key to the
# workloads project (the ClusterClass attaches it to every VM by name).
# Single-project setup: skip — the key is already there from §A.1.
curl -sX POST https://api.hetzner.cloud/v1/ssh_keys \
  -H "Authorization: Bearer $HCLOUD_TOKEN_WORKLOADS" -H "Content-Type: application/json" \
  -d "$(jq -n --arg key "$(cat ~/.ssh/glossia-ops.pub)" '{name:"glossia-ops", public_key:$key}')" \
  || echo "(skip if 'uniqueness_error': key already in this project)"

kubectl apply -f infra/k8s/clusters/clusterclass-glossia.yaml
kubectl -n org-glossia get clusterclass glossia-hcloud
```

### A.5 etcd-snapshot CronJob

```bash
kubectl apply -f infra/k8s/mgmt/etcd-snapshot.yaml

# Pre-stage the two Secrets the CronJob expects:
#
# 1. talos-snapshotter-config — a tightly-scoped talosconfig with the
#    os:etcd:backup role only (so a leak from inside the cluster can't
#    drive talosd beyond etcd snapshots).
op document get 'talosconfig: glossia-mgmt' --vault glossia-production \
  --out-file /tmp/admin-talosconfig.yaml
talosctl --talosconfig /tmp/admin-talosconfig.yaml config new \
  --roles os:etcd:backup /tmp/snapshotter-talosconfig.yaml

# `config new` reaches talosd to mint the new client cert, so it must run
# while :50000 is still reachable from this operator machine — i.e. BEFORE
# §A.6 tightens the firewall. If you've already tightened, temporarily
# re-open :50000 to your operator IP, run, and re-tighten.
#
# `config new` only copies `endpoints` from the parent talosconfig, not
# `nodes`. `talosctl etcd snapshot` requires --nodes, so we set it here.
# Single-node mgmt cluster: nodes = endpoints.
talosctl --talosconfig /tmp/snapshotter-talosconfig.yaml config node \
  $(yq '.contexts[].endpoints[0]' /tmp/snapshotter-talosconfig.yaml)

kubectl -n mgmt-system create secret generic talos-snapshotter-config \
  --from-file=talosconfig=/tmp/snapshotter-talosconfig.yaml
shred -u /tmp/admin-talosconfig.yaml /tmp/snapshotter-talosconfig.yaml

# 2. s3-credentials — bucket-scoped keys for an S3-compatible store
#    (Tigris, Cloudflare R2, Backblaze B2, etc.). The 1Password item
#    must carry access_key_id, secret_access_key, and endpoint_url.
kubectl -n mgmt-system create secret generic s3-credentials \
  --from-literal=access_key_id="$(op read 'op://glossia-production/glossia-mgmt-etcd-snapshots-keys/access_key_id')" \
  --from-literal=secret_access_key="$(op read 'op://glossia-production/glossia-mgmt-etcd-snapshots-keys/secret_access_key')" \
  --from-literal=endpoint_url="$(op read 'op://glossia-production/glossia-mgmt-etcd-snapshots-keys/endpoint_url')"

# Smoke-test the CronJob without waiting for the next hour:
kubectl -n mgmt-system create job --from=cronjob/etcd-snapshot etcd-snapshot-manual
kubectl -n mgmt-system logs -f job/etcd-snapshot-manual
```

### A.6 Tailscale on the mgmt VM

Follow the operator + tenant bootstrap steps documented inline at the
top of [`mgmt/tailscale.yaml`](mgmt/tailscale.yaml). Once the device
shows up as `glossia-mgmt`, tighten the Hetzner firewall to drop
`:50000` from public access:

```bash
export HCLOUD_TOKEN=$(op read 'op://glossia-production/hetzner-glossia-mgmt/credential')
FW_ID=$(curl -sH "Authorization: Bearer $HCLOUD_TOKEN" \
  "https://api.hetzner.cloud/v1/firewalls?name=glossia-mgmt" | jq -r '.firewalls[0].id')
curl -sX POST "https://api.hetzner.cloud/v1/firewalls/$FW_ID/actions/set_rules" \
  -H "Authorization: Bearer $HCLOUD_TOKEN" -H "Content-Type: application/json" \
  -d '{"rules":[
    {"direction":"in","protocol":"tcp","port":"6443","source_ips":["0.0.0.0/0","::/0"],"description":"kube-apiserver"},
    {"direction":"in","protocol":"icmp","source_ips":["0.0.0.0/0","::/0"],"description":"ping"}
  ]}' | jq '.actions[].status'
```

Operators reach `talosctl` only via `--endpoints glossia-mgmt` from
this point on; CI hits `:6443` over the public IP using
`kubeconfig: glossia-mgmt`.

---

## Part B — Onboard a workload cluster

For each new cluster (e.g. `glossia-production`, or per-tenant
clusters added later).

### B.1 Author the Cluster CR

Each workload cluster is a `Cluster` CR in topology mode referencing
the `glossia-hcloud` ClusterClass. The production CR is at
[`clusters/cluster-production.yaml`](clusters/cluster-production.yaml);
copy it for new clusters and adjust `metadata.name`, replica counts,
machine types, and any per-pool labels.

### B.2 Apply the Cluster CR

```bash
export KUBECONFIG=~/.kube/glossia-mgmt.yaml

kubectl apply -f infra/k8s/clusters/cluster-production.yaml
kubectl -n org-glossia get cluster glossia-production -w
# Ready=True once control plane is up. ~5–10 min cold start.
```

Fetch the workload cluster kubeconfig:

```bash
kubectl -n org-glossia get secret glossia-production-kubeconfig \
  -o jsonpath='{.data.value}' | base64 -d > ~/.kube/glossia-production.yaml
chmod 600 ~/.kube/glossia-production.yaml

KUBECONFIG=~/.kube/glossia-production.yaml kubectl get nodes
# Initially expect 1 control-plane node; the rest follow as caph
# provisions them. NotReady is expected — Cilium isn't installed yet.
```

### B.3 Bootstrap the workload (Cilium → HCCM → CSI → ESO → platform)

Order matters. Cilium first (no kube-proxy DaemonSet exists; Service
IPs don't work without it). HCCM next so LBs reconcile. Then CSI, ESO,
and the platform chart.

```bash
export KUBECONFIG=~/.kube/glossia-production.yaml

# 1. Cilium. k8sServiceHost is the Cluster's controlPlaneEndpoint.host.
API_HOST=$(KUBECONFIG=~/.kube/glossia-mgmt.yaml kubectl -n org-glossia \
  get cluster glossia-production -o jsonpath='{.spec.controlPlaneEndpoint.host}')
helm repo add cilium https://helm.cilium.io
helm upgrade --install cilium cilium/cilium \
  -n kube-system --version 1.18.5 \
  -f infra/k8s/mgmt/bootstrap/cilium-values.yaml \
  --set k8sServiceHost="${API_HOST}" \
  --set k8sServicePort=443

kubectl -n kube-system rollout status ds/cilium
# Cilium enables WireGuard transparent encryption for node-to-node pod traffic.

# 2. HCCM. Region is the Cluster CR's region variable.
REGION=$(KUBECONFIG=~/.kube/glossia-mgmt.yaml kubectl -n org-glossia \
  get cluster glossia-production -o jsonpath='{.spec.topology.variables[?(@.name=="region")].value}' | tr -d '"')
helm repo add hcloud https://charts.hetzner.cloud
helm upgrade --install hccm hcloud/hcloud-cloud-controller-manager \
  -n kube-system \
  -f infra/k8s/mgmt/bootstrap/hccm-values.yaml \
  --set "env.HCLOUD_LOAD_BALANCERS_LOCATION.value=${REGION}"

# 3. hcloud-csi.
helm upgrade --install hcloud-csi hcloud/hcloud-csi \
  -n kube-system \
  -f infra/k8s/mgmt/bootstrap/hcloud-csi-values.yaml

# 4. Platform chart: cert-manager, ingress-nginx, external-dns, ESO,
#    and Rook and Ceph object storage when enabled by the provider overlay.
#    The CNPG / ClickHouse / Barman-plugin subcharts ship with the chart
#    but default OFF — those are cluster-scoped operators managed
#    standalone here (step 6), so the chart must not double-install them.
APP_NS=glossia
kubectl create namespace "${APP_NS}" --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace platform --dry-run=client -o yaml | kubectl apply -f -

# Rook's CSI/node and OSD pods need privileges that Talos's restricted
# namespace default blocks. This is scoped to the platform namespace where
# the Rook operator and Ceph cluster are installed.
kubectl label --overwrite ns platform \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged

kubectl -n platform create secret generic cloudflare-api-token \
  --from-literal=api-token="$(op read 'op://glossia-production/cloudflare-glossia-dns/credential')" \
  --dry-run=client -o yaml | kubectl apply -f -

# charts/ and Chart.lock are gitignored — deps resolve at install time.
helm repo add rook-release https://charts.rook.io/release
helm dependency update infra/helm/platform
helm upgrade --install platform infra/helm/platform \
  -n platform \
  -f infra/helm/platform/values-hetzner.yaml

# cert-manager + ESO install in the same release; if a cold first apply
# reports a webhook not-ready it is self-healing — re-run the upgrade
# once cert-manager's Deployment is Ready, or wait a reconcile cycle.

# Rook and Ceph object storage readiness. Ceph can take several minutes
# while Hetzner volumes attach and storage daemons initialize.
kubectl -n platform wait --for=condition=Ready cephcluster/rook-ceph --timeout=30m
kubectl -n platform get cephobjectstore glossia-s3
kubectl -n "${APP_NS}" get objectbucketclaim glossia-s3
kubectl -n platform get networkpolicy glossia-s3-rgw-ingress
kubectl -n platform get cephobjectstore glossia-releases-s3
kubectl -n platform get objectbucketclaim glossia-releases
kubectl -n platform get ingress glossia-releases
kubectl -n platform get networkpolicy glossia-releases-s3-rgw-ingress

# The app bucket is intentionally cluster-internal. The app points at the
# in-cluster Rook Ceph Object Gateway service, and the Kubernetes
# NetworkPolicy is enforced by Cilium.
#
# Release artifacts use a separate public object gateway at
# https://releases.glossia.ai. The bucket name is also `releases.glossia.ai`,
# so public artifact paths are rooted at the host:
# https://releases.glossia.ai/cli/<version>/glossia-linux-x64.tar.gz.
# A Helm hook job applies anonymous download access to that bucket; write
# access stays scoped to the generated `glossia-releases` bucket credentials.
#
# After the first bucket claim reconciliation, copy the generated write
# credentials into the `glossia-releases` 1Password item in the
# `glossia-production` vault. The release workflow reads these fields directly
# and masks them before signing uploads:
kubectl -n platform get secret glossia-releases \
  -o jsonpath='{.data.AWS_ACCESS_KEY_ID}' | base64 --decode
kubectl -n platform get secret glossia-releases \
  -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}' | base64 --decode
op item edit glossia-releases --vault glossia-production \
  AWS_ACCESS_KEY_ID[text]="<generated access key>" \
  AWS_SECRET_ACCESS_KEY[password]="<generated secret key>"

# 5. ESO ClusterSecretStore (1Password). Use a DEDICATED 1Password
#    Service Account with READ on only the glossia-production vault, so
#    a leak in the workload cluster can't reach the rest of the org's
#    1Password. Store its token as item `onepassword-sa-glossia-production`
#    (field `credential`) in that vault.
#
#    Apply the manifest FIRST — it creates the `onepassword` namespace
#    and the ClusterSecretStore. The store reports NotReady until the
#    token Secret below exists; that is expected, not an error.
VAULT_NAME=glossia-production envsubst < infra/k8s/mgmt/bootstrap/onepassword-secretstore.yaml | kubectl apply -f -

kubectl -n onepassword create secret generic onepassword-sa-token \
  --from-literal=token="$(op read 'op://glossia-production/onepassword-sa-glossia-production/credential')" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl get clustersecretstore onepassword
# Expect READY=True (re-check after a few seconds; ESO revalidates).

kubectl -n platform get externalsecret mail-relay
kubectl -n platform get networkpolicy mail-relay-ingress
kubectl -n platform get ciliumnetworkpolicy mail-relay-egress
kubectl -n platform rollout status deployment/mail-relay --timeout=5m
# The relay Deployment stays pending until the `onepassword` store projects
# the upstream mail provider credentials into the platform namespace.

# 6. Database operators — managed standalone (NOT via the platform
#    chart, so each has exactly one owner). The CNPG Barman plugin is
#    what enables Postgres backups; it must sit beside the CNPG operator
#    in cnpg-system. cert-manager (step 4) must be Ready first — the
#    plugin's mTLS cert depends on it.
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cloudnative-pg cnpg/cloudnative-pg \
  --version 0.28.2 -n cnpg-system --create-namespace
helm upgrade --install plugin-barman-cloud cnpg/plugin-barman-cloud \
  --version 0.6.0 -n cnpg-system
# OCI chart — needs a logged-in helm registry even for the public pull:
#   echo "$GH_PAT" | helm registry login ghcr.io -u <user> --password-stdin
helm upgrade --install clickhouse-operator \
  oci://ghcr.io/clickhouse/clickhouse-operator-helm \
  --version 0.0.4 -n clickhouse-operator-system --create-namespace

kubectl get crd | grep -E 'objectstores.barmancloud|clusters.postgresql.cnpg|clickhouseclusters.clickhouse'
# Expect all three present before deploying the Glossia app chart.
```

### B.4 Tailscale Kubernetes control-plane proxy

The workload cluster starts with a public Hetzner control-plane load
balancer so bootstrap and automation have an initial path in. Before
closing that endpoint, install the Tailscale proxy in each workload
cluster and cut operator plus GitHub Actions kubeconfigs over to the
tailnet path.

Keep `infra/tailscale/policy.hujson` mirrored into the Tailscale
Access controls page. The policy defines the proxy tags, the GitHub
Actions tag, and the access grants for Transmission Control Protocol
port 443.

Create tagged, pre-approved auth keys:

- Production proxy: one-off is enough, tagged
  `tag:glossia-k8s-production`, stored in 1Password item
  `tailscale-apiserver-proxy-production`, field `authkey`.
- Observability proxy: one-off is enough, tagged
  `tag:glossia-k8s-observability`, stored in the
  `glossia-observability` vault as item
  `tailscale-apiserver-proxy-observability`, field `authkey`.
- GitHub Actions: reusable and ephemeral, tagged
  `tag:glossia-github-actions`, stored as the production environment
  secret `TAILSCALE_AUTHKEY`.

The long-running proxy key is only needed for the first join. The proxy
writes its Tailscale node identity into `tailscale-apiserver-state`, and
`TS_AUTH_ONCE=true` makes restarts use that state instead of consuming
another auth key. If that state Secret is deleted, create and store a
fresh key before the next restart.

Install the production proxy after External Secrets Operator is Ready:

```bash
export KUBECONFIG=~/.kube/glossia-production.yaml

kubectl create namespace tailscale --dry-run=client -o yaml | kubectl apply -f -
kubectl label --overwrite namespace tailscale \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged

helm upgrade --install tailscale-apiserver-proxy \
  infra/helm/tailscale-apiserver-proxy \
  --namespace tailscale \
  --values infra/helm/tailscale-apiserver-proxy/values-production.yaml

kubectl -n tailscale rollout status deployment/tailscale-apiserver-proxy \
  --timeout=5m
tailscale ping glossia-production-kube
```

Use `values-observability.yaml` instead when installing into the
observability cluster:

```bash
helm upgrade --install tailscale-apiserver-proxy \
  infra/helm/tailscale-apiserver-proxy \
  --namespace tailscale \
  --values infra/helm/tailscale-apiserver-proxy/values-observability.yaml

kubectl -n tailscale rollout status deployment/tailscale-apiserver-proxy \
  --timeout=5m
tailscale ping glossia-observability-kube
```

After the proxy is reachable, rewrite each operator and automation
kubeconfig so `clusters[].cluster.server` points at the Tailscale name.
Keep `clusters[].cluster.certificate-authority-data`, and set
`clusters[].cluster.tls-server-name` to `kubernetes`, because the proxy
forwards raw Kubernetes traffic and the Kubernetes
[Application Programming Interface server](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
still presents its own certificate.

Do not remove public Kubernetes access until both checks pass:

```bash
KUBECONFIG=/tmp/operator-tailnet-kubeconfig.yaml kubectl get nodes
KUBECONFIG=/tmp/github-actions-tailnet-kubeconfig.yaml kubectl -n glossia get pods
```

GitHub Actions also needs to join the tailnet before any deploy step
uses the proxied kubeconfig. The deploy workflows run the Tailscale
GitHub Action with a `TAILSCALE_AUTHKEY` production environment secret
before writing the kubeconfig file.

The current Cluster Application Programming Interface Provider Hetzner
control-plane load balancer schema does not expose source ranges in the
workload cluster manifest. Treat final public-endpoint closure as a
separate cutover after the proxy path is proven and the remaining
automation has moved behind Tailscale.

### B.5 GitHub Actions ServiceAccount and kubeconfig secret

```bash
APP_NS=glossia

sed "s/__NAMESPACE__/${APP_NS}/g" infra/k8s/mgmt/ci-service-account.yaml \
  | KUBECONFIG=~/.kube/glossia-production.yaml kubectl apply -f -

SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA=$(kubectl -n "$APP_NS" get secret github-actions-deployer-token -o jsonpath='{.data.ca\.crt}')
TOKEN=$(kubectl -n "$APP_NS" get secret github-actions-deployer-token -o jsonpath='{.data.token}' | base64 -d)

cat > /tmp/ci-kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: glossia-production
    cluster:
      server: $SERVER
      certificate-authority-data: $CA
      tls-server-name: kubernetes
contexts:
  - name: ci
    context:
      cluster: glossia-production
      namespace: $APP_NS
      user: github-actions-deployer
users:
  - name: github-actions-deployer
    user:
      token: $TOKEN
current-context: ci
EOF

KUBECONFIG=/tmp/ci-kubeconfig.yaml kubectl -n "$APP_NS" get pods   # sanity-check
base64 < /tmp/ci-kubeconfig.yaml | gh secret set KUBECONFIG \
  --env production --repo glossia/glossia
shred -u /tmp/ci-kubeconfig.yaml
```

The token is persistent; revoke by deleting the
`github-actions-deployer-token` Secret, or rotate by recreating it.

### B.6 First deploy

Hand the workload cluster kubeconfig over to whichever release
workflow deploys the Glossia app chart. Smoke test with:

```bash
curl -v https://glossia.ai/ready
```

### B.7 Database backup storage

Postgres (CNPG, via the Barman Cloud plugin installed in §B.3) and
ClickHouse (a `clickhouse-backup` CronJob) back up to a **dedicated
object-storage bucket with its own credentials** — deliberately *not*
the bucket/keys the app uses for its own object storage, so a
compromise or fat-fingered policy on one can't take out the backups of
the other. Use a different provider or at least a different account +
region from the app's `S3_*` store for real DR isolation.

Provision once per workload cluster:

1. Create a private bucket (e.g. `glossia-production-db-backups`) on an
   S3-compatible store, with a versioning/object-lock + lifecycle
   policy matching your retention target.
2. Mint **bucket-scoped** access keys (no broader account access) and
   save them to 1Password as item `glossia-db-backups-keys` in the
   `glossia-production` vault, with fields: `access_key_id`,
   `secret_access_key`, `endpoint_url`, `region`, `bucket`.

That is all the infra side needs — the bucket + the 1Password item.
The Glossia application chart consumes them: an ESO `ExternalSecret`
projects the keys into the app namespace, and the chart's
`ObjectStore` + `ScheduledBackup` (Postgres) and `clickhouse-backup`
CronJob (ClickHouse) point at this bucket. Enabling/scheduling/retention
all live in the app chart's values, not here.

### B.8 Operator dashboard (Grafana)

Cluster-level observability — one Grafana per workload cluster, wired
straight to the in-cluster Postgres + ClickHouse the Glossia app chart
provisions. Values:
[`observability/grafana-values.yaml`](observability/grafana-values.yaml).

```bash
export KUBECONFIG=~/.kube/glossia-production.yaml

# Admin login. existingSecret keys must be admin-user / admin-password
# (see grafana-values.yaml). Password lives in the per-env vault.
kubectl -n platform create secret generic grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$(op read 'op://glossia-production/kubernetes/GF_SECURITY_ADMIN_PASSWORD')" \
  --dry-run=client -o yaml | kubectl apply -f -

# Datasource password injected into datasources.yaml via envFromSecret
# as ${GRAFANA_POSTGRES_PASSWORD}; it is the app's Postgres password.
kubectl -n platform create secret generic grafana-datasource-env \
  --from-literal=GRAFANA_POSTGRES_PASSWORD="$(op read 'op://glossia-production/kubernetes/POSTGRES_PASSWORD')" \
  --dry-run=client -o yaml | kubectl apply -f -

helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install grafana grafana/grafana \
  -n platform \
  -f infra/k8s/observability/grafana-values.yaml
```

Reachable at `https://data.glossia.ai` once external-dns + cert-manager
settle. The datasource URLs assume the app runs in namespace `glossia`;
override them in `grafana-values.yaml` if you deploy elsewhere.

---

## Teardown

```bash
KUBECONFIG=~/.kube/glossia-mgmt.yaml kubectl -n org-glossia delete cluster glossia-production
```

caph drains + deletes the nodes and releases the Hetzner LB and
servers.

---

## Troubleshooting crib

**`Cluster` stuck in `InfrastructureReady: false`**
```bash
kubectl -n org-glossia describe cluster glossia-production
kubectl -n org-glossia get hetznercluster,hcloudmachine,machine
```
Most often a bad `hetzner` Secret in `org-glossia` (token typo, missing
permission). The Secret must hold `hcloud=<token>` and
`hcloud-ssh-key-name=<key>` (the SSH key uploaded to the workload
Hetzner project).

**`HCloudMachine` stuck with `ServerCreateFailedIrrecoverableError` / "unsupported location"**
Hetzner per-DC capacity or server-type stock. Pick a different machine
type (patch the Cluster CR's relevant variable) and `kubectl delete
machine` the stuck ones so caph reconciles. For account-level limits,
check `https://console.hetzner.cloud/your-account/limits`.

**LoadBalancer stuck in `<pending>`**
HCCM needs the `load-balancer.hetzner.cloud/location` annotation on
the Service to pick a DC. The platform chart sets it; verify with
`kubectl describe svc`. CCM logs:
```bash
kubectl -n kube-system logs -l app.kubernetes.io/name=hcloud-cloud-controller-manager
```

**Pods can't resolve external DNS**
kubelet's `resolvConf` must point at `/run/systemd/resolve/resolv.conf`,
not the default `/etc/resolv.conf` (a 127.0.0.53 stub unreachable from
pod netns). The ClusterClass already sets this — confirm via:
```bash
kubectl debug node/<node> -it --image=busybox -- chroot /host cat /var/lib/kubelet/config.yaml | grep resolvConf
```

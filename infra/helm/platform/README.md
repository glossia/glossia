# Platform ingress and client IPs

The generic chart does not require PROXY protocol. The Hetzner overlay enables
it on **both** the TCP load balancer and ingress-nginx:

- `load-balancer.hetzner.cloud/uses-proxyprotocol: "true"` on the Service tells
  Hetzner's cloud controller to configure the sender.
- `ingress-nginx.controller.config.use-proxy-protocol: "true"` configures the
  nginx receiver. With `compute-full-forwarded-for`, nginx appends the PROXY
  source address rather than the load balancer's address to `X-Forwarded-For`.

A chart validation rejects mismatched Hetzner sender/receiver settings. This
prevents configuration drift; it does **not** make their runtime updates atomic.
The observability overlay inherits the same pair when layered after Hetzner.

## Why this matters

Without PROXY protocol, a TCP load balancer terminates the incoming connection
and opens another to nginx. It cannot add HTTP headers inside the TLS stream,
so nginx otherwise forwards the load balancer's address as the client IP.
`externalTrafficPolicy: Local` preserves the address of that connection's peer,
not the original visitor hidden behind it.

The October 2026 analytics investigation confirmed this on production: the
collector attributed most Tuist events to the German load balancer, including
visitors across 166 browser timezones. Since the daily visitor hash uses IP and
User-Agent, unrelated visitors using the same browser were also merged.

Cloudflare is independent of the LB-to-nginx PROXY connection. With proxied DNS,
Hetzner sends the Cloudflare edge's address in PROXY, while Cloudflare supplies
`CF-Connecting-IP` / `X-Forwarded-For`. With DNS-only records, Hetzner sends the
visitor's address directly. Cloudflare does not need to emit PROXY protocol.

Glossia reads nginx's overwritten `X-Real-IP` only from private ingress peers,
not the client-controlled first `X-Forwarded-For` entry. Direct public socket
peers cannot supply either address. Restrict direct pod access to trusted
workloads because private peers are the ingress trust boundary.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER` and
`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER` are both disabled by default. They
control the `CF-Connecting-IP` and `CF-IPCountry` overrides independently. Do
not enable either merely to fix this incident: authenticate Cloudflare or strip
forged headers on direct-origin requests before trusting its edge metadata.
Preserving forwarded HTTP headers does not authenticate them. Every private
HTTP proxy that can reach the application must overwrite or strip a caller's
`X-Real-IP` before forwarding it. The production Pomerium access route strips
`X-Real-IP`, `CF-Connecting-IP`, and `CF-IPCountry`. Without an authoritative
client address it intentionally falls back to its socket peer, so requests
through that authenticated route still share an IP-based bucket.

### Shared Discourse ingress

`community.glossia.ai` uses Cloudflare on this same load balancer. Rails
currently attributes its visitors to the LB's public IP; after the PROXY
cutover it will instead see Cloudflare edge addresses as the rightmost public
hop in `X-Forwarded-For`. Correct forum attribution requires a separate
Discourse trusted-proxy configuration. This PR does not silently change its
DNS or Rails trust policy. Include the forum in availability checks, and do
not treat its existing IP-based rate limits as accurate.

## Existing-cluster cutover

**Schedule a maintenance window before merging a change to these settings.**
The production platform HelmRelease follows this repository through Flux, so
merging can initiate the cutover without a separate manual deploy. Helm updates
the ConfigMap and Service together, but nginx reload and Hetzner cloud-controller
reconciliation are asynchronous. During a mismatch, HTTP and TLS requests can
fail. Neither two nginx replicas nor Helm rollback makes that interval atomic.

1. Before merging, have an operator suspend the management cluster's
   `HelmRelease/platform` in namespace `org-glossia`. Record the current Service
   annotation and controller ConfigMap, and check the ingress and Hetzner
   cloud controllers are healthy. Arrange a tailnet/control-plane access path
   independent of public ingress. Confirm nginx's NodePorts are reachable only
   by the LB or trusted infrastructure: PROXY protocol itself is not
   authenticated. Review ingress-log retention because those logs will start
   recording real client addresses instead of the load balancer address.
2. After merging, wait for the accompanying Glossia `ClientIP` application
   change to finish deploying. It selects nginx's canonical address, but until
   PROXY is enabled nginx itself still trusts inbound `X-Forwarded-For` as
   before. Immediately before resuming, review a `helm diff upgrade` against
   the live release using the exact Git revision and complete ordered
   `valuesFiles` from
   `infra/k8s/workload-platforms/glossia-production/platform-helmrelease.yaml`.
   Confirm only the expected ingress Service annotation and ConfigMap key
   change; investigate any accumulated platform drift, particularly storage
   changes. Preserve the object-storage overlays. Resume the platform
   HelmRelease in the maintenance window to apply the complete Hetzner
   overlay, never just one setting. Check other clusters using the same
   overlay before deploying them as well.
3. Observe both reconciliations. Confirm the Service annotation and the nginx
   ConfigMap both read `"true"`, nginx has reloaded its generated configuration
   with `listen ... proxy_protocol`, and the Hetzner LB has PROXY enabled on
   its targets. The Kubernetes annotation alone does not confirm LB convergence.
   Also confirm `.status.loadBalancer.ingress[].ipMode` is `Proxy`, not `VIP`.
   HCCM v1.31.0 (used in production) sets this when PROXY is enabled. This
   prevents Cilium from short-circuiting in-cluster requests directly to nginx
   without the LB's PROXY header. Verify HTTPS from an existing in-cluster
   workload as well as from outside. If the controller leaves `VIP` set or
   in-cluster HTTPS fails, roll back both settings as described below rather
   than leaving an ingress that internal clients cannot reach.
4. Check public HTTPS, the collector route, and all other hosts sharing this
   ingress. Check nginx logs for `broken header` / PROXY errors. For DNS-only
   traffic, nginx access logs should now show visitor addresses rather than
   the same LB address for every request.
5. Generate controlled visits from two known networks and inspect only the
   newly collected countries and visitor IDs. Confirm geolocation no longer
   collapses worldwide timezones into Germany. Do not add persistent raw-IP or
   User-Agent logging to validate the fix.

If the migration fails, revert **both** settings to `"false"` and reconcile the
full release. Explicitly set the Service annotation to `"false"`: removing it
can leave the previous PROXY setting active in Hetzner. Observe both systems
converge again; rollback has the same temporary mismatch risk. The chart guard
permits an explicit matched false/false rollback.

Historical country attribution and unique-visitor counts cannot be repaired
from stored events because the original IPs were deliberately not persisted.
Mark the pre-cutover country and visitor-derived reports as unreliable rather
than guessing countries from browser language or timezone. Existing event
counts remain event counts; this fix does not change them to unique visitors.

## Regression checks

After resolving chart dependencies:

```sh
helm dependency build infra/helm/platform
ruby infra/helm/platform/test/client_ip_test.rb
```

The tests render generic, Hetzner, production Flux, and observability values,
assert the resulting sender/receiver configuration, and reject either one-sided
change. The Infra workflow runs them alongside Helm lint and rendering checks.
`app/test/glossia_web/client_ip_test.exs` covers the private ingress boundary,
IPv4-mapped IPv6, spoofed forwarding headers, and explicit Cloudflare trust.

# Control-plane high availability

The production cluster runs a single control-plane node, so there is one etcd
member and one API server. Losing that node is a full control-plane outage.
This is the largest availability gap in the platform, but it cannot be closed
by simply raising `controlPlane.replicas`, and the reason is important.

## Why it is not a replica bump

`infra/k8s/clusters/workloads/production/cluster.yaml` pins the API endpoint to
the control-plane node's own address:

```yaml
controlPlaneEndpoint:
  host: 178.105.114.211   # the single control-plane node's IP
  port: 6443
```

with a matching `clusterEndpointHost` variable. The comment there explains the
intent: public API access was closed after the Tailscale proxy cutover, so
nodes and CAPI talk to the control-plane server's address directly "until this
cluster is rebuilt with a private Hetzner network."

A `controlPlaneLoadBalancer` exists (`128.140.24.27`) but is not the endpoint.

Two problems follow:

1. **The endpoint is a single point of failure regardless of replica count.**
   Even with three control-plane nodes, every kubelet, every kube-proxy, and
   CAPI itself still reach the API at `178.105.114.211`. If that one node dies,
   the API is unreachable even though two other control planes are healthy.

2. **The 1 -> 2 etcd transition has no fault tolerance.** Scaling from one to
   three members passes through two, and a two-member etcd loses quorum if
   either member is unavailable. A failure mid-join can wedge the API. Because
   the only access to this cluster is *through* that API (Tailscale-proxied),
   a wedged API leaves no in-band recovery path.

## The correct procedure (needs a maintenance window and console access)

Do not attempt this remotely-only. Have Hetzner console access to the
control-plane server before starting.

1. **Give the API a stable endpoint that is not a node IP.** Either point
   `controlPlaneEndpoint` at the existing control-plane load balancer
   (`128.140.24.27`) or, preferably, stand up the private-network endpoint the
   cluster comment anticipates. The kube-apiserver serving certificate must
   include that address in its SANs; regenerate it if not.

2. **Reconfigure the existing node and CAPI to use the new endpoint** before
   adding members. This is the risky, cluster-rebuild-shaped step and is why
   the work has been deferred.

3. **Only then raise `controlPlane.replicas` to 3.** With a stable endpoint in
   front, the KubeadmControlPlane can add the second and third members and the
   endpoint survives any single node loss. Add them one at a time and confirm
   etcd is healthy (`etcdctl endpoint health`) between each.

Until steps 1 and 2 are done, leaving the control plane at one replica is the
safer state: a single-member etcd has no quorum to lose, and node remediation
is bounded by the health-check timeouts already set in the ClusterClass.

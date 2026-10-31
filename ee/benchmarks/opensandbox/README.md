# OpenSandbox / Firecracker evaluation

Enterprise-only research, not a production sandbox adapter or a measured resume
benchmark. The obsolete Python Firecracker harness and its harness-only tests
were removed rather than maintaining a second port. It was never executed through
real Firecracker pause/resume; no VM latency, memory-release, density, or migration
claim follows from this evaluation.

The active standalone Elixir experiment is
[`../gvisor`](../gvisor/README.md). It uses gVisor `systrap`, **not Firecracker**.
The shared Node app, CDP probe, and launch fixture remain in
[`workload/`](workload/) and are used by that benchmark. They are deliberately
small fixtures, not representative large repositories.

## Inspected upstream pins

- OpenSandbox release-1.2.0:
  [`13dcd3972a849aa3af9856e2546d0af313fcc824`](https://github.com/opensandbox-group/OpenSandbox/commit/13dcd3972a849aa3af9856e2546d0af313fcc824).
- Its `manifests/third-party/fast-sandbox.commit`:
  [`4c389ae1b0e3823d59eee2ade4fba36682984590`](https://github.com/opensandbox-group/fast-sandbox/commit/4c389ae1b0e3823d59eee2ade4fba36682984590).

The evaluated path was native Fast Sandbox snapshots with the Kubernetes control
plane, not the experimental OverlayBD stack or a container fallback. Upstream
pool defaults (512 MiB, 128 PIDs) were too small for the intended app + Chromium
fixture. The proposed two-guest allocation was 2 vCPUs / 4 GiB per guest plus
control-plane/build overhead, not a measured minimum.

## Host constraints

This pinned Firecracker path needs a disposable **Linux x86_64 KVM host**, root
access, kernel ≥5.10, cgroup v2, working `/dev/kvm` and `/dev/net/tun`, and a
writable XFS StateRoot with reflinks. CPU flags or a device node alone are not
proof: a future preflight must actually create a VM with `KVM_CREATE_VM`. There
is no emulation or container fallback. Upstream integration setup changes host
networking and mounts and requires explicit approval, as do publishing images
and provisioning resources. Never use the production cluster.

**Ordinary Hetzner Cloud VMs cannot host this experiment**: Hetzner's
[Cloud FAQ](https://docs.hetzner.com/cloud/servers/faq/) says nested virtualization
is unavailable. Hetzner bare metal can host multiple Firecracker VMs; a cloud
provider must expose working KVM. The gVisor alternative does not require KVM.

## Findings and evidence limits

Local fixture validation on an ARM Mac exercised the extracted actual preview
driver with Chromium: an edited heading, click counter 0 → 1, unchanged
app/browser nonces and draft bytes, and a visually inspected fresh JPEG. It did
not prove Linux namespace behavior or VM restoration. An earlier navigation
timeout followed by a successful isolated-port run did not establish a fix for
intermittent driver failures.

A future Firecracker benchmark must independently prove released host VMMs,
published checkpoints and cleared placement while idle, replacement VMMs after
resume, unchanged guest boot/process and memory-only identities, exact draft
bytes, a fresh input-acknowledging JPEG, and cleanup. Retained disks, paused
resident VMs, and cold restarts do not count. The proposed median ≤2 seconds /
every sample ≤5 seconds gate was a target, never a measured result. The real
driver's 850-second watchdog also limits long-idle experiments; do not remove
security/time limits to obtain a passing score.

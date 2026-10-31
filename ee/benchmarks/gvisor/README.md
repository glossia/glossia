# Kubernetes-reconciled preview checkpoint experiment

Enterprise-only, opt-in tooling. **Not a production operator or a hostile-code
security boundary.** Use a disposable dedicated Linux VM/cluster, never the
application cluster. Nothing here changes production Flux or the editor runtime.

## What this evaluates

Two app + Chromium sessions run inside separate gVisor sandboxes on one host.
`SandboxSession` custom resources request `Running` or `Suspended`. A trusted
privileged runner reconciles those requests, journals transitions on its PVC,
and publishes evidence with the observed Kubernetes generation.

The runtime uses `systrap`, not KVM. This is the candidate for ordinary Hetzner
Cloud VMs, where nested virtualization is unavailable. This is **not** the
OpenSandbox/Firecracker backend in `../opensandbox`; that experiment requires
KVM and therefore a different host, such as bare metal.

The benchmark proves cooperative checkpoint/resume of a fixed fixture, not
arbitrary repositories or arbitrary mid-command snapshots:

1. Extract the actual `PreviewBrowser.source()` JavaScript. Inject only a
   benchmark-specific pause handshake at its main-loop/screenshot boundary.
   Fetch event handlers stay active; this is not global CDP quiescence.
2. Run the fixture app and Chromium in the **same** gVisor sandbox, using
   `--platform=systrap --network=none --overlay2=none --ignore-cgroups=true`.
   Their loopback/CDP connection belongs to the checkpoint, not the host.
3. Deliver clicks, validate exact draft bytes and process/memory identities,
   and wait for the main-loop pause acknowledgement.
4. Checkpoint, delete the original runtime, verify its Sentry/gofer processes
   disappeared, then freeze the matching ordinary filesystem generation.
   Only a durable `complete.json` makes a checkpoint usable.
5. Clone that filesystem into a new writable bundle and restore into a fresh
   runtime ID with `--background=false`. Release the saved pause request.
6. Require a screenshot sequence beyond the final stopped-frame watermark and
   independently evaluate the browser through CDP. Preserve the guest boot ID,
   driver/server/Chromium identities, server/browser memory-only nonces, clicks,
   and draft bytes. Challenge the restored browser with another click.

`mix run exercise.exs` runs up to three cycles on both sessions, replaces the
outer runner Pod during the first suspended interval, and leaves both sessions suspended.
It operates through the Kubernetes CR interface and refuses a non-loopback k3s
API. It captures JSON evidence and JPEGs; `result.json` must say `success: true`.

This directory is a standalone Elixir Mix project using Jason, MuonTrap, and Req, not
the full Glossia application. `reconcile.exs` starts the controller with
`flock --nonblock /state/writer.lock mix run reconcile.exs` in the runner. The
exercise independently inspects suspended processes through `kubectl exec` and
`mix run --no-start`, rather than trusting the CR status alone. Shared Node
fixtures remain in [`../opensandbox/workload`](../opensandbox/workload).

## Elixir validation (2026-10-31)

The replacement image ran Elixir 1.18.3 / OTP 27 on the same disposable ARM64
Ubuntu VM, with no `/dev/kvm`. Source, lockfile, generated driver, and runtime
hashes were checked against the running image.

- Eight coordinated restores passed: three cycles on two sessions with
  3-second idle periods, followed by one cycle with a 30-second idle period.
  Both runs replaced the outer runner Pod while suspended. Memory identities,
  exact draft bytes, stopped-process absence, fresh frames, and subsequent
  clicks were checked through the real Kubernetes/gVisor/browser stack.
- Fresh-frame median was **4.35 seconds** for the first six restores and
  **11.84 seconds** for the two 30-second-idle restores. The latter spent about
  10 seconds copying filesystems. Across all eight: median **4.68 seconds**,
  range **3.57–11.97 seconds**; runtime-only restore median **0.74 seconds**.
  These runs do not isolate idle duration as the cause of the timing difference.
- Shared evidence/command/persistence tests passed on macOS and in the Linux
  image. A deliberate stale-frame acceptance mutation failed the freshness test.
- Fresh Elixir controls passed for 33 queued clicks, an untouched second
  session, duplicate-writer rejection, three API admission rejections, and
  denied secret access. Injecting a CLI failure after the real pause
  acknowledgement recovered from frame 18 to 19 with memory/draft continuity.
  A failure before checkpointing preserved both live sandbox processes and the
  same browser memory with all 33 clicks. These controls used the real API and
  browser, with temporary `runsc` wrappers at the failing command boundary.
- A later control attempt was interrupted by Kubernetes disk-pressure eviction
  after repeated runs accumulated about 26 GiB of retained generations. It is
  not counted as a restore result. Removing obsolete disposable generations,
  while retaining each latest committed checkpoint, restored free disk space.
  Kubelet had also garbage-collected the locally loaded image; it was reimported
  with the same digest before the successful fresh-session controls above.

This validates the standalone Elixir benchmark, not a production editor adapter.
Filesystem snapshot/clone strategy and bounded checkpoint retention remain
necessary before this can be a practical production session lifecycle.

### Bounded-reconcile follow-up (2026-10-31)

The measurements above predate the backlog-interruption fix. New controls on the
same disposable VM used the updated reconciler compiled over the retained local
image, with matching source hashes. The full eight-restore run was not repeated.
The four shared Mix tests passed on macOS and in the Linux image.

- A 65-click request published `ApplyingInput` at 32, then generation-matching
  `Running` with exactly 65 acknowledged clicks.
- A 10,000-click backlog was interrupted by `Suspended` in 8 seconds, at 129
  committed clicks, with no sandbox processes remaining. Resume advanced to 161
  while preserving draft bytes, process identities, and memory-only nonces.
- Deleting another 10,000-click session completed in 5 seconds at 64 committed
  clicks. Both sessions' finalizers completed without draining their backlogs;
  independent process checks confirmed deletion.
- Injecting a probe failure after guest acknowledgement left durable intent for
  10,000 clicks and an uncommitted 32-click batch. Suspension settled only those
  32 clicks, without replay, in 4 seconds and retained the remaining backlog.

## Historical Python baseline (2026-10-31)

The following measurements and controls were collected with the earlier Python
harness. They are retained as a historical baseline, **not validation or timing
evidence for the Elixir port**; the fresh Elixir results are above.

On a disposable ARM64 Ubuntu 24.04 VM (4 vCPUs, 8 GiB, kernel 6.8, no `/dev/kvm`):

- Eight coordinated restores passed: three cycles with two sessions and 3-second
  idle periods, then one cycle with two sessions and a 30-second idle period.
  Both runs replaced the outer runner Pod during the first suspended interval.
- Median fresh-frame latency: **4.49 seconds**, range **2.93–6.46 seconds**.
  Median runtime-only restore: **0.67 seconds**. Ordinary ext4 filesystem copies
  were a significant part of the remaining latency.
- A subsequent rebuild verified the running image's source/binary hashes and
  restored both existing sessions again. Final CR generations matched their
  Suspended statuses, with no original sandbox processes remaining.
- Additional controls covered 33 queued clicks without loss, an untouched second
  session, duplicate-writer rejection, API admission, and denied secret access.
  Lifecycle fault injection with real gVisor/Chromium but a replaced API boundary
  verified quiescence recovery and live-memory preservation on failed checkpoint.
  Reintroducing the stale recovery watermark made that control fail as expected.

An earlier run **without** the main-loop handshake passed its first cycle but
failed its next cycle with `browser_timeout_Page.captureScreenshot`. The exact
cause remains unproven. Do not interpret the coordinated results as arbitrary
mid-command snapshot reliability. These are local VM results, not Hetzner
performance or production-readiness evidence.

## Prerequisites

- Dedicated Linux 5.6+ VM, native ARM64 or x86-64, at least 4 vCPUs / 8 GiB RAM.
  No `/dev/kvm` is needed. Do not mix architectures or CPU families for snapshots.
- Disposable k3s with local kubeconfig, default StorageClass, and administrator
  access. The experiment was exercised with k3s `v1.37.1+k3s1`.
- Rootful nerdctl/containerd with BuildKit, `umoci`, `tar`, Elixir/Erlang, GNU
  coreutils, and util-linux `flock`. Run `mix deps.get` in this directory for the
  standalone project's Jason, MuonTrap, and Req dependencies. No Python is required.
- gVisor **`release-20261026.0`**, including its matching `gvisor-bin/` sidecars,
  installed under `/usr/local/bin`. Verify the release archive checksum before
  installation, following the [official installation layout][install]. The
  runner copies these exact binaries; restore rejects a different version.
- Enough storage for full filesystem copies plus memory snapshots. The 20 GiB
  PVC is retained deliberately, and local-path provisioning is not a disk quota.
  Prefer at least 30 GiB free for a clean three-cycle experiment. Check free space
  before every run; do not accumulate repeated runs on the same PVC.

## Build on the disposable Linux host

From the repository root, as root with the above tools installed:

```sh
set -eu
(cd ee/benchmarks/gvisor && mix deps.get && mix compile)
WORK=$(mktemp -d /var/tmp/glossia-gvisor.XXXXXXXX)
nerdctl build -t glossia-editor-bench:local ee/benchmarks/opensandbox/workload
nerdctl save -o "$WORK/workload.tar" glossia-editor-bench:local
mkdir "$WORK/image" "$WORK/context"
tar -xf "$WORK/workload.tar" -C "$WORK/image"
umoci unpack --image "$WORK/image:local" "$WORK/bundle"
tar -cpf "$WORK/context/rootfs.tar" -C "$WORK/bundle/rootfs" .
cp /usr/local/bin/runsc "$WORK/context/"
cp -a /usr/local/bin/gvisor-bin "$WORK/context/"
cp ee/benchmarks/gvisor/{Dockerfile,mix.exs,mix.lock,reconcile.exs,exercise.exs} "$WORK/context/"
cp -a ee/benchmarks/gvisor/lib "$WORK/context/"
# Extract the actual driver from this repository using the standalone project.
(cd ee/benchmarks/gvisor && mix run --no-compile preview_source.exs) > "$WORK/context/preview-runtime.mjs"
nerdctl build -t glossia-gvisor-reconciler:local "$WORK/context"
nerdctl save -o "$WORK/reconciler.tar" glossia-gvisor-reconciler:local
k3s ctr images import "$WORK/reconciler.tar"
```

The nerdctl and k3s image stores are separate. Preload the runner on the selected
node; it intentionally uses `imagePullPolicy: Never`. No image is published.
Save the image ID and SHA-256 hashes of `runsc`, the Elixir sources, `mix.lock`,
and the generated driver with results. Mutable local tags are for this disposable
experiment only.

## Deploy and exercise

```sh
set -eu
k3s kubectl apply -f ee/benchmarks/gvisor/kubernetes.yaml
k3s kubectl wait --for=condition=Established \
  crd/sandboxsessions.bench.glossia.ai --timeout=30s
k3s kubectl -n glossia-sandbox-bench rollout status \
  statefulset/gvisor-reconciler --timeout=120s
k3s kubectl apply -f ee/benchmarks/gvisor/sessions.yaml
(cd ee/benchmarks/gvisor && mix run exercise.exs \
  --output /var/tmp/glossia-resume-results-01 --cycles 3 --idle-seconds 3)
```

Do not reapply `sessions.yaml` over an ongoing run: its initial input sequence
cannot replace an already advanced sequence. To update the runner image, suspend
sessions first, scale the StatefulSet to zero, import the replacement, and scale
back to one. A rollout during an active session intentionally does **not** silently
restore stale work.

`inputSequence` is a cumulative click count, not a coalescing request token.
Each reconcile delivers at most one batch of 32 missing inputs with durable
intent and guest acknowledgements, then yields to polling for lifecycle changes.
`ApplyingInput` is not settled, even when `observedGeneration` matches. Callers
must also wait for the requested phase: `Running` acknowledges the full requested
sequence. Suspension settles only an in-flight batch, preserving the durable
backlog for resume; deletion does not drain inputs.

## Interpret the numbers

- `filesystem_clone_ms`: fresh writable filesystem preparation, including journal
  persistence. `cp --reflink=auto` falls back to a full copy on ext4.
- `runsc_restore_ms`: synchronous runtime restore, after filesystem preparation.
- `runtime_ready_ms`: both stages together, not a usable preview yet.
- `fresh_frame_ms`: from beginning filesystem preparation until a newly produced
  post-restore JPEG. Excludes the independent continuity probe.
- `verified_ms`: adds the independent live CDP/process/file continuity probe.
- `both_sessions_acknowledged_ms`: API request through both generation-matching
  Running statuses, including client polling overhead.
- `post_resume_both_clicks_ms`: a **separate** later input challenge. Not total
  resume-to-interactive latency; artifact collection occurs before this clock.
- `quiesce_ms` / `suspend_ms`: preparation through main-loop acknowledgement /
  total internal suspension through durable checkpoint publication.
- `released_rss_kib`: summed Sentry/gofer RSS before removal, **not** independently
  measured reclaimed physical memory. Shared pages, caches, and page cache make
  RSS different from a cgroup memory or node-capacity measurement.

## Failure and ownership limits

The PVC lock fences a second writer on this single-node POSIX filesystem. This
is not distributed lease fencing. A lost active sandbox is reported failed,
never cold-started or rolled back to an older checkpoint. Interrupted transitions
require inspection. Failed restore/start attempts are cleaned up; a failed
checkpoint preserves a surviving authoritative runtime instead of deleting its
only live memory. A failed pre-checkpoint handshake is released and must produce
a fresh validated frame before being considered Running again.

No host PID/network/IPC namespaces, host filesystem, or runtime socket is mounted.
Nevertheless the privileged root runner is trusted and shares one outer resource
limit between both sandboxes. Kubernetes schedules the runner, **not individual
session reservations**. Suspension releases inner processes but retains the
runner Pod, its resource reservations, and disk state. This is not production
multi-tenant isolation, per-session resource accounting, or cross-node migration.

The static fixture makes no external connections. Long-idle resume, arbitrary
application timers, external TCP connections, Chromium upgrades, and different
host CPUs are not proven. In particular the extracted driver retains its existing
850-second watchdog: this experiment does not establish hours-long session resume.
The handshake does not establish the cause of the earlier mid-command screenshot
timeout or claim to fix the production browser implementation.

## Cleanup and another run

Delete the two disposable CRs and wait for their finalizers to remove runtimes
before deleting the namespace. The PVC is deliberately retained on StatefulSet
scale-down/deletion. Archive the evidence, inspect remaining claims/PVs, and
explicitly dispose of benchmark storage before starting a clean run. Each cycle
retains old generations for inspection; there is no automatic checkpoint GC.
Never force-remove a finalizer while its runtime is alive.

For an entirely disposable VM, removing the VM after archiving evidence is the
simplest complete cleanup. Nothing here is registered with production Flux.

[install]: https://gvisor.dev/docs/user_guide/install/

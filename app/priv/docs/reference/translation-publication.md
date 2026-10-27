%{
  title: "Translation publication",
  summary: "Pull request reuse, batching, and the project-wide push limit.",
  category: "reference",
  section: "translation",
  order: 10
}
---

Glossia keeps one open translation pull request per project. New default-branch
commits continue its branch rather than opening a pull request for each source
commit. A new pull request is created after the previous one is merged or closed.
A closed publication gets a fresh branch name, including when retrying the same
source commit; its rejected outputs are not reused as completed work.

Source synchronization happens in a disposable local checkout before assessment,
preserving the open branch's completed translations and lockfiles. A run that
finds no output or lockfile changes does not advance the remote branch merely
to catch up with the default branch, and does not spend a publication slot.
When a batch is ready, source synchronization and the validated changes are
published together in one non-forced branch update. The commit retains both
the previous publication and the assessed source commit as ancestors.

Publication and session replacement share a database-backed project lock, including
when they run on different application replicas or detached runners. If a runner
created a pull request but could not save its metadata, the next publication
recovers the open Glossia pull request from GitHub before creating another one.
An open pull request is not abandoned when its branch conflicts with the source
or source history is rewritten: the session fails and retains the existing
publication for resolution.

## Push limit

The limit is fixed at **4 pushes per hour per project**, shared across sessions
and replicas. It is not currently configurable.

Pushes are evenly spaced, not counted in fixed clock-hour buckets. Branch
updates are at least 15 minutes apart. The next interval
starts when a publication attempt finishes, so a slow batch cannot be followed
immediately by a fast one. Intermediate batches, retries,
and final flushes all share the same budget. Ambiguous failed attempts consume a
slot too, because GitHub may have advanced the branch before a connection failed.
The budget is stored in PostgreSQL and is not reset by a new session or process
restart.

Before publishing, Glossia rereads the remote head and merges the session's source
locally again. This preserves earlier batches and detects conflicts without
moving the branch. If an earlier update succeeded but its response was lost,
already-present changes are not committed again; publication metadata and the
pull request are recovered without another branch update. If the ref was created
but the runner stopped before creating its pull request, a no-change assessment
still creates the missing pull request, without spending a branch-update slot.

An unexpected remote advance is accepted only when its differences from the
expected synchronized tree are already-present parts of the pending batch.
Other edits made during assessment fail publication rather than being overwritten
or publishing translations validated against stale inputs. The existing pull
request is retained for resolution.

## Batching

A run collects validated file changes and requests publication after 25 files
or 15 minutes. These thresholds do not bypass the push limit. During a cooldown,
additional completed files join the pending batch; repeated changes to the same
path keep the latest content.

At the end of the run, the final flush waits for the same budget. The session
remains active and sends heartbeats while waiting. It rechecks cancellation and
admission periodically without keeping a database transaction open while asleep.

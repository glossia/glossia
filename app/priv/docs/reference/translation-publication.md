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
immediately by a fast one. Source-branch merges, intermediate batches, retries,
and final flushes all share the same budget. Ambiguous failed attempts consume a
slot too, because GitHub may have advanced the branch before a connection failed.
The budget is stored in PostgreSQL and is not reset by a new session or process
restart.

## Batching

A run collects validated file changes and requests publication after 25 files
or 15 minutes. These thresholds do not bypass the push limit. During a cooldown,
additional completed files join the pending batch; repeated changes to the same
path keep the latest content.

At the end of the run, the final flush waits for the same budget. The session
remains active and sends heartbeats while waiting. It rechecks cancellation and
admission periodically without keeping a database transaction open while asleep.

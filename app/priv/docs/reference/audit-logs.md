%{
  title: "Audit logs",
  summary: "Administrator access, recorded fields, coverage, and storage for organization audit events.",
  category: "reference",
  section: "platform",
  edition: "enterprise",
  order: 11
}
---

Open **Organization → Audit logs** in the account sidebar to review account
changes and successful organization sign-ins. Only organization administrators
can read these events, including on public accounts.

## Read the log

Events and filter options belong to the selected account. The table shows up to
50 events per page, newest first, with timestamps in UTC.

- **Search** event names, summaries, actor handles, and actor email addresses
  without case sensitivity.
- **Filter** events by name with **is** or **is not**.
- **Sort** by time, event name, or actor handle.

Search, filters, sorting, and page number remain in the URL so you can share a view
with another administrator.

## What is recorded

The log records account-scoped domain events: organization settings, invitations,
member removals, permissions, projects, language memory, authentication settings,
domain verification, and successful organization sign-ins. System events may
have no actor.

It does not record every page view, failed login, or database write, and does not
replace revision history, translation progress, analytics, or operational logs.

## Recorded fields

| Field | Meaning |
|---|---|
| `id` | Unique event identifier |
| `account_id` | Account whose activity is recorded |
| `name` | Domain event name, such as `organization.authentication_updated` |
| `occurred_at` | UTC timestamp with microsecond precision |
| `user_id` | Acting user, or null for a system action |
| `actor_handle`, `actor_email` | Actor snapshots taken when the event is emitted |
| `resource_type`, `resource_id` | Affected resource, when provided |
| `summary` | Human-readable description, when provided |
| `metadata` | Allowlisted `via` context, such as scheduled verification |

Actor snapshots survive profile changes. Deleting an actor or resource does not
cascade to audit history. Arbitrary metadata, provider tokens, and client secrets
are not stored.

## Storage and deployment

Run the Enterprise image's release migration task before starting a new release.
It creates `audit_events` in PostgreSQL, separate from ClickHouse product
analytics. The Community image does not include these migrations.

Events are written synchronously. Inside a database transaction, an audit event
rolls back with that transaction. A failed audit insert fails the caller, but
changes made without an enclosing transaction may already have completed.

Recording starts when the migration and release are active; earlier activity and
legacy ClickHouse events are not backfilled. There is no automatic expiry,
configurable retention, export API, or external immutable archive. Database
administrators retain database access: this is not a tamper-proof compliance
archive.

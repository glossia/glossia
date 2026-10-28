%{
  title: "Audit logs",
  summary: "Administrator access, recorded fields, coverage, and storage for organization audit events.",
  category: "reference",
  section: "platform",
  edition: "enterprise",
  order: 11
}
---

Organization administrators can open **Enterprise → Audit logs** in the account
sidebar. Community retains ordinary revision history, translation progress,
analytics, and operational logs; the administrator audit log requires Enterprise.

## Access and table controls

Only an administrator of the selected organization can read its audit events or
event-filter options. Public account visibility and basic membership do not grant
audit access. Queries are always scoped to the selected account.

The table supports case-insensitive search over event names, summaries, actor
handles, and actor email addresses. The Event filter supports **is** and **is
not**. Time, event name, and actor handle are sortable; the initial order is
newest first. Search, filters, sorting, and page number remain in the URL. Pages
contain up to 50 events. Displayed timestamps are UTC.

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

Arbitrary event metadata, provider tokens, and client secrets are not copied into
the audit record. Actor snapshots remain unchanged when a user later changes
their profile. No cascading actor or resource foreign keys delete audit history.

## Event coverage

The log subscribes to Glossia's existing account-scoped domain events. These
include organization settings, member invitations and removals, permission
changes, project and language-memory changes, authentication configuration,
domain verification, and successful organization sign-ins. System events may
have no actor. This is not an HTTP access log or a record of every page view,
failed login attempt, or database write.

## Storage and deployment

The Enterprise migration creates `audit_events` in PostgreSQL, separate from
ClickHouse product analytics. `mix ecto.migrate` and the release migration task
include Enterprise migrations only when built with `GLOSSIA_EDITION=enterprise`.
Apply migrations before starting the new Enterprise release. Community builds
do not compile the audit schema, migration, persistence, or UI.

Events are inserted synchronously, not through a lossy ingestion buffer. An event
emitted inside a database transaction rolls back with that transaction. An audit
insert failure fails the caller; mutations without an enclosing transaction may
already have completed before emitting their event.

Recording starts after the Enterprise migration and release are active. Earlier
activity and legacy ClickHouse events are not backfilled. The implementation has
no automatic expiry, configurable retention, export API, or external immutable
archive. Database administrators retain ordinary database access; this is not a
tamper-proof compliance archive.

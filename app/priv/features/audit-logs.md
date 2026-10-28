%{
  title: "Audit logs",
  summary: "Give organization administrators a searchable history of account changes and organization sign-ins.",
  edition: "enterprise",
  order: 9,
  icon: "book-open",
  hero_cta_text: "Contact us",
  hero_cta_url: "mailto:contact@glossia.ai",
  highlights: [
    %{title: "Who changed what", description: "See the event, actor, affected resource, and UTC timestamp.", icon: "book-open"},
    %{title: "Administrator access", description: "Keep audit history private to the organization's administrators, even for public accounts.", icon: "shield-check"},
    %{title: "Shareable views", description: "Search actors and events, filter event types, and preserve the view in its URL.", icon: "code"}
  ]
}
---

## Review organization activity

Enterprise adds **Audit logs** to the account sidebar's **Enterprise** section.
Administrators can review account-scoped domain events, including membership
and permission changes, authentication settings, domain verification, and
successful organization sign-ins.

## Find the relevant changes

Search event descriptions, names, actor handles, or email addresses. Filter by
event type and sort by time, event name, or actor handle. Table controls remain
in the URL so another authorized administrator can open the same view.

## Durable records, explicit limits

Records are stored synchronously in PostgreSQL, separately from product
analytics. Actor snapshots preserve who performed an action even when a profile
later changes. Recording begins when the Enterprise migration and release are
active; earlier activity is not backfilled.

This is not an immutable compliance archive. Retention controls, audit exports,
and external tamper-proof storage are not included. See the
[audit log reference](/docs/reference/audit-logs) for fields and event coverage.

## Available in Enterprise

Administrator audit logs require Enterprise. Community keeps ordinary voice and
glossary version history, translation-session history, analytics, and operational
logs. [Compare editions](/docs/explanation/editions).

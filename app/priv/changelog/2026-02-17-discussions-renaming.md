%{
  title: "Tickets are now discussions",
  summary: "The contributor workflow is now framed as discussions across the UI, routing, and backend model naming."
}
---

We renamed the contributor conversation surface from **Tickets** to **Discussions**.

What changed:

- Sidebar navigation now links to **Discussions**.
- Dashboard routes now use `/discussions` (legacy `/tickets` routes continue to resolve).
- Admin views now use **Discussions** labels and `/admin/discussions` routes.
- The application layer now uses `Glossia.Discussions` as the primary context.
- Suggestion links from voice and glossary now point to discussion URLs.

This keeps the product language aligned with the suggestion-driven collaboration workflow while preserving backward compatibility for older links.

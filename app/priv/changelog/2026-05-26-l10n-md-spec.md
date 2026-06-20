%{
  title: "We created the L10N.md specification",
  summary: "Glossia now ships a public spec, schema set, and reference site for translation-context files."
}
---

We created **L10N.md**, a human-first specification for describing translation context in a way that works for people, repositories, and agents.

This release includes three pieces:

- A public **L10N.md spec** that explains the format and its design goals.
- **Versioned JSON Schemas** so tooling can validate files automatically.
- A dedicated **reference website** published with examples and guidance for implementers.

The goal is to make translation context portable and inspectable instead of trapping it inside proprietary systems. Teams can keep the context next to their content, and tools can read the same source of truth consistently.

If you want to explore it, start at [l10n.md](https://l10n.md).

%{
  title: "Glossary changed-field highlighting and draft-safe suggestion flow",
  summary: "Glossary edits now visually highlight changed content, and suggestion cancel/back keeps contributors on the draft-preserved edited state."
}
---

The Glossary editor now makes pending edits much easier to spot:

- Changed terms, definitions, and translation rows are visually highlighted while editing.
- Added or modified glossary entry blocks are highlighted so reviewers can quickly scan what changed.
- The request finalization page now shows proposed glossary changes in the same term-card layout as the editor (read-only), with clear added/updated/removed highlighting.

The suggestion flow also keeps draft context in the URL, so canceling or navigating back from the suggestion creation page returns to the edited glossary state without losing in-progress changes.

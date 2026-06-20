---
source_language: "en"
validation:
  - "./scripts/validate-gettext.sh"
  - "--strict"
sources:
  "priv/gettext/*.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - ja
  - zh_Hant
---

# Project Translation Context

This repository holds a single small product. There is no need for nested
scopes; the root document defines both the repository-wide voice and the
translation workflow.

## Voice
- Friendly and direct. Prefer plain words over jargon.
- Use the second person ("you") for user-facing copy.
- Avoid exclamation marks outside of celebratory states.

## Product Language
- "Workspace" refers to the team's shared area.
- "Run" is the unit of execution; do not translate to a localized verb form.

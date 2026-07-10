---
model: "openai/gpt-5"
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

# App Translation Context

The app includes marketing copy, onboarding, and a signed-in dashboard for localization managers.

## Translation Domains
- `marketing`: Public-facing copy. Tone should feel clear, credible, and inviting.
- `onboarding`: New user setup. Keep copy short and confidence-building.
- `dashboard`: Logged-in interface. Prefer compact labels and direct verbs.
- `errors`: Recovery-oriented error messages. Explain what happened and what to do next.

## Product Language
- "Workspace" refers to the translator's team space and should remain a singular concept.
- "String set" refers to a grouped collection of related translations.
- "Ship review" means the final approval pass before a locale is published.

---
source_language: en
frontmatter: translate
sources:
  "priv/docs/**/*.md": "priv/i18n/{locale}/docs/{relpath}"
  "priv/blog/*.md": "priv/i18n/{locale}/blog/{relpath}"
  "priv/features/*.md": "priv/i18n/{locale}/features/{relpath}"
  "priv/legal/*.md": "priv/i18n/{locale}/legal/{relpath}"
  "priv/gettext/default.pot": "priv/gettext/{locale}/LC_MESSAGES"
  "priv/gettext/errors.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
  - de
  - ja
  - zh-Hans
  - ko
  - pt-BR
---

# Web Application Translation Context

The web application is a Phoenix product surface with public marketing pages,
documentation navigation, account management, project onboarding, sandbox setup, and
translation session workflows.

## Gettext Catalogs

- `priv/gettext/default.pot` contains most product and dashboard strings.
- `priv/gettext/errors.pot` contains validation and form error messages.
- Output files should live under `priv/gettext/<locale>/LC_MESSAGES/` and keep the source
  domain names, for example `default.po` and `errors.po`.
- Preserve all gettext references, flags, plural forms, and interpolation placeholders.

## User Interface Guidance

- Keep labels short enough for table cells, buttons, filters, and sidebars.
- Preserve product names and technical file names in English when they refer to code or
  repository artifacts.
- For actions, prefer direct verbs.
- For setup and translation status messages, keep the wording calm and specific.

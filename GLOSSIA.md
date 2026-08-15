---
source_language: en
frontmatter: translate
sources:
  "app/priv/docs/**/*.md": "app/priv/i18n/{locale}/docs/{relpath}"
  "app/priv/blog/*.md": "app/priv/i18n/{locale}/blog/{relpath}"
  "app/priv/features/*.md": "app/priv/i18n/{locale}/features/{relpath}"
  "app/priv/legal/*.md": "app/priv/i18n/{locale}/legal/{relpath}"
  "app/priv/gettext/default.pot": "app/priv/gettext/{locale}/LC_MESSAGES"
  "app/priv/gettext/dashboard_projects.pot": "app/priv/gettext/{locale}/LC_MESSAGES"
  "app/priv/gettext/errors.pot": "app/priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
  - de
  - ja
  - zh-Hans
  - ko
  - pt-BR
---

# Glossia Repository Translation Context

This repository contains the Glossia web application, the command-line translator, the
`GLOSSIA.md` reference site, deployment manifests, and supporting product documentation.

The source language is English. Translated outputs go next to their English sources
according to the `sources` templates above. Target locale overrides and extra guidance
for a specific language belong in `GLOSSIA/<locale>.md`.

## Product Language

- Keep "Glossia" untranslated.
- Keep `GLOSSIA.md`, `.glossia/`, command names, file paths, environment variable names, and
  code identifiers exactly as written.
- Treat "voice", "terminology", "translation session", "setup session", "sandbox", and
  "lockfile" as product concepts. Translate them consistently within each locale.
- Prefer clear, direct user interface copy over literal word-for-word translation.

## Tone

- Marketing and onboarding copy should feel credible, calm, and practical.
- Dashboard and operational copy should be compact and action-oriented.
- Error messages should explain what happened and what to do next without blaming the user.
- Do not use em dashes. Prefer a hyphen or rewrite the sentence.

## Formatting Rules

- Preserve placeholders such as `%{name}`, `{locale}`, `{relpath}`, and `{count}` exactly.
- Preserve Markdown, HTML tags, links, code fences, and quoted code identifiers.
- Preserve gettext comments and references. Translate only gettext `msgstr` values.

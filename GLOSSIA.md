---
source_language: "en"
targets:
  es: "Spanish"
---

# Glossia Repository Translation Context

This repository contains the Glossia web application, the command-line translator, the
`GLOSSIA.md` reference site, deployment manifests, and supporting product documentation.

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

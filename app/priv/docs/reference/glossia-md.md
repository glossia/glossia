%{
  title: "GLOSSIA.md",
  summary: "Reference for repository translation settings and context.",
  category: "reference",
  order: 1
}
---

`GLOSSIA.md` tells Glossia which files to translate, where translated files belong, which languages to target, and what context should guide the result. A repository can have a root file and additional scoped files in subdirectories.

## Structure

Each file has two parts:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter between `---` markers.
2. Markdown below the frontmatter with product, audience, voice, or domain context.

```yaml
---
source_language: en
model: translation-default
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
validation:
  - ./scripts/validate-docs.sh
  - --strict
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Write for software developers. Keep product names and code samples unchanged.
```

Provider credentials belong in account settings, never in `GLOSSIA.md`. The optional `model` value is an account model handle.

## Frontmatter fields

| Field | Type | Required | Description |
|---|---|---|---|
| `source_language` | string | no | Source locale for this scope. Defaults to `en`. |
| `model` | string | no | Account model handle. Glossia uses the account default when omitted and reports an error when an explicit handle does not exist. |
| `sources` | map or list | for a top-level rule | Source file patterns. Map values can define output templates. |
| `targets` | map or list | when sources are configured | Target locale codes. A map can associate a locale code with a language name. |
| `output` | string | when no source mapping or `target_path` supplies a destination | Output file template. |
| `target_path` | string | when no source mapping or `output` supplies a destination | Base directory template for translated files. |
| `translate` | list | no | Multiple translation rules, each with its own sources and optional overrides. |
| `exclude` | list | no | File patterns to skip. |
| `preserve` | list | no | Content kinds that must remain unchanged, such as placeholders or uniform resource locators. |
| `frontmatter` | string | no | `preserve` by default, or `translate`. |
| `prompt` | string | no | Additional guidance for this scope or rule. |
| `validation` | list | no | A validation command followed by its arguments. |
| `check_cmd` | string | no | A check command available to the translation workflow. |
| `check_cmds` | map | no | Named check commands available to the translation workflow. |
| `retries` | integer | no | Number of retry attempts after a failed check. Defaults to `2`. |
| `locale` | string | no | Locale attached to a locale-specific context file. |

Unknown frontmatter fields are ignored.

## Source mappings

The clearest form maps every source pattern to an output template:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

A source list is also valid, but it needs `output` or `target_path` to define the destination:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Target languages

A list uses each locale code as its language identifier:

```yaml
targets:
  - es
  - ja
```

A map can add a readable language name:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Output variables

| Variable | Value |
|---|---|
| `{locale}` or `{lang}` | Target locale code. |
| `{relpath}` | Source path relative to the matched pattern. |
| `{basename}` | Source filename without its extension. |
| `{ext}` | Source file extension without the leading dot. |

## Multiple rules

Use `translate` when different content groups need different destinations or checks:

```yaml
---
source_language: en
targets:
  - es
translate:
  - sources:
      - "docs/**/*.md"
    output: "docs/i18n/{locale}/{relpath}"
  - source: "messages/*.json"
    output: "messages/{locale}/{basename}.{ext}"
---
```

Rule values override values inherited from the surrounding file.

## Scoped context

Glossia reads `GLOSSIA.md` files from the repository root toward the source file:

- Parent settings provide defaults.
- A deeper file overrides fields for its directory.
- Markdown context is accumulated from parent to child.
- Locale-specific guidance and a locale-specific model handle can live in `GLOSSIA/<locale>.md`.

This lets a repository keep broad voice guidance at the root while placing product-area or language-specific guidance close to the content it affects.

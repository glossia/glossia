%{
  title: "L10N.md",
  summary: "Complete reference for the L10N.md configuration file.",
  category: "reference",
  order: 1
}
---

`L10N.md` is the configuration file that tells Glossia what to translate, which target locales to generate, and which context should guide the translation. It lives at the root of your repository or in subdirectories when you need scoped context.

## Structure

An `L10N.md` file has two parts:

1. **YAML frontmatter** between `---` markers for machine-readable settings.
2. **Markdown context** below the frontmatter for translators and agents.

```yaml
---
source_language: en
model: gpt-5
validation:
  - ./scripts/validate-docs.sh
  - --strict

sources:
  "docs/**/*.md": "docs/i18n/{locale}/**"
  "locales/**/*.json": "locales/{locale}/**"
targets:
  - es
  - ja
  - de
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Project context for translators goes here.
```

Provider, endpoint, and API key settings live in local `glossia.toml` instead of `L10N.md`:

```toml
[llm]
provider = "openai"
api_key_env = "OPENAI_API_KEY"
```

## Frontmatter Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `source_language` | string | yes | Source locale for the files in this scope. |
| `model` | string | yes | Model identifier, optionally qualified as `provider/model`. |
| `sources` | map or list | yes | Source globs, optionally mapped to output path templates. |
| `targets` | list or map | yes | Target locale codes. |
| `validation` | list | no | Command argv used to validate generated output. |
| `frontmatter` | string | no | `preserve` by default, or `translate`. |
| `preserve` | list | no | Elements to preserve, such as placeholders or URLs. |
| `exclude` | list | no | Glob patterns to skip. |
| `retries` | integer | no | Retry count for validation failures. |

## Source Mappings

When `sources` is a map, each key is a source glob and each value is an output path template:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/**"
```

When `sources` is a list, Glossia uses `target_path` or rule-level output settings to resolve generated files.

## Output Path Variables

| Variable | Description |
|---|---|
| `{locale}` or `{lang}` | Target locale code. |
| `{relpath}` | Relative path of the source file. |
| `{basename}` | Filename without extension. |
| `{ext}` | File extension. |

## Scoped Context

`L10N.md` files can exist at any depth. Glossia merges context from root to leaf:

- Parent frontmatter provides defaults.
- Deeper frontmatter overrides parent values.
- Markdown bodies are concatenated as translation context.
- Locale-specific context can live in `L10N/<locale>.md`.

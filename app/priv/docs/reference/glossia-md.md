%{
  title: "GLOSSIA.md",
  summary: "Complete reference for the GLOSSIA.md configuration file.",
  category: "reference",
  order: 1
}
---

`GLOSSIA.md` is the configuration file that tells Glossia what to process, how to process it, and where to write the output. It lives at the root of your project or in any subdirectory to scope configuration to a subtree.

## Structure

A `GLOSSIA.md` file has two parts:

1. **TOML frontmatter** between `+++` markers that defines content entries and LLM settings.
2. **Free-text context** below the frontmatter that agents use to understand your product, tone, and conventions.

```toml
+++
[llm]
provider = "anthropic"

[[content]]
source = "docs/**/*.md"
targets = ["es", "fr"]
output = "docs/i18n/{lang}/{relpath}"
+++

Glossia is a CLI tool for LLM-powered content processing.
Source language: English.
Tone: technical, concise, friendly.
```

## `[llm]` section

| Field | Type | Description |
|---|---|---|
| `provider` | string | LLM provider: `"openai"`, `"anthropic"`, or `"vertex"` |
| `api_key` | string | API key or env var template like `{env.OPENAI_API_KEY}` |

## `[[llm.agent]]` entries

Define models for different roles:

```toml
[[llm.agent]]
role = "coordinator"
model = "claude-sonnet-4-5-20250929"

[[llm.agent]]
role = "translator"
model = "claude-sonnet-4-5-20250929"
```

## `[[content]]` entries

Each `[[content]]` block defines a set of files to process.

### Common fields

| Field | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | Glob pattern for source files |
| `exclude` | array | no | Glob patterns to skip |
| `check_cmd` | string | no | Validation command (use `{file}` placeholder) |

### Translation fields

When `targets` is present, the entry is a translation entry:

| Field | Type | Required | Description |
|---|---|---|---|
| `targets` | array | yes | Target language codes |
| `output` | string | yes | Output path template |

### Revisit fields

When `targets` is absent, the entry is a revisit entry:

| Field | Type | Required | Description |
|---|---|---|---|
| `output` | string | no | Output path (defaults to overwriting source) |

## Output path variables

| Variable | Description |
|---|---|
| `{lang}` | Target language code |
| `{relpath}` | Relative path of the source file |
| `{basename}` | Filename without extension |
| `{ext}` | File extension |

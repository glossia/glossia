# Glossia CLI

Localize like you ship software.

`glossia` translates repository content locally, keeps generated files in-repo,
and lets you validate output with your own tooling before you ship it.

It is centered around a generic `L10N.md` context tree:

- `L10N.md` files can exist at any depth.
- Frontmatter is inherited from root to leaf.
- Deeper files override parent frontmatter keys.
- Markdown bodies are concatenated and used as translation context.
- Locale-specific context can live in `L10N/<locale>.md`.

## Install

```bash
mise use aqua:glossia.ai/cli@latest
glossia --help
```

You can also download platform binaries from GitHub Releases.

## Usage

```bash
glossia init
glossia translate
glossia check
glossia status
glossia clean --dry-run
```

`revisit` is reserved for a follow-up pass and currently returns a
not-implemented error.

## Configuration

The primary `L10N.md` shape follows the v1.1 spec: `model` is a model
identifier, `sources` is a map from source patterns to target path templates,
`targets` is a locale array, and `validation` is an argv array.

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
Global translation guidance goes here.
```

Provider, auth, and endpoint configuration live locally in `glossia.toml`:

```toml
[llm]
provider = "fireworks"
base_url = "https://api.fireworks.ai/inference/v1"
api_key_env = "FIREWORKS_API_KEY"
```

`provider` in `L10N.md` is still accepted as a backward-compatible extension,
but `glossia.toml` takes precedence for runtime connection settings.

Supported output placeholders:

- `{locale}` or `{lang}`
- `{relpath}`
- `{basename}`
- `{ext}`

## Development

```bash
mise install
mise exec -- cargo test --lib
mise exec -- cargo test --test e2e_translate
mise exec -- cargo clippy --all-targets --all-features -- -D warnings
mise exec -- cargo build --release
mise exec -- blick review --base origin/main --json --stream
```

The integration test suite exercises generic Markdown and JSON translation
flows end to end against a local in-process OpenAI-compatible fake provider,
including structured output repair retries.

Blick review and learn are configured in `blick.toml` and the GitHub workflows
under `.github/workflows/blick*.yml`. The review skill is tuned for this
CLI, its generic translation architecture, and the provider-agnostic context
hashing model.

Release automation lives in `RELEASE.md`. Releases are published from the
`glossia/glossia` monorepo with `cli-v*` tags and generated from changes under
`cli/**`.

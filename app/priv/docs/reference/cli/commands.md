%{
  title: "Commands",
  summary: "Reference for all Glossia CLI commands and their flags.",
  category: "reference",
  subcategory: "cli",
  order: 1
}
---

## `glossia init`

Create a starter `GLOSSIA.md` configuration file and local `glossia.toml` runtime config in the current repository.

```bash
glossia init
```

Fails if `GLOSSIA.md` already exists.

## Translation is server-side

Translation runs on the Glossia server, not in the CLI. When a commit lands,
Glossia plans the work from your `GLOSSIA.md` files, translates each file with
your account's configured model, and opens a pull request with the results — you
can watch each file and the model's turns live on the translation session page.

The model is chosen per document: a `GLOSSIA.md` `model:` naming one of your
account model handles selects it; otherwise your account's default model is used.

The translation credential resolves in this order: the account model's own API
key, then a globally configured inference provider (`GLOSSIA_TRANSLATION_API_KEY`
+ `GLOSSIA_TRANSLATION_BASE_URL` + `GLOSSIA_TRANSLATION_MODEL`), and — in
development only — your local Claude Code or Codex CLI session (whichever is
valid), so you can run real translations locally without configuring a key.

The CLI's `init`, `check`, `status`, and `clean` commands remain for local
inspection.

## `glossia revisit`

Reserved for a future source-language revision pass. The Rust CLI currently returns a not-implemented error for this command.

```bash
glossia revisit
```

## `glossia check`

Validate all generated output files against their configured checks.

```bash
glossia check [OPTIONS]
```

| Flag | Description |
|---|---|
| `--check-cmd <CMD>` | Override the validation command |
| `--locale <LOCALE>` | Validate one target locale |

## `glossia status`

Show the current state of all content entries: up to date, stale, or missing.

```bash
glossia status [OPTIONS]
```

| Flag | Description |
|---|---|
| `--check-cmd <CMD>` | Override the validation command used for status planning |
| `--locale <LOCALE>` | Report one target locale |

## `glossia clean`

Remove generated output files.

```bash
glossia clean [OPTIONS]
```

| Flag | Description |
|---|---|
| `--dry-run` | Show what would be removed without doing it |
| `--orphans` | Only remove orphaned files (outputs with no matching source) |
| `--locale <LOCALE>` | Clean one target locale |

## Global flags

| Flag | Description |
|---|---|
| `--path <PATH>` | Override the project root directory |
| `--no-color` | Disable colored output |

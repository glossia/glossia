%{
  title: "Commands",
  summary: "Reference for all Glossia CLI commands and their flags.",
  category: "reference",
  subcategory: "cli",
  order: 1
}
---

## `glossia init`

Create a starter `L10N.md` configuration file and local `glossia.toml` runtime config in the current repository.

```bash
glossia init
```

Fails if `L10N.md` already exists.

## `glossia translate`

Run translation for all configured source mappings.

```bash
glossia translate [OPTIONS]
```

| Flag | Description |
|---|---|
| `--force` | Re-translate all files, ignoring hashes |
| `--retries <N>` | Override retry count |
| `--dry-run` | Show what would be translated without doing it |
| `--check-cmd <CMD>` | Override the validation command |
| `--locale <LOCALE>` | Translate one target locale |

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

%{
  title: "CLI commands",
  summary: "Reference for all Glossia CLI commands and their flags.",
  category: "reference",
  order: 2
}
---

## `glossia init`

Launch an interactive agent to create a `CONTENT.md` configuration file.

```bash
glossia init
```

Requires an ACP-compatible agent (Claude Code, Codex CLI, Gemini CLI, Goose, or OpenCode) installed on your system.

## `glossia translate`

Run translation for all `[[content]]` entries that have `targets` defined.

```bash
glossia translate [OPTIONS]
```

| Flag | Description |
|---|---|
| `--force` | Re-translate all files, ignoring hashes |
| `--yolo` | Skip validation checks |
| `--no-yolo` | Force validation even if `--yolo` is set |
| `--retries <N>` | Override retry count |
| `--dry-run` | Show what would be translated without doing it |
| `--check-cmd <CMD>` | Override the validation command |

## `glossia revisit`

Run revision for all `[[content]]` entries that do not have `targets`.

```bash
glossia revisit [OPTIONS]
```

| Flag | Description |
|---|---|
| `--force` | Re-process all files, ignoring hashes |
| `--retries <N>` | Override retry count |
| `--dry-run` | Show what would be revised without doing it |
| `--check-cmd <CMD>` | Override the validation command |

## `glossia check`

Validate all generated output files against their configured checks.

```bash
glossia check [OPTIONS]
```

| Flag | Description |
|---|---|
| `--check-cmd <CMD>` | Override the validation command |

## `glossia status`

Show the current state of all content entries: up to date, stale, or missing.

```bash
glossia status
```

## `glossia clean`

Remove generated output files.

```bash
glossia clean [OPTIONS]
```

| Flag | Description |
|---|---|
| `--dry-run` | Show what would be removed without doing it |
| `--orphans` | Only remove orphaned files (outputs with no matching source) |

## Global flags

| Flag | Description |
|---|---|
| `--path <PATH>` | Override the project root directory |
| `--no-color` | Disable colored output |

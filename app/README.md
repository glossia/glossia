# Glossia App

This directory contains the multi-tenant Phoenix application. It serves both
the authenticated product and the public website:

- Blog content lives in `priv/blog/`.
- Changelog entries live in `priv/changelog/`.
- Documentation lives in `priv/docs/`.
- Feature pages live in `priv/features/`.

Repository-wide conventions for this app live in [AGENTS.md](./AGENTS.md).

## Local development

From the repository root:

```bash
mise install
cd app
mix setup
mix phx.server
```

### Toki host harness (development only)

Toki normally uses the account/server API provider through ReqLLM. To explicitly
use the development server's installed Claude CLI through Condukt 1.12 instead,
set `GLOSSIA_TOKI_HARNESS=claude` when starting that server. Optionally set
`GLOSSIA_TOKI_HARNESS_MODEL=haiku` (or another Claude CLI model identifier).
These settings are ignored outside `config_env() == :dev`, override API inference
for all authorized Toki users on that server, and are never read from client
request bodies. Mobile clients still talk only to the server, not a local CLI.
Unset the harness variable to restore the normal provider path.

Authentication uses the server's `CLAUDE_CODE_OAUTH_TOKEN`, or its existing
unexpired Claude Code macOS keychain login. Other platforms must supply the token
(obtain one interactively with `claude setup-token`). Credentials go only to the
CLI environment, never the model prompt. Tokens are not refreshed or saved by
Toki. No account API key or implicit Codex/Pi session is borrowed in this mode.

The CLI must be version 2.1.285 or newer and support `--safe-mode`, `--tools ""`,
`dontAsk` permissions, strict empty MCP configuration, disabled hooks/skills,
and `--no-session-persistence`. A local `--version` preflight rejects older or
unknown versions before inference. Both documented
[API retry controls](https://code.claude.com/docs/en/errors#tune-retry-behavior)
are set to zero, and the retry watchdog is disabled.
It receives only the same bounded authorized project context and transcript as
the API path, in a private disposable home/cwd with no checkout mounted. State is
removed on success, failure, timeout, or worker death; a whole VM/machine crash
can leave temporary directories behind. The CLI has a 60-second timeout inside
the unchanged 90-second worker deadline. There is one inference invocation per
claimed turn, with no retry, fallback, or session resume. Reply size and final
authorization checks still apply. A process-group wrapper also cleans up CLI
children on macOS, where MuonTrap alone only terminates its immediate child.

This trusts the installed CLI and machine policy, not an OS-level sandbox.
Condukt's installed Codex adapter does not guarantee tool-less inference (a
read-only sandbox still permits reads/commands), and 1.12 has no Pi adapter.
Those harness values therefore fail configuration in development rather than
silently enabling coding capabilities. No real-model check is part of the
regression tests; they use a stub CLI/transport.

## Worktree-aware databases

Development and test database names are derived at runtime from the current working tree path.
No `.codex` setup is required: each Git worktree gets isolated Postgres and ClickHouse databases automatically.

Set `GLOSSIA_DB_SUFFIX` only if you need to override the automatic suffix.

The dev server port also scopes per worktree via `GLOSSIA_SERVER_PORT`, which is loaded automatically through `mise`.

After the server boots, visit `http://localhost:${GLOSSIA_SERVER_PORT}`. If that variable is unset in your shell, the runtime falls back to `4050`.

## Production

Production infrastructure lives in this repository under `deploy/helm/glossia/`
and `infra/`. Pushes to `main` build and publish the application image to GitHub
Container Registry, and Flux reconciles the production deployment.

## Learn more

* Glossia docs: https://glossia.ai/docs
* Phoenix guides: https://hexdocs.pm/phoenix/overview.html
* Phoenix docs: https://hexdocs.pm/phoenix
* Elixir Forum: https://elixirforum.com/c/phoenix-forum

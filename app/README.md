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

## Worktree-aware databases

Development and test database names are derived at runtime from the current working tree path.
No `.codex` setup is required: each Git worktree gets isolated Postgres and ClickHouse databases automatically.

Set `GLOSSIA_DB_SUFFIX` only if you need to override the automatic suffix.

The dev server port also scopes per worktree via `GLOSSIA_SERVER_PORT`, which is loaded automatically through `mise`.

After the server boots, visit `http://localhost:${GLOSSIA_SERVER_PORT}`. If that variable is unset in your shell, the runtime falls back to `4050`.

## Production

Production infrastructure is maintained separately from this source
repository. The application image is published to the GitHub Container Registry
after the application checks pass on `main`.

## Learn more

* Glossia docs: https://glossia.ai/docs
* Phoenix guides: https://hexdocs.pm/phoenix/overview.html
* Phoenix docs: https://hexdocs.pm/phoenix
* Elixir Forum: https://elixirforum.com/c/phoenix-forum

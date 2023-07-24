# Glossia

[![Glossia](https://github.com/glossia/app/actions/workflows/glossia.yml/badge.svg)](https://github.com/glossia/app/actions/workflows/glossia.yml)

Glossia's monolith repository.

## Development

### Setup

1. Clone the repository: `git clone git@github.com:glossia/app.git`
2. Install the dependencies: `mix deps.get`
3. Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

### Useful commands

- Open a remote console with production: `flyctl ssh console --pty -C "/app/bin/glossia remote"`
- Generate a graph of dependencies: `mix xref graph`
- Seed data: `mix run priv/repo/seeds.exs`
# Glossia Monorepo

A monorepo containing Glossia applications and packages.

## Structure

```
glossia/
├── cli/               # Rust CLI tool
├── crates/
│   └── glossia-core/  # Shared Rust library
├── server/            # Phoenix backend server (includes web editor)
├── Cargo.toml         # Rust workspace configuration
├── mise.toml          # Dependency management
└── .gitignore
```

## Prerequisites

This project uses `mise` to manage dependencies. Install mise from https://mise.jdx.dev/

## Setup

1. Install dependencies using mise:
```bash
mise install
```

2. Set up the Phoenix server:
```bash
cd server
mix deps.get
mix ecto.create
```

3. (Optional) Build the CLI:
```bash
cargo build --release -p glossia-cli
```

## Applications

### Phoenix Server (`server`)

The Phoenix backend server hosts the Glossia platform, including:
- **Web Editor**: Phoenix LiveView-based translation review interface
- **API**: REST API for CLI authentication and translation
- **Ephemeral Environments**: Orchestrates Firecracker microVMs for review sessions
- **Authentication**: GitHub/GitLab OAuth integration

**Development:**
```bash
cd server
mix phx.server
```

The server will be available at http://localhost:4000

**Interactive shell:**
```bash
cd server
iex -S mix phx.server
```

### CLI (`cli`)

A command-line tool for Glossia built with Rust and Clap. Shares code with server integrations via the `glossia-core` library.

**Build:**
```bash
cargo build --release -p glossia-cli
```

**Run:**
```bash
cargo run -p glossia-cli -- greet --name "World"
cargo run -p glossia-cli -- config
```

**Install locally:**
```bash
cargo install --path cli
glossia greet --name "World"
```

## Shared Libraries

### `glossia-core` (`crates/glossia-core`)

Core Rust library shared between the CLI and server integrations. Contains common functionality like:
- Configuration parsing (`glossia.toml`)
- Translation file format handlers
- Decision data structures
- Validation check runtime

## Tech Stack

- **Dependency Manager**: mise
- **CLI**: Rust + Clap
- **Shared Library**: Rust
- **Backend Server**: Phoenix (Elixir + PostgreSQL)
- **Web Editor**: Phoenix LiveView
- **Ephemeral Environments**: Firecracker microVMs (via Fly.io or AWS)

## Architecture Overview

Glossia is an AI-native translation platform with a unique architecture:

1. **CLI**: Developers run `glossia translate` locally to AI-translate changes
2. **Web Editor**: Linguists click a repo badge → ephemeral environment spins up → review translations in browser
3. **Ephemeral Environments**: Each review session gets an isolated Firecracker microVM with the repo cloned using the user's OAuth credentials
4. **Git as Source of Truth**: No syncing - translations live in the repo, decisions stored in `.glossia/` directory

See [CLAUDE.md](./CLAUDE.md) for the full vision and architecture details.

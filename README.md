# Glossia Monorepo

A monorepo containing Glossia applications and packages.

## Structure

```
glossia/
├── apps/
│   └── desktop/       # Tauri desktop application
├── cli/               # Rust CLI tool
├── crates/
│   └── glossia-core/  # Shared Rust library
├── server/            # Phoenix backend server
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

2. Navigate to the app you want to work on and install its dependencies:

**For Desktop App:**
```bash
cd apps/desktop
npm install
```

**For Phoenix Server:**
```bash
cd server
mix deps.get
mix ecto.create
```

**For CLI (optional, built via Cargo workspace):**
```bash
cargo build --release -p glossia-cli
```

## Applications

### Desktop App (`apps/desktop`)

A Tauri-powered desktop application.

**Development:**
```bash
cd apps/desktop
npm run dev
```

**Build:**
```bash
cd apps/desktop
npm run build
```

### Phoenix Server (`server`)

A Phoenix backend server for the Glossia platform.

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

A command-line tool for Glossia built with Rust and Clap. Shares code with the desktop app via the `glossia-core` library.

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

Core Rust library shared between the desktop app and CLI. Contains common functionality like configuration, utilities, and business logic.

## Tech Stack

- **Dependency Manager**: mise
- **Desktop App**: Tauri 2.0 (Rust + HTML/CSS/JS)
- **CLI**: Rust + Clap
- **Shared Library**: Rust
- **Backend Server**: Phoenix (Elixir + PostgreSQL)

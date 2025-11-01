# Glossia CLI

Command-line interface for Glossia.

## Features

- Shares core functionality with the desktop app via `glossia-core` library
- Built with Clap for robust argument parsing
- Async runtime with Tokio

## Usage

```bash
# Run from workspace root
cargo run -p glossia-cli -- greet --name "World"
cargo run -p glossia-cli -- config

# Or build and install
cargo install --path .
glossia greet --name "Your Name"
glossia config
```

## Commands

- `greet` - Greet a user (uses shared `glossia-core::greet` function)
- `config` - Display current configuration

## Development

The CLI uses the shared `glossia-core` library located in `crates/glossia-core`, which means any business logic added there is automatically available to both the CLI and desktop app.

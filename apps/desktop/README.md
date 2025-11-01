# Glossia Desktop

A Tauri-powered desktop application.

## Prerequisites

This project uses `mise` to manage dependencies. Install mise from https://mise.jdx.dev/

## Setup

1. Install dependencies using mise:
```bash
mise install
```

2. Install npm dependencies:
```bash
npm install
```

## Development

Run the app in development mode:
```bash
npm run dev
```

## Build

Build the app for production:
```bash
npm run build
```

The built application will be in `src-tauri/target/release/bundle/`.

## Tech Stack

- **Frontend**: HTML, CSS, JavaScript
- **Backend**: Rust with Tauri 2.0
- **Package Manager**: npm
- **Dependency Manager**: mise

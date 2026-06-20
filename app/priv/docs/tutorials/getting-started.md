%{
  title: "Getting started",
  summary: "Set up Glossia in your project and run your first translation.",
  category: "tutorials",
  order: 1
}
---

This tutorial walks you through installing Glossia, creating a configuration file, and running your first content translation.

## Prerequisites

- A project with content files (Markdown, JSON, YAML, or PO)
- An API key for at least one LLM provider (OpenAI, Anthropic, or Vertex AI)

## Install Glossia

Install with mise:

```bash
mise use aqua:glossia.ai/cli@latest
```

Or install with aqua directly:

```bash
aqua g -i glossia.ai/cli@latest
```

## Initialize your project

Run the init command to set up an `L10N.md` configuration file:

```bash
glossia init
```

This writes a starter `L10N.md` at the project root and creates `glossia.toml` for local provider settings when it does not already exist.

## Run your first translation

Once `L10N.md` is in place, translate your content:

```bash
glossia translate
```

Glossia reads your source files, sends them to the configured model, validates the output, and writes the translated files to the paths defined in your configuration.

## Check the results

Review what Glossia produced:

```bash
glossia status
```

This shows which files are up to date, which are stale, and which are missing.

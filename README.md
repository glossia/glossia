# Glossia

The language OS for your organization.

Glossia captures your voice, terminology, and tone in one place so linguists and teams can shape how your organization speaks across every language and surface.

## What is a language OS?

Your organization already has systems for code, design, and data. Language deserves the same level of care. Glossia provides:

- **One source of truth for how you speak** -- All of your linguistic preferences live in one place. Every team draws from the same foundation, so your organization sounds consistent whether it is a product screen, a marketing campaign, or a support reply.
- **Speak new languages, reach new markets** -- The same linguistic foundation that keeps your content consistent also powers expansion into new languages. Linguists refine the voice once, and every market benefits from that work immediately.
- **Context for the tools you already use** -- Glossia integrates with your existing workflows through APIs and open standards like [MCP](https://modelcontextprotocol.io/). Your writing tools, content platforms, and AI assistants can all tap into your organization's linguistic knowledge without switching systems.

## Project structure

- **`app/`** -- The web application, built with [Elixir](https://elixir-lang.org/) and [Phoenix](https://www.phoenixframework.org/).
- **`cli/`** -- The CLI, written in [Go](https://go.dev/). Translates files locally using LLMs, keeps content in-repo, and validates output with your own tooling.

## OSS and enterprise boundary

Glossia OSS remains the shared product core. Enterprise-specific concerns live in the
enterprise repository and integrate through explicit extension points.

- Marketing and docs pages belong in the enterprise repository.
- Deployment automation, including Kamal, belongs in the enterprise repository.
- Secrets management belongs in the enterprise repository.
- Auditing is emitted by OSS workflows but stored and enriched by the configured audit sink.
- Authorization defaults to the OSS policy backend, but deployments can replace it with an enterprise permission system.

## Getting started

Visit [glossia.ai](https://glossia.ai) to learn more, or check out the [docs](https://glossia.ai/docs).

### CLI

```bash
mise use aqua:glossia.ai/cli@latest
glossia init
glossia translate
```

### Web app

```bash
cd app
mix setup
mix phx.server
```

## Community

- [Forum](https://community.glossia.ai/)
- [Discord](https://discord.gg/7FRHkwvs)

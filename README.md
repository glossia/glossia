# Glossia

The language OS for your organization.

Glossia captures your voice, terminology, and tone in one place so linguists
and teams can shape how your organization speaks across every language and
surface.

Glossia is proprietary software. The source is available to authorized
contributors only and is not licensed for copying, redistribution, or external
use. See [LICENSE.md](./LICENSE.md).

## Product Shape

Glossia is now a single multi-tenant Phoenix application. The public website,
blog, docs, changelog, product app, OAuth server, API, MCP surface, and account
workflows live in `app/`.

The previous standalone website, CLI, infra, and L10N repositories have been
folded into this monorepo. The separate cloud control-plane repository is
retired for this direction and was not imported because tenancy belongs in the
main Phoenix application.

## Project Structure

- `app/`: Elixir and Phoenix application. It serves the product and the public
  website content from `app/priv/`.
- `cli/`: active Rust CLI implementation, with release automation scoped to
  `cli/**`.
- `infra/`: infrastructure sources imported from the infra repository, including
  Helm platform charts, Kubernetes cluster assets, and Terraform.
- `l10n/`: L10N standard package, including the specification, schemas,
  examples, and Eleventy reference site. This package keeps its own MIT license
  notice in `l10n/LICENSE`.
- `deploy/`: application deployment chart and production values.
- `mobile/`: mobile app prototype.

## Getting Started

Visit [glossia.ai](https://glossia.ai) to learn more, or check out the [docs](https://glossia.ai/docs).

### CLI

```bash
mise use aqua:glossia.ai/cli@latest
glossia init
glossia translate
```

### Web App

```bash
cd app
mix setup
mix phx.server
```

### CLI Development

```bash
cd cli
mise exec -- cargo test --lib
mise exec -- cargo test --test e2e_translate
```

### L10N Standard

```bash
cd l10n
mise run install
mise run validate
mise run build
```

## Community

- [Forum](https://community.glossia.ai/)
- [Discord](https://discord.gg/7FRHkwvs)

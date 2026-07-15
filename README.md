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

The previous standalone website, command-line tool, and infrastructure
repositories have been folded into this monorepo. The separate cloud
control-plane repository is retired for this direction and was not imported
because tenancy belongs in the main Phoenix application.

## Project Structure

- `app/`: Elixir and Phoenix application. It serves the product and the public
  website content from `app/priv/`.
- `cli/`: active Rust CLI implementation, with release automation scoped to
  `cli/**`.
- `infra/`: infrastructure sources imported from the infra repository, including
  Helm platform charts, Kubernetes cluster assets, and Terraform.
- `deploy/`: application deployment chart and production values.
- `mobile/`: mobile app prototype.

## Getting Started

Visit [glossia.ai](https://glossia.ai) to learn more, or check out the [docs](https://glossia.ai/docs).

### Command Line Interface

Add Glossia to `mise.toml`:

```toml
[tools."http:glossia"]
version = "latest"
url = 'https://releases.glossia.ai/cli/{{ version }}/glossia-{{ os(macos="darwin") }}-{{ arch() }}.{{ os(windows="zip", macos="tar.gz", linux="tar.gz") }}'
version_list_url = "https://releases.glossia.ai/cli/versions.txt"
checksum_url = 'https://releases.glossia.ai/cli/{{ version }}/SHA256SUMS'
```

Then run:

```bash
mise install
mise exec -- glossia init
mise exec -- glossia translate
```

### Web App

```bash
cd app
mix setup
mix phx.server
```

### Command Line Interface Development

```bash
cd cli
mise exec -- cargo test --lib
mise exec -- cargo test --test e2e_translate
```

## Community

- [Forum](https://community.glossia.ai/)
- [Discord](https://discord.gg/7FRHkwvs)

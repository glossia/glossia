# Glossia

Glossia is a language OS for teams that ship continuously. It brings together
translation, shared voice and terminology, and localization analytics, with
content and review kept in your repository's delivery workflow.

Learn more and get started in the [documentation](https://glossia.ai/docs).

## License and editions

Glossia is open core: the application, CLI, SDK, and infrastructure outside
`ee/` are licensed under [Apache-2.0](LICENSE-APACHE), subject to third-party
notices and the exceptions in [LICENSE.md](LICENSE.md). Commercial use,
self-hosting, and hosted services are permitted under that license.

The [`ee/`](ee/) directory contains source-available enterprise code under
its [own license](ee/LICENSE.md). Production use requires a separate written
commercial agreement. Enterprise audit ingestion is the first code isolated
there; this checkout does not yet implement audit persistence or an audit UI.

Core is the default build. See [ee/README.md](ee/README.md) for enterprise build
instructions and [CONTRIBUTING.md](CONTRIBUTING.md) for contributions. A CLA is
required only for contributions to `ee/`, not the open-source core.

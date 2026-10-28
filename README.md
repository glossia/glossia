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
commercial agreement. **Isolated translation runners** live there: detached
Kubernetes Jobs, managed FLAME capacity, Kata-backed setup sandboxes, and
release-aware rollout checks. Community runs translations locally in Oban and
uses host-local setup workspaces for trusted repositories. Both editions retain
the translation engine, validation, progress, and publication workflow. The
Enterprise edition also includes **organization single sign-on** (Google
Workspace and Okta through OpenID Connect) and **administrator audit logs** with
PostgreSQL persistence and a searchable dashboard. Their implementation, UI,
assets, translations, and audit migration live in `ee/`. Basic OAuth login,
organizations, invitations, permissions, and ordinary revision history stay in
Community. See the [edition comparison](https://glossia.ai/docs/explanation/editions).

Core is the default build. See [ee/README.md](ee/README.md) for enterprise build
instructions and [CONTRIBUTING.md](CONTRIBUTING.md) for contributions. A CLA is
required only for contributions to `ee/`, not the open-source core.

## Application images and releases

Merges to `main` publish separate community and enterprise images after both
editions pass their application checks. App releases use `app-vX.Y.Z` tags and
publish `ghcr.io/glossia/glossia:X.Y.Z-community` and
`ghcr.io/glossia/glossia:X.Y.Z-enterprise`, with generated release notes.
`main-community` and `main-enterprise` track checked main builds; unsuffixed
`main` remains a community-only compatibility alias.

See [Application releases](.github/RELEASING.md) for versioning, image tags,
licensing, and retry behavior.

%{
  title: "Community and Enterprise",
  summary: "What is open source, what Enterprise adds, and how editions differ from hosting.",
  category: "explanation",
  section: "platform",
  order: 3
}
---

Glossia has two editions: **Community**, the open-source version, and
**Enterprise**, which includes Community plus additional access, audit, and
execution controls.

To self-host Glossia, choose your edition's OCI image from GitHub Container
Registry (GHCR):

- **Community:** `ghcr.io/glossia/glossia:latest-community`
- **Enterprise:** `ghcr.io/glossia/glossia:latest-enterprise`

Pin a versioned tag or image digest for production deployments.

## Community

Community includes the translation workflow and collaboration features:

- Repository translation, validation, progress tracking, and pull requests.
- Voice, glossary, and language memory.
- Organizations, invitations, and member permissions.
- Google, GitHub, and GitLab login.
- Localization analytics, REST API, MCP server, CLI, and SDK.

Organizations do not require Enterprise. Both editions use the same translation
engine and support the same languages and file formats.

## Enterprise

Enterprise adds three features:

- [Single sign-on](/docs/how-to/organization-sign-in): connect Google Workspace or
  Okta so verified work accounts can join your organization.
- [Audit logs](/docs/reference/audit-logs): let organization administrators search
  account changes and successful organization sign-ins.
- [Isolated translation runners](/docs/reference/isolated-translation-runners): run
  repository work outside the application host, with configurable placement and
  jobs that survive web deployments.

Documentation labels features **Community and Enterprise** or **Enterprise**
below their headings. Each feature's guide describes its requirements and limits.

## Where repository work runs

Community runs translations, validation commands, and project setup on the
application host as the application user. These workspaces are **not security
sandboxes**: repository commands can access the host environment and credentials.
Use them only with code you trust, even when hosting Community on Kubernetes.

Enterprise uses separate Kubernetes Jobs for translations and Pods for project
setup. MicroVM isolation additionally requires Kata and an explicitly configured
RuntimeClass; a separate Pod alone does not provide it. Translation jobs still
receive application credentials. Outside Kubernetes, Enterprise translations
fall back to local execution without isolation.

## Licensing and hosting

Both editions can be self-hosted. Community is licensed under
[Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), which
permits modification, redistribution, and commercial hosting.

Enterprise is **source-available, not open source**. Its
[Enterprise License](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md)
permits development, testing, and evaluation; production use requires a separate
written commercial agreement. Downloading the Enterprise image does not grant
production-use rights.

For building from source and contributing, see the repository's
[Enterprise guide](https://github.com/glossia/glossia/blob/main/ee/README.md).

%{
  title: "Community and Enterprise",
  summary: "What is open source, what Enterprise adds, and how editions differ from hosting.",
  category: "explanation",
  section: "platform",
  order: 3
}
---

Glossia has two editions. Community is the open-source foundation. Enterprise
includes Community and adds organization single sign-on, administrator audit
logs, and infrastructure features for running repository code outside the
application host.

## Compare editions

| Capability | Community | Enterprise |
|---|---|---|
| Repository translation and pull request publication | Included | Included |
| Voice, glossary, and language memory | Included | Included |
| REST API, MCP server, CLI, and SDK | Included | Included |
| Localization analytics | Included | Included |
| Organizations, invitations, and member permissions | Included | Included |
| Ordinary Google, GitHub, and GitLab login | Included | Included |
| Organization single sign-on with Google Workspace or Okta | Not included | Included, OpenID Connect with verified domains |
| Searchable administrator audit logs | Not included | Included, for new domain events after migration |
| Translation execution | Local Oban worker on the application host | Detached Kubernetes Job when running in a cluster |
| Jobs that outlive a web-pod rollout | Not included | Included |
| Dedicated runner placement and managed capacity | Not included | Included |
| Kata microVM isolation | Not included | Optional, requires a configured Kubernetes RuntimeClass |
| Automatic recovery on a healthy engine release | Not included | Included, for eligible failures |
| License | Apache-2.0 | Apache-2.0 core plus Enterprise License |

The infrastructure capabilities above are called
[Isolated translation runners](/features/isolated-translation-runners).
Both editions use the same translation engine, validation, progress tracking,
and publication workflow. Enterprise changes where work runs, not which languages
or file formats Community can translate.

## Local execution and trust

Community executes translations and repository validation commands on the
application host, as the application user. Automated project setup uses a local
workspace. These workspaces are not security sandboxes: repository commands can
access the host environment and its credentials. Use Community only with code
and validation commands you trust. It does not start Kubernetes Jobs or a remote
runner pool, even when the application itself runs in Kubernetes.

Enterprise moves translation work into detached Jobs and project setup into
sandbox Pods. A separate Pod is not automatically a microVM: kernel isolation
requires a supported runtime such as Kata and an explicitly configured
RuntimeClass. Read the [runner reference](/docs/reference/isolated-translation-runners)
for requirements and operational limits.

## Organization access and audit history

[Single sign-on](/docs/how-to/organization-sign-in) connects Google Workspace or
Okta to an organization after DNS domain verification. Verified identities join
with basic permissions. It does not enforce SSO-only login, implement SAML, or
provide SCIM provisioning. Existing login methods remain available.

[Audit logs](/docs/reference/audit-logs) record account changes and successful
organization sign-ins in PostgreSQL. Only the organization's administrators can
read them, even when the account is public. The dashboard has a separate
**Enterprise** navigation section for Authentication and Audit logs.

Audit logs do not replace the Community edition's voice and glossary versions,
translation-session history, product analytics, or operational logs. Earlier
activity is not backfilled. This implementation does not provide audit exports,
retention controls, or tamper-proof storage.

## Edition is separate from hosting

Community can be self-hosted, modified, redistributed, and offered as a commercial
hosted service under [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE).
Self-hosting is not an Enterprise-only feature.

Enterprise code is public in the repository's `ee/` directory, but is
**source-available, not open source**. Production use requires a separate written
commercial agreement under the
[Enterprise License](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md).
Development, testing, and evaluation are permitted under that license. This
checkout does not implement license-key activation; selecting an Enterprise
build does not grant production-use rights.

## Selecting a build

The default source build is Community (`GLOSSIA_EDITION=core`). Enterprise is
selected at build time with `GLOSSIA_EDITION=enterprise`; changing that variable
on an already compiled release does not change its edition. Community builds
do not compile the `ee/` directory or include the FLAME runner dependencies.

Published images are `ghcr.io/glossia/glossia:X.Y.Z-community` and
`ghcr.io/glossia/glossia:X.Y.Z-enterprise`. The `main-community` and
`main-enterprise` tags follow checked main builds; `main` is a Community alias.
Use a real release version in place of `X.Y.Z`, or pin an image digest.

Build and contribution instructions live in the repository's
[Enterprise boundary guide](https://github.com/glossia/glossia/blob/main/ee/README.md).
Documentation and feature pages label availability below their headings.
“Community and Enterprise” means the feature is part of the open-source core;
“Enterprise” means the Enterprise build is required.

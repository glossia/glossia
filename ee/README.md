# Glossia Enterprise

All material in this directory is governed by the [Glossia Enterprise License](LICENSE.md), not the Apache-2.0 core license. Production use requires a separate written commercial agreement. Development, testing, and evaluation are permitted as described in the license.

## Boundary

**Isolated translation runners** include the detached Kubernetes Job launcher,
Job boot role and supervision, managed FLAME pool, Kubernetes client,
Kata-backed project-setup adapter, and Deployment rollout verification. Their
implementations and tests live here. Core routes execution through
`Glossia.Extensions.translation_runtime/0`; the default runtime runs translation
inline in its Oban worker and starts no remote pool, even in Kubernetes. The
Enterprise build selects `GlossiaEnterprise.TranslationSessions.Runtime` and
`GlossiaEnterprise.Sandbox.KataAdapter` at compile time. FLAME dependencies are
included only in Enterprise builds.

Community setup workspaces run on the application host and are not a security
boundary. Use them only with trusted repositories. Enterprise microVM isolation
requires an installed and configured Kata RuntimeClass; an ordinary Pod alone
does not provide it. Detached translation Jobs still inherit application
credentials. Outside Kubernetes, Enterprise translations fall back to local
execution without isolation.

The public [edition comparison](https://glossia.ai/docs/explanation/editions)
and [runner reference](https://glossia.ai/docs/reference/isolated-translation-runners)
describe availability, requirements, and configuration.

**Organization single sign-on** includes Google Workspace and Okta OpenID Connect,
DNS verification and its renewal worker, provider callbacks, work-email login,
and authentication settings. Core's optional sign-in facade returns no
organization provider in Community, leaving ordinary OAuth login unchanged.
SSO does not currently include SAML, SCIM provisioning, or SSO-only enforcement.

**Audit logs** persist account-scoped domain events synchronously in PostgreSQL.
`Glossia.Events` calls the optional audit subscriber as well as the ordinary
analytics handler. Audit writes participate in the caller's transaction; a
failure raises, so operations without an enclosing transaction may already have
mutated data. Arbitrary event metadata and authentication credentials are not
stored. Only actual organization administrators can list records or filter
options, including on public accounts. Actor snapshots survive profile changes.

The audit schema and compiled migration live in `ee/lib/glossia_enterprise/audit/`.
Both `mix ecto.migrate` and `Glossia.Release.migrate/0` include Enterprise migration
modules only in Enterprise builds. Run migrations before starting a new release.
Existing activity and legacy ClickHouse rows are not backfilled. Audit exports,
retention management, tamper-proof storage, and license-key enforcement are not
implemented. Product analytics remains separate from audit storage.

Enterprise dashboard LiveViews, login components, and navigation live under
`ee/lib/glossia_enterprise_web/`; the main dashboard invokes its optional navigation
extension. Administrators see **Organization → Authentication / Audit logs**.
Enterprise CSS and Gettext catalogs live in `ee/assets/` and `ee/priv/gettext/`;
Community does not compile or bundle those surfaces. The shared locale hooks
set the process-wide locale so optional translation backends follow the user.

The Apache-2.0 core retains `Glossia.Events`, its event struct and handler
behaviour, ordinary activity and revision history, product analytics, OAuth
login, organizations, invitations, and permissions. Core compiles and starts
without `ee/`, audit persistence, Enterprise routes, or remote runners.

Put enterprise-only implementations, tests, and future migrations or assets under `ee/`. Add extension points in core rather than referencing enterprise implementations directly. Do not move core security checks, ordinary activity history, or operational logs into enterprise merely because they emit events.

## Build and test

From `app/`:

```sh
# Default, with no enterprise source compiled.
MIX_BUILD_PATH=_build/core-dev mix compile
MIX_BUILD_PATH=_build/core-test mix test

# Includes ../ee/lib and ../ee/test, with the core test helper.
GLOSSIA_EDITION=enterprise MIX_BUILD_PATH=_build/enterprise-dev mix compile
GLOSSIA_EDITION=enterprise MIX_BUILD_PATH=_build/enterprise-test mix test

# Formatting covers both directories.
mix format --check-formatted
```

Use separate build paths when switching editions so compiled enterprise modules cannot remain in a core build. The edition is selected at build time, not by changing an environment variable on an already compiled release. Enterprise test discovery uses a small `ee/test/test_helper.exs` shim that loads `app/test/test_helper.exs` for shared setup.

Also use separate build paths for dev and test when overriding `MIX_BUILD_PATH`.
For example, use `_build/enterprise-dev` for compilation and
`_build/enterprise-test` for tests to avoid mixing consolidated protocols.

Refresh translation catalogs from `app/` in an Enterprise build so both backends
are extracted: `GLOSSIA_EDITION=enterprise mix gettext.extract --merge`. Core and
Enterprise builds must each pass `mix gettext.extract --merge --check-up-to-date`.

The default published `ghcr.io/glossia/glossia:main` image and Helm chart use the Apache-2.0 core (community edition), also tagged `:main-community`. The separately published `:main-enterprise` image includes enterprise code and requires the enterprise agreement for production use. Glossia's own production HelmRelease explicitly selects that enterprise tag.

Versioned app releases publish both `:X.Y.Z-community` and `:X.Y.Z-enterprise` from the same tested commit, with shared git-cliff release notes under an `app-vX.Y.Z` tag. See [Application releases](../.github/RELEASING.md) for stable tags and publication behavior.

To build enterprise code explicitly, use these named Docker contexts:

```sh
docker build -f app/Dockerfile \
  --build-context cli=./cli \
  --build-context sdk=./sdk \
  --build-context ee=./ee \
  --build-context licensing=. \
  --build-arg GLOSSIA_EDITION=enterprise \
  app
```

For a core image, omit both `--build-arg GLOSSIA_EDITION=enterprise` and `--build-context ee=./ee`. BuildKit prunes the enterprise-only source stage, so neither the enterprise sources nor their license are copied into the image. The core image can be built from a source checkout with `ee/` removed.

## Contributions

Only contributions to `ee/` require the [Enterprise CLA](../CLA.md). The privileged GitHub workflow checks enterprise paths using the API, including deleted files and both sides of renames. CLA Assistant collects signatures in `signatures/v2/cla.json` on the same repository's `cla-signatures` branch. See [CONTRIBUTING.md](../CONTRIBUTING.md) for signing and repository-rule setup.

## Legal review before commercial rollout

The Enterprise License and CLA are custom terms, not a legal sign-off. The CLA
remains a draft and its workflow blocks external Enterprise contributions until
legal review is complete. Do not remove that safeguard just because tests pass.

Before relying on the Enterprise License for a commercial rollout, have qualified
software-licensing counsel review:

- **Licensor and contributions.** Confirm the correct rights holder and the CLA's
  copyright, patent, employer, and contractor permissions. Existing grants remain
  intact; moving files or collecting new signatures does not revoke earlier
  permissions or retroactively cover old contributions.
- **Customer agreements.** Prepare the separate production agreement referenced
  by the license, with the correct contracting entity, deployment and usage
  rights, support terms, liability, termination, and governing law. Confirm the
  public evaluation terms, including the 30-day breach-remedy provision, work
  under the relevant jurisdictions. The public license is not a subscription
  agreement or a data-processing agreement.
- **Third-party distribution.** Inventory dependencies, bundled tools, fonts,
  assets, and base-image packages. Preserve required notices and satisfy any
  source or redistribution obligations in the actual OCI images. Including the
  Glossia license files alone does not establish compliance for those components.

The repository's license and CLA checks verify workflow and packaging rules,
not ownership, third-party license compatibility, or legal enforceability.

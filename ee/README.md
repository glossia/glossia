# Glossia Enterprise

All material in this directory is governed by the [Glossia Enterprise License](LICENSE.md), not the Apache-2.0 core license. Production use requires a separate written commercial agreement. Development, testing, and evaluation are permitted as described in the license.

## Boundary

The first enterprise code is the audit ingestion row schema and its buffer supervision extension. These previously lived in `app/lib/glossia/ingestion/event.ex` and the application's supervision trees. The schema retains the legacy ClickHouse `events` row format. The table may have been removed by the historical default-sink migration; this extension does not recreate it.

This checkout does **not** contain an audit-event persistence handler, a migration creating the audit table, an audit-log UI, retention management, exports, or license-key enforcement. Moving the existing ingestion pieces here does not enable those capabilities. In particular, compiling enterprise code does not turn product analytics into an audit log.

The Apache-2.0 core retains `Glossia.Events`, its event struct and handler behaviour, the default no-op handler, and product analytics. Core compiles and starts without `ee/`; it does not start an audit buffer. Optional enterprise child processes are supplied through `Glossia.Extensions.audit_children/0` and the `:audit_extension` configuration key.

Put enterprise-only implementations, tests, and future migrations or assets under `ee/`. Add extension points in core rather than referencing enterprise implementations directly. Do not move core security checks, ordinary activity history, or operational logs into enterprise merely because they emit events.

## Build and test

From `app/`:

```sh
# Default, with no enterprise source compiled.
MIX_BUILD_PATH=_build/core mix compile
MIX_BUILD_PATH=_build/core mix test

# Includes ../ee/lib and ../ee/test, with the core test helper.
GLOSSIA_EDITION=enterprise MIX_BUILD_PATH=_build/enterprise mix compile
GLOSSIA_EDITION=enterprise MIX_BUILD_PATH=_build/enterprise mix test

# Formatting covers both directories.
mix format --check-formatted
```

Use separate build paths when switching editions so compiled enterprise modules cannot remain in a core build. The edition is selected at build time, not by changing an environment variable on an already compiled release. Enterprise test discovery uses a small `ee/test/test_helper.exs` shim that loads `app/test/test_helper.exs` for shared setup.

The default published `ghcr.io/glossia/glossia:main` image and Helm chart use the Apache-2.0 core. The separately published `:main-enterprise` image includes enterprise code and requires the enterprise agreement for production use. Glossia's own production HelmRelease explicitly selects that enterprise tag.

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

The enterprise license and CLA should receive legal review before a commercial rollout or acceptance of external enterprise contributions. Existing contribution rights must be checked separately; neither moving files nor collecting new signatures retroactively relicenses older work.

# CLI Release

The Glossia CLI auto-releases from `main` whenever a conventional commit
touches `cli/**` and qualifies for a semver bump (`feat:`, `fix:`, etc.).

## Flow

1. On every push to `main`, the `Release` workflow runs `git cliff` with
   `--include-path "cli/**" --unreleased --bump`. If the unreleased
   section contains any release notes, the workflow proceeds.
2. `git cliff --bumped-version` computes the next tag (e.g. `cli-v0.16.0`)
   from the latest `cli-v*` tag.
3. `cli/CHANGELOG.md` is regenerated from history, committed as
   `[Release] glossia cli-v<version>`, and tagged.
4. Cross-platform CLI archives + checksums are built.
5. Artifacts are uploaded to S3 under `<prefix>/<version>/` and
   `<prefix>/latest/` (when S3 is configured), the release commit and
   tag are pushed, and a GitHub Release is created.
6. An `aquaproj/aqua-registry` PR is opened (when configured).

## Manual override

`workflow_dispatch` accepts an optional `version` input (e.g. `0.16.0`)
to force a specific version instead of the auto-bump.

## Required GitHub Secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AQUA_REGISTRY_GITHUB_TOKEN` (optional, for aqua-registry PRs)

## Required GitHub Variables

- `RELEASE_AWS_REGION` (example: `us-east-1`)
- `RELEASE_S3_BUCKET` (bucket name only)
- `RELEASE_BASE_URL` (public HTTP base URL for downloads, no trailing slash)

## Optional GitHub Variables

- `RELEASE_S3_PREFIX` (path prefix inside bucket)
- `RELEASE_S3_ENDPOINT` (for S3-compatible endpoints)
- `AQUA_REGISTRY_FORK` (fork in `owner/aqua-registry` form)

## Tag and version conventions

- Tag format: `cli-v<MAJOR>.<MINOR>.<PATCH>` (e.g. `cli-v0.16.0`).
- Version (used in S3 paths and Aqua registry): `<MAJOR>.<MINOR>.<PATCH>`.
- Conventional commits drive bumps: `feat:` → minor, `fix:`/`refactor:`/etc. → patch,
  `feat!:`/`BREAKING CHANGE:` → major. `chore:`, `ci:`, and `build:` are skipped.

## Artifact layout

Each release version publishes:

- `glossia-linux-x64.tar.gz`
- `glossia-linux-arm64.tar.gz`
- `glossia-darwin-x64.tar.gz`
- `glossia-darwin-arm64.tar.gz`
- `glossia-windows-x64.zip`
- `SHA256SUMS`
- `SHA512SUMS`

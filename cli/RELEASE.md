# CLI Release

The release workflow does not create GitHub Releases.

## What it does

1. Generates `cli/CHANGELOG.md` with `git-cliff`.
2. Builds cross-platform CLI archives.
3. Uploads archives and checksums to S3 under:

- `/<prefix>/<version>/`
- `/<prefix>/latest/`

4. Tags the release commit.
5. Optionally opens a PR to `aquaproj/aqua-registry`.

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

## Artifact layout

Each release version publishes:

- `glossia-linux-x64.tar.gz`
- `glossia-linux-arm64.tar.gz`
- `glossia-darwin-x64.tar.gz`
- `glossia-darwin-arm64.tar.gz`
- `glossia-windows-x64.zip`
- `SHA256SUMS`
- `SHA512SUMS`

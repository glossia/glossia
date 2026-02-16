%{
  title: "Releases",
  summary: "CLI release history and download links.",
  category: "reference",
  subcategory: "cli",
  order: 2
}
---

Glossia CLI releases are published as pre-built executables for all major platforms. Each release is uploaded to S3 and made available via direct download or the [aqua](https://aquaproj.github.io/) package manager.

## Install via aqua

If you use aqua, install the CLI with:

```bash
aqua g -i glossia/glossia
```

Aqua handles platform detection and version management automatically.

## Direct download

Every release publishes five platform-specific archives:

| Platform | Archive |
|----------|---------|
| Linux x64 | `glossia-linux-x64.tar.gz` |
| Linux ARM64 | `glossia-linux-arm64.tar.gz` |
| macOS x64 | `glossia-darwin-x64.tar.gz` |
| macOS ARM64 | `glossia-darwin-arm64.tar.gz` |
| Windows x64 | `glossia-windows-x64.zip` |

Each archive contains a single `glossia` binary (or `glossia.exe` on Windows) ready to use.

Each release directory also contains `SHA256SUMS` and `SHA512SUMS` files for verification.

## macOS Gatekeeper

When you download a binary via a browser on macOS, the system adds a quarantine attribute that triggers a "damaged and can't be opened" error. Remove it after extracting:

```bash
xattr -c glossia
```

## Verify checksums

After downloading an archive, verify its integrity:

```bash
# Download the checksums file
curl -O https://releases.glossia.ai/cli/latest/SHA256SUMS

# Verify your download
shasum -a 256 -c SHA256SUMS --ignore-missing
```

## Changelog

The full changelog is maintained at [`cli/CHANGELOG.md`](https://github.com/glossia/glossia/blob/main/cli/CHANGELOG.md) in the repository. It follows a manually-maintained format where each release lists changes grouped by category: Features, Bug Fixes, Performance, Refactors, Documentation, and Chores.

## Release process

Releases are cut locally using `mise run cli/release`, which:

1. Parses the `## NEXT` section of the changelog
2. Determines the version bump (minor for new features, patch otherwise)
3. Builds platform executables via Go
4. Packages and uploads archives to S3
5. Commits the version bump and tags the release

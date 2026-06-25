# Command Line Interface Release

The Glossia monorepo auto-releases the command line interface from `main`
whenever a conventional commit touching `cli/**` qualifies for a semver bump
(`feat:`, `fix:`, etc.).

The release workflow lives at `.github/workflows/release.yml` and uses the root
`cliff.toml` config. Command line releases use the `cli-v*` tag line.

## Flow

1. On every push to `main`, the `Release` workflow runs `git cliff` with
   `--include-path 'cli/**' --unreleased --bump`. If the unreleased section
   contains command line release notes, the workflow proceeds.
2. `git cliff --include-path 'cli/**' --bumped-version` computes the next tag
   (for example `cli-v0.16.0`) from the latest command line release tag.
3. `CHANGELOG.md` is regenerated from history, committed as
   `[Release] glossia <tag>`, and tagged.
4. Cross-platform command line archives + checksums are built.
5. The release commit and tag are pushed.
6. The release job reads the generated `glossia-releases` bucket credentials
   from 1Password and uploads the archives + checksum files to public object
   storage at:

   - `https://releases.glossia.ai/cli/<version>/`
   - `https://releases.glossia.ai/cli/latest/`

The release notes are rendered by `git-cliff` using a dedicated release-notes
template and GitHub pull request metadata.

## Manual override

`workflow_dispatch` accepts an optional `version` input (for example `0.16.0`)
to force a specific version instead of the auto-bump.

## Tag and version conventions

- Tag format: `cli-v<MAJOR>.<MINOR>.<PATCH>` (for example `cli-v0.16.0`).
- Version (used in release metadata and artifact names): `<MAJOR>.<MINOR>.<PATCH>`.
- Conventional commits drive bumps: `feat:` means minor,
  `fix:`/`refactor:`/etc. mean patch, and `feat!:` or `BREAKING CHANGE:` means
  major. `chore:`, `ci:`, and `build:` are skipped.

## Artifact layout

Each release version publishes:

- `glossia-linux-x64.tar.gz`
- `glossia-linux-arm64.tar.gz`
- `glossia-darwin-x64.tar.gz`
- `glossia-darwin-arm64.tar.gz`
- `glossia-windows-x64.zip`
- `SHA256SUMS`
- `SHA512SUMS`
- `RELEASE_NOTES.md`

These files are uploaded under `cli/<version>/` and mirrored to `cli/latest/`.

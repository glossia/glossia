# Command Line Interface Release

The Glossia monorepo auto-releases the command line interface from `main`
whenever a conventional commit touching `cli/**` qualifies for a semver bump
(`feat:`, `fix:`, etc.).

The release workflow lives at `.github/workflows/release.yml` and uses the root
`cliff.toml` config. Command line releases use the `cli-v*` tag line.

## Flow

1. On every push to `main`, the `Release` workflow runs `git cliff` with
   `--include-path 'cli/**'`, excluding release bookkeeping files. If the
   unreleased section contains command line release notes, the workflow
   proceeds.
2. `git cliff --include-path 'cli/**' --bumped-version` computes the next tag
   (for example `cli-v0.17.0`) from the latest command line release tag.
3. Cross-platform command line archives + checksums are built.
4. The release tag is pushed.
5. The release job reads the generated `glossia-releases` bucket credentials
   from 1Password and uploads the archives, checksum files, release notes, and
   browser index page to public object storage at:

   - `https://releases.glossia.ai/cli/<version>/`
   - `https://releases.glossia.ai/cli/latest/`
6. A GitHub Release is created or updated for the tag using the generated
   release notes.

GitHub Releases are the source of truth for command line release history. The
published object storage includes a copy of the release notes next to the
archives so installers can consume the same notes without GitHub access.

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
- `index.html`

These files are uploaded under `cli/<version>/` and mirrored to `cli/latest/`.
The generated `index.html` file is also uploaded as the trailing-slash object
for each prefix, so opening `https://releases.glossia.ai/cli/latest/` in a
browser shows the file list instead of the object storage error page.

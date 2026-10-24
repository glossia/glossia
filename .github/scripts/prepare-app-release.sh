#!/usr/bin/env bash
# Run from the repository root, after checking out the tested main commit with full history.
set -euo pipefail

# No per-commit API enrichment: version detection and PR links work offline.
export GITHUB_TOKEN="" GH_TOKEN=""

filter=(
  --config app/cliff.toml
  --use-branch-tags
  --include-path 'app/**'
  --include-path 'ee/**'
  # These sources and licenses are also copied into the application image.
  --include-path 'cli/**'
  --include-path 'sdk/web/**'
  --include-path 'LICENSE.md'
  --include-path 'LICENSE-APACHE'
  --exclude-path 'app/CHANGELOG.md'
)

context="$(git cliff "${filter[@]}" --unreleased --context)"
commit_count="$(jq '[.[].commits[]] | length' <<< "$context")"
previous_tag="$(jq -r '.[0].previous.version // "app-v0.1.0"' <<< "$context")"

if [[ "$commit_count" == 0 ]]; then
  printf 'should_release=false\nbuild_version=%s\n' "${previous_tag#app-v}" >> "$GITHUB_OUTPUT"
  exit 0
fi

tag="$(git cliff "${filter[@]}" --bumped-version)"
if [[ ! "$tag" =~ ^app-v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid app release tag: $tag" >&2
  exit 1
fi
version="${tag#app-v}"
git cliff "${filter[@]}" --unreleased --tag "$tag" --output app-release-notes.md

# Both editions share a version, changelog, and tested source commit.
{
  printf 'should_release=true\ntag_name=%s\nversion=%s\nbuild_version=%s\n' "$tag" "$version" "$version"
} >> "$GITHUB_OUTPUT"

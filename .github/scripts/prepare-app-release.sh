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

# Bump from the context's previous tag instead of `--bumped-version`. With
# --include-path, git-cliff drops a tag placed on a commit outside those paths
# and bumps from the tag before it, recomputing a version that already exists.
if [[ ! "$previous_tag" =~ ^app-v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Invalid previous app release tag: $previous_tag" >&2
  exit 1
fi
major="${BASH_REMATCH[1]}" minor="${BASH_REMATCH[2]}" patch="${BASH_REMATCH[3]}"
if [[ "$(jq -r '.[0].previous.version // empty' <<< "$context")" == "" ]]; then
  # No app release yet: the first one is the initial tag itself.
  tag="$previous_tag"
else
  # git-cliff's defaults: breaking changes bump major, features bump minor.
  case "$(jq -r '[.[].commits[]] | if any(.breaking) then "major" elif any(.group | test("Features")) then "minor" else "patch" end' <<< "$context")" in
    major) tag="app-v$((major + 1)).0.0" ;;
    minor) tag="app-v${major}.$((minor + 1)).0" ;;
    *) tag="app-v${major}.${minor}.$((patch + 1))" ;;
  esac
fi
version="${tag#app-v}"
git cliff "${filter[@]}" --unreleased --tag "$tag" --output app-release-notes.md

# Both editions share a version, changelog, and tested source commit.
{
  printf 'should_release=true\ntag_name=%s\nversion=%s\nbuild_version=%s\n' "$tag" "$version" "$version"
} >> "$GITHUB_OUTPUT"

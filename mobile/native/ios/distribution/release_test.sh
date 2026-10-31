#!/usr/bin/env bash
# Exercise real git-cliff calculations in disposable Git histories, as in Habibi.
set -euo pipefail
SOURCE=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/glossia-ios-release.XXXXXX")
trap 'rm -rf "$fixture"' EXIT
unset GITHUB_OUTPUT
export GIT_AUTHOR_DATE=2026-01-01T00:00:00Z GIT_COMMITTER_DATE=2026-01-01T00:00:00Z
git init -q -b main "$fixture"
git -C "$fixture" config user.name 'Release Test'
git -C "$fixture" config user.email release@example.invalid
git -C "$fixture" config commit.gpgsign false
git -C "$fixture" config tag.gpgsign false
git -C "$fixture" config core.hooksPath /dev/null
mkdir -p "$fixture/mobile/native/ios/distribution" "$fixture/app" "$fixture/mobile/src"
cp "$SOURCE/mobile/native/cliff.toml" "$fixture/mobile/native/cliff.toml"
cp "$SOURCE/mobile/native/ios/distribution/check.sh" "$fixture/mobile/native/ios/distribution/check.sh"
check="$fixture/mobile/native/ios/distribution/check.sh"

reject() {
  if bash "$check" >/dev/null 2>&1; then
    echo "Invalid release inputs were accepted" >&2; exit 1
  fi
}
change() {
  printf '%s\n' "$2" >> "$fixture/$1"
  git -C "$fixture" add .
  git -C "$fixture" commit -qm "$2"
}
expect() {
  local output
  output=$(bash "$check")
  grep -qx "should-release=$1" <<< "$output"
  grep -qx "next-version=ios@$2" <<< "$output"
  grep -qx "next-version-number=$2" <<< "$output"
}

reject # Unborn HEAD.
change app/server.txt 'chore: initialize fixture'
expect false ''
for tag in app-v90.0.0 cli-v80.0.0 sdk-v70.0.0; do git -C "$fixture" tag "$tag"; done
change mobile/native/app.txt 'feat: introduce native clients (#123)'
expect true 0.1.0
bash "$check" notes | grep -q 'https://github.com/glossia/glossia/pull/123'
git -C "$fixture" tag ios@0.1.0
expect false 0.1.0
change app/server.txt 'feat: unrelated server feature'
change mobile/src/prototype.txt 'fix: unrelated Expo change'
change mobile/native/app.txt 'chore: internal maintenance'
expect false 0.1.0
change mobile/native/app.txt 'fix: correct device startup'
expect true 0.1.1
bash "$check" notes | grep -q 'correct device startup'
git -C "$fixture" tag ios@0.1.1
git -C "$fixture" tag ios@0.0.9
expect false 0.1.1
change mobile/native/app.txt 'feat: add a native feature'
expect true 0.2.0
git -C "$fixture" tag ios@0.2.0
change mobile/native/app.txt 'feat!: change the native protocol'
git -C "$fixture" tag ios@99.0.0-rc.1
expect true 1.0.0
git -C "$fixture" checkout -qb unrelated
change mobile/native/app.txt 'feat: only on another branch'
git -C "$fixture" tag ios@99.0.0
git -C "$fixture" checkout -q main
expect true 1.0.0
git -C "$fixture" tag ios@1.0.0
git -C "$fixture" checkout -qb feature
change mobile/native/app.txt 'feat: release a merged feature'
git -C "$fixture" checkout -q main
git -C "$fixture" merge -q --no-ff feature -m 'Merge pull request #1 from feature'
expect true 1.1.0
git -C "$fixture" tag ios@1.1.0
change mobile/native/app.txt $'fix: replace the native protocol\n\nBREAKING CHANGE: retire old clients'
expect true 2.0.0
git -C "$fixture" tag ios@2.0.0
mkdir -p "$fixture/.github/workflows"
change .github/workflows/ios-release.yml 'fix: repair iOS distribution'
expect true 2.0.1
touch "$fixture/uncommitted"
reject
rm "$fixture/uncommitted"
printf '\ninvalid = [\n' >> "$fixture/mobile/native/cliff.toml"
git -C "$fixture" add .
git -C "$fixture" commit -qm 'ci: invalid configuration fixture'
reject
echo 'iOS release fixtures passed: independent tags/paths, bootstrap, merges, bumps and failures'

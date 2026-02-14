#!/usr/bin/env bash
#MISE description="Release the CLI: bump version, build, upload to S3, commit & tag"
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CLI_DIR="$ROOT/cli"
CHANGELOG="$CLI_DIR/CHANGELOG.md"
VERSION_FILE="$CLI_DIR/src/version.ts"
PACKAGE_JSON="$CLI_DIR/package.json"
DIST_DIR="$CLI_DIR/dist/bin"

# ---------- helpers ----------

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required but not found in PATH"
}

# ---------- 1. validate prerequisites ----------

require_cmd bun
require_cmd aws
require_cmd fnox

# ---------- 2. check NEXT section has entries ----------

next_block=$(awk '/^## NEXT/{found=1; next} /^## [0-9]/{found=0} found' "$CHANGELOG")

has_entries=false
while IFS= read -r line; do
  # skip blank lines and sub-heading lines
  if [[ -z "$line" ]] || [[ "$line" =~ ^### ]]; then
    continue
  fi
  has_entries=true
  break
done <<< "$next_block"

if ! $has_entries; then
  die "No entries under ## NEXT in $CHANGELOG. Add changelog entries before releasing."
fi

# ---------- 3. calculate next version ----------

current_version=$(sed -n 's/.*VERSION = "\([^"]*\)".*/\1/p' "$VERSION_FILE")
if [[ -z "$current_version" ]]; then
  die "Could not parse current version from $VERSION_FILE"
fi

IFS='.' read -r major minor patch <<< "$current_version"

# Check if there are any Features entries
if echo "$next_block" | grep -q '### Features' && \
   echo "$next_block" | awk '/### Features/{found=1; next} /^### /{found=0} found' | grep -q '^\- '; then
  minor=$((minor + 1))
  patch=0
else
  patch=$((patch + 1))
fi

new_version="${major}.${minor}.${patch}"
today=$(date +%Y-%m-%d)

printf 'Current version: %s\n' "$current_version"
printf 'New version:     %s\n' "$new_version"

# ---------- 4. update CHANGELOG ----------

# Build the cleaned NEXT block: remove empty sub-headings
cleaned_block=""
current_heading=""
current_entries=""

while IFS= read -r line; do
  if [[ "$line" =~ ^### ]]; then
    # Flush previous heading+entries if entries exist
    if [[ -n "$current_heading" ]] && [[ -n "$current_entries" ]]; then
      cleaned_block+="${current_heading}"$'\n'"${current_entries}"
    fi
    current_heading="$line"
    current_entries=""
  elif [[ -n "$line" ]]; then
    current_entries+="${line}"$'\n'
  fi
done <<< "$next_block"

# Flush last heading
if [[ -n "$current_heading" ]] && [[ -n "$current_entries" ]]; then
  cleaned_block+="${current_heading}"$'\n'"${current_entries}"
fi

# Build new changelog content
{
  echo "# Changelog"
  echo ""
  echo "All notable changes to this project will be documented in this file."
  echo ""
  echo "## NEXT"
  echo ""
  echo "### Features"
  echo ""
  echo "### Bug Fixes"
  echo ""
  echo "## ${new_version} - ${today}"
  echo ""
  echo "$cleaned_block"
  # Append everything after the old NEXT block (existing versions)
  awk '/^## [0-9]/{found=1} found' "$CHANGELOG"
} > "${CHANGELOG}.tmp"

mv "${CHANGELOG}.tmp" "$CHANGELOG"

# ---------- 5. bump version files ----------

sed -i '' "s/VERSION = \"${current_version}\"/VERSION = \"${new_version}\"/" "$VERSION_FILE"

# Update package.json version using a temporary file to avoid issues
tmp_pkg=$(mktemp)
sed "s/\"version\": \"${current_version}\"/\"version\": \"${new_version}\"/" "$PACKAGE_JSON" > "$tmp_pkg"
mv "$tmp_pkg" "$PACKAGE_JSON"

printf 'Bumped version in %s and %s\n' "$VERSION_FILE" "$PACKAGE_JSON"

# ---------- 6. build executables ----------

printf 'Installing dependencies...\n'
(cd "$CLI_DIR" && bun install --frozen-lockfile)

printf 'Building executables...\n'
(cd "$CLI_DIR" && bun run build:exe)

# ---------- 7. package archives ----------

RELEASE_DIR="$ROOT/tmp/release"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

platforms=(
  "glossia-linux-x64"
  "glossia-linux-arm64"
  "glossia-darwin-x64"
  "glossia-darwin-arm64"
  "glossia-windows-x64.exe"
)

STAGING_DIR="$ROOT/tmp/release-staging"

for bin in "${platforms[@]}"; do
  src="$DIST_DIR/$bin"
  if [[ ! -f "$src" ]]; then
    die "Expected binary not found: $src"
  fi

  # Archive name keeps the platform suffix, but the binary inside is just "glossia"
  name="${bin%.exe}"
  rm -rf "$STAGING_DIR"
  mkdir -p "$STAGING_DIR"

  if [[ "$bin" == *windows* ]]; then
    cp "$src" "$STAGING_DIR/glossia.exe"
    archive="$RELEASE_DIR/${name}.zip"
    (cd "$STAGING_DIR" && zip -j "$archive" "glossia.exe")
  else
    cp "$src" "$STAGING_DIR/glossia"
    # Strip macOS quarantine attribute so downloaded binaries work without Gatekeeper errors
    xattr -c "$STAGING_DIR/glossia" 2>/dev/null || true
    archive="$RELEASE_DIR/${name}.tar.gz"
    tar -czf "$archive" -C "$STAGING_DIR" "glossia"
  fi
done

rm -rf "$STAGING_DIR"

printf 'Packaged %d archives in %s\n' "${#platforms[@]}" "$RELEASE_DIR"

# ---------- 8. generate checksums ----------

(cd "$RELEASE_DIR" && shasum -a 256 *.tar.gz *.zip > SHA256SUMS 2>/dev/null || shasum -a 256 *.tar.gz > SHA256SUMS)
(cd "$RELEASE_DIR" && shasum -a 512 *.tar.gz *.zip > SHA512SUMS 2>/dev/null || shasum -a 512 *.tar.gz > SHA512SUMS)

printf 'Generated checksums\n'

# ---------- 9. load S3 credentials ----------

export AWS_ACCESS_KEY_ID="$(fnox get RELEASE_S3_ACCESS_KEY_ID)"
export AWS_SECRET_ACCESS_KEY="$(fnox get RELEASE_S3_SECRET_ACCESS_KEY)"
export AWS_DEFAULT_REGION="$(fnox get RELEASE_S3_REGION)"

s3_bucket="$(fnox get RELEASE_S3_BUCKET)"
s3_prefix="$(fnox get RELEASE_S3_PREFIX 2>/dev/null || true)"
s3_endpoint="$(fnox get RELEASE_S3_ENDPOINT 2>/dev/null || true)"

endpoint_flag=()
if [[ -n "$s3_endpoint" ]]; then
  endpoint_flag=(--endpoint-url "$s3_endpoint")
fi

s3_base="s3://${s3_bucket}"
if [[ -n "$s3_prefix" ]]; then
  s3_base="${s3_base}/${s3_prefix}"
fi

# ---------- 10. upload to S3 ----------

printf 'Uploading to S3...\n'

for file in "$RELEASE_DIR"/*; do
  fname=$(basename "$file")
  aws s3 cp "$file" "${s3_base}/cli/${new_version}/${fname}" "${endpoint_flag[@]}"
  aws s3 cp "$file" "${s3_base}/cli/latest/${fname}" "${endpoint_flag[@]}"
done

printf 'Uploaded to %s/cli/%s/ and %s/cli/latest/\n' "$s3_base" "$new_version" "$s3_base"

# ---------- 11. git commit and tag ----------

git add "$CHANGELOG" "$VERSION_FILE" "$PACKAGE_JSON"
git commit -m "$(cat <<EOF
release(cli): ${new_version}
EOF
)"

git tag -m "release(cli): ${new_version}" "cli-v${new_version}"

printf '\nReleased CLI v%s\n' "$new_version"
printf 'Run "git push && git push --tags" to publish.\n'

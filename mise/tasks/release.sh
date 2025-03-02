#!/usr/bin/env bash
#MISE description="Releases a new version of the project if needed."

set -eo pipefail

bumped_changelog_hash=$(echo -n "$(git cliff --bump --unreleased)" | shasum -a 256 | awk '{print $1}')
current_changelog_hash=$(echo -n "$(cat CHANGELOG.md)" | shasum -a 256 | awk '{print $1}')

if [ "$bumped_changelog_hash" == "$current_changelog_hash" ]; then
    echo "No releasable changes detected. Exiting earlier..."
    exit 0
fi

next_version=$(git cliff --bumped-version)

# Updating the CHANGELOG.md
git cliff --bump -o CHANGELOG.md
git add CHANGELOG.md
git commit -m "[Release] Glossia $next_version"
git tag "$next_version"
git push origin "$next_version"

release_notes=$(git cliff --latest)

PAYLOAD=$(jq -n \
  --arg tag_name "$next_version" \
  --arg name "$next_version" \
  --arg body "$release_notes" \
  --argjson draft false \
  --argjson prerelease false \
  '{
    tag_name: $tag_name,
    name: $name,
    body: $body,
    draft: $draft,
    prerelease: $prerelease
  }')

# Make API request to create the release
RESPONSE=$(curl -s -X POST "https://codeberg.org/api/v1/repos/glossia/glossia/releases" \
  -H "Authorization: token $GLOSSIA_CODEBERG_WORKFLOWS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if echo "$RESPONSE" | grep -q '"id":'; then
    echo "Release created successfully!"
else
    echo "Failed to create release. Response:"
    echo "$RESPONSE"
fi

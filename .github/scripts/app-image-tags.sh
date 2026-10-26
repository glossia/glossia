#!/usr/bin/env bash
# Generate both explicit edition tags and backwards-compatible community aliases.
set -euo pipefail

case "$EDITION" in
  core) flavor=community; suffix="" ;;
  enterprise) flavor=enterprise; suffix=-enterprise ;;
  *) echo "Unknown edition: $EDITION" >&2; exit 1 ;;
esac

if [[ -n "${VERSION:-}" && ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid release version: $VERSION" >&2
  exit 1
fi

tags=(
  "$IMAGE:$REVISION$suffix"
  "$IMAGE:main$suffix"
  "$IMAGE:main-$RUN_NUMBER-$REVISION$suffix"
)
if [[ "$EDITION" == core ]]; then
  tags+=("$IMAGE:$REVISION-community" "$IMAGE:main-community" "$IMAGE:main-$RUN_NUMBER-$REVISION-community")
fi
if [[ -n "${VERSION:-}" ]]; then
  tags+=("$IMAGE:$VERSION-$flavor" "$IMAGE:latest-$flavor")
  if [[ "$EDITION" == core ]]; then
    tags+=("$IMAGE:$VERSION" "$IMAGE:latest")
  fi
fi

{
  printf 'tags<<EOF\n'
  printf '%s\n' "${tags[@]}"
  printf 'EOF\n'
} >> "$GITHUB_OUTPUT"

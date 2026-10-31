#!/usr/bin/env bash
#MISE description="Calculate the next independent iOS release without publishing"
set -euo pipefail

ROOT=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
git -C "$ROOT" rev-parse --verify HEAD >/dev/null
if [[ -n $(git -C "$ROOT" status --porcelain) ]]; then
  echo "Release inputs must be committed; the worktree is not clean." >&2
  exit 1
fi

# Like Habibi, keep native releases independent of server, CLI and SDK tags.
export GITHUB_TOKEN="" GH_TOKEN=""
cliff=(git cliff --repository "$ROOT" --config "$ROOT/mobile/native/cliff.toml" --use-branch-tags)
for path in 'mobile/native/**/*' '.github/workflows/ios-release.yml'; do
  cliff+=(--include-path "$path")
done
latest=$(git -C "$ROOT" tag --merged HEAD --list 'ios@*' |
  jq -Rrs 'split("\n") | map(select(test("^ios@[0-9]+\\.[0-9]+\\.[0-9]+$")))
    | sort_by(split("@")[1] | split(".") | map(tonumber)) | last // ""')

run_cliff() {
  if [[ -n "$latest" ]]; then
    "${cliff[@]}" --tag-pattern "^${latest//./\.}$" "$@" -- "${latest}..HEAD"
  else
    "${cliff[@]}" "$@"
  fi
}

context=$(run_cliff --unreleased --context |
  jq 'map(.commits |= map(.message = .raw_message))')
# Select the exact baseline above, but validate the next tag against the full
# configured pattern. git-cliff 2.10 rejects bumps with an exact baseline regex.
# Restore conventional messages: serialized `message` contains only descriptions,
# whereas its version calculator reads `message`, not `raw_message`.
from_context=(git cliff --config "$ROOT/mobile/native/cliff.toml" --from-context /dev/stdin)
count=$(jq '[.[].commits[]] | length' <<< "$context")
should_release=true
if [[ "$count" == 0 ]]; then
  should_release=false
  version=${latest#*@}
else
  version=$("${from_context[@]}" --bumped-version <<< "$context")
  version=${version#*@}
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "git-cliff returned an invalid iOS version: $version" >&2
    exit 1
  fi
  if [[ -n "$latest" ]] && ! jq -en --arg next "$version" --arg last "${latest#*@}" \
    '($next | split(".") | map(tonumber)) > ($last | split(".") | map(tonumber))' >/dev/null; then
    echo "The next iOS version must exceed $latest." >&2
    exit 1
  fi
fi

case "${1:-check}" in
  check)
    outputs=$(printf 'should-release=%s\nnext-version=ios@%s\nnext-version-number=%s\n' \
      "$should_release" "$version" "$version")
    printf '%s\n' "$outputs"
    [[ -z "${GITHUB_OUTPUT:-}" ]] || printf '%s\n' "$outputs" >> "$GITHUB_OUTPUT"
    ;;
  notes)
    if [[ "$should_release" == true ]]; then
      "${from_context[@]}" --tag "ios@$version" --strip all <<< "$context"
    fi
    ;;
  *) echo "Usage: $0 [check|notes]" >&2; exit 1 ;;
esac

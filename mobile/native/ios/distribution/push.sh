#!/usr/bin/env bash
# Prepare a local device bundle before signing. Does not create credentials or sign.
set -euo pipefail
if [[ $# != 3 ]]; then
    echo "Usage: bash ios/distribution/push.sh PROFILE.mobileprovision Glossia.app OUTPUT.entitlements" >&2
    exit 2
fi
decoded=$(mktemp)
trap 'rm -f "$decoded"' EXIT
security cms -D -i "$1" > "$decoded"
python3 "$(dirname "$0")/push.py" "$decoded" "$2" "$3"
cp "$1" "$2/embedded.mobileprovision"
echo "Profile-derived push configuration prepared. Sign the extension and app using your existing signing workflow."

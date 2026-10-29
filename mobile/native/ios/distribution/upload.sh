#!/usr/bin/env bash
#MISE description="Validate or upload an IPA to App Store Connect without submitting for review"
set -euo pipefail
set +x
umask 077

mode=${1:?Usage: upload.sh [check|validate|upload] [IPA]}
[[ "$mode" == check || "$mode" == validate || "$mode" == upload ]] || exit 1
: "${ASC_API_KEY_ID:?Store the App Store Connect API key ID in Infisical}"
: "${ASC_API_ISSUER_ID:?Store the App Store Connect issuer ID in Infisical}"
: "${ASC_API_KEY_P8_BASE64:?Store the App Store Connect private API key in Infisical}"
[[ "$ASC_API_KEY_ID" =~ ^[A-Za-z0-9]+$ ]]
[[ "$ASC_API_ISSUER_ID" =~ ^[0-9a-fA-F-]{36}$ ]]
temporary=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/glossia-appstore.XXXXXX")
trap 'rm -rf "$temporary"' EXIT
export API_PRIVATE_KEYS_DIR="$temporary"
printf '%s' "$ASC_API_KEY_P8_BASE64" | base64 --decode > "$temporary/AuthKey_$ASC_API_KEY_ID.p8"
unset ASC_API_KEY_P8_BASE64
openssl ec -in "$temporary/AuthKey_$ASC_API_KEY_ID.p8" -passin pass: -noout >/dev/null
if [[ "$mode" == check ]]; then
  echo "App Store Connect upload credentials are configured."
  exit 0
fi
ipa=${2:?Provide the signed IPA}
[[ -s "$ipa" ]]
if [[ "$mode" == validate ]]; then
  xcrun altool --validate-app "$ipa" \
    --api-key "$ASC_API_KEY_ID" --api-issuer "$ASC_API_ISSUER_ID"
else
  # Upload acceptance is not processing completion, beta approval or public release.
  # Do not retry automatically: a connection failure may follow a successful upload.
  xcrun altool --upload-package "$ipa" --api-key "$ASC_API_KEY_ID" --api-issuer "$ASC_API_ISSUER_ID"
fi

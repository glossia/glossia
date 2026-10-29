#!/usr/bin/env bash
#MISE description="Distribution-sign and package the built device app using Infisical-injected secrets"
set -euo pipefail
set +x
umask 077

ROOT=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
VERSION=${1:?Usage: bundle.sh VERSION BUILD_NUMBER [OUTPUT_IPA]}
BUILD=${2:?Usage: bundle.sh VERSION BUILD_NUMBER [OUTPUT_IPA]}
OUTPUT=${3:-$ROOT/mobile/native/.once/distribution/Glossia.ipa}
# Local bootstrap builds 1.0.N precede CI's first run/attempt build 1.1.
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$BUILD" =~ ^[1-9][0-9]*(\.[0-9]+){0,2}$ ]] || {
  echo "Expected a stable version and a positive build number (CI: RUN_NUMBER.RUN_ATTEMPT)." >&2; exit 1;
}
[[ "$OUTPUT" == /* && ! -e "$OUTPUT" ]] || {
  echo "The output IPA must be a new absolute path." >&2; exit 1;
}
: "${IOS_DISTRIBUTION_P12_BASE64:?Missing signing identity}"
: "${IOS_DISTRIBUTION_P12_PASSWORD:?Missing signing identity password}"
: "${IOS_APP_STORE_PROFILE_BASE64:?Missing App Store provisioning profile}"
: "${IOS_EXTENSION_APP_STORE_PROFILE_BASE64:?Missing Glossia Activity App Store profile}"

temporary=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/glossia-ios.XXXXXX")
keychain="$temporary/signing.keychain-db"
original_keychains=()
while IFS= read -r path; do
  original_keychains+=("$path")
done < <(security list-keychains -d user | sed -E 's/^[[:space:]]*"(.*)"$/\1/')
cleanup() {
  if [[ ${#original_keychains[@]} -gt 0 ]]; then
    security list-keychains -d user -s "${original_keychains[@]}" >/dev/null 2>&1 || true
  else
    security list-keychains -d user -s >/dev/null 2>&1 || true
  fi
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  rm -rf "$temporary"
}
trap cleanup EXIT
printf '%s' "$IOS_DISTRIBUTION_P12_BASE64" | base64 --decode > "$temporary/distribution.p12"
printf '%s' "$IOS_APP_STORE_PROFILE_BASE64" | base64 --decode > "$temporary/profile.mobileprovision"
printf '%s' "$IOS_EXTENSION_APP_STORE_PROFILE_BASE64" | base64 --decode > "$temporary/extension.mobileprovision"
unset IOS_DISTRIBUTION_P12_BASE64 IOS_APP_STORE_PROFILE_BASE64 IOS_EXTENSION_APP_STORE_PROFILE_BASE64
security cms -D -i "$temporary/profile.mobileprovision" > "$temporary/profile.plist"
security cms -D -i "$temporary/extension.mobileprovision" > "$temporary/extension.plist"

# Never mutate Once's cached bundle or the checked-in development plist.
app="$temporary/package/Payload/Glossia.app"
extension="$app/PlugIns/GlossiaActivity.appex"
mkdir -p "$(dirname "$app")"
ditto "$ROOT/mobile/native/.once/out/GlossiaIOSDevice/Glossia.app" "$app"
python3 -B "$ROOT/mobile/native/ios/distribution/profile.py" \
  "$temporary/profile.plist" "$temporary/extension.plist" "$app" "$temporary"
team=$(plutil -extract TeamIdentifier.0 raw -o - "$temporary/profile.plist")
identity=$(openssl x509 -inform DER -in "$temporary/certificate.cer" -noout -fingerprint -sha1 |
  cut -d= -f2 | tr -d ':')

# Once copies custom plists without Xcode's SDK/platform metadata processing.
sdk=$(xcrun --sdk iphoneos --show-sdk-version)
sdk_build=$(xcrun --sdk iphoneos --show-sdk-build-version)
xcode_build=$(xcodebuild -version | awk '/Build version/ {print $3}')
xcode_version=$(xcodebuild -version | awk '/^Xcode / {split($2,v,"."); printf "%02d%d%d",v[1],v[2],v[3]}')
for bundle in "$app" "$extension"; do
  plist="$bundle/Info.plist"
  plutil -replace CFBundleShortVersionString -string "$VERSION" "$plist"
  plutil -replace CFBundleVersion -string "$BUILD" "$plist"
  plutil -replace CFBundleSupportedPlatforms -json '["iPhoneOS"]' "$plist"
  plutil -replace UIRequiredDeviceCapabilities -json '["arm64"]' "$plist"
  plutil -replace DTPlatformName -string iphoneos "$plist"
  plutil -replace DTPlatformVersion -string "$sdk" "$plist"
  plutil -replace DTPlatformBuild -string "$sdk_build" "$plist"
  plutil -replace DTSDKName -string "iphoneos$sdk" "$plist"
  plutil -replace DTSDKBuild -string "$sdk_build" "$plist"
  plutil -replace DTXcode -string "$xcode_version" "$plist"
  plutil -replace DTXcodeBuild -string "$xcode_build" "$plist"
  plutil -replace DTCompiler -string com.apple.compilers.llvm.clang.1_0 "$plist"
  plutil -replace BuildMachineOSBuild -string "$(sw_vers -buildVersion)" "$plist"
done
# Required by Apple's iPad multitasking validation for direct Once bundles.
plutil -replace 'UISupportedInterfaceOrientations~ipad' -json \
  '["UIInterfaceOrientationPortrait","UIInterfaceOrientationPortraitUpsideDown","UIInterfaceOrientationLandscapeLeft","UIInterfaceOrientationLandscapeRight"]' "$app/Info.plist"
cp "$temporary/profile.mobileprovision" "$app/embedded.mobileprovision"
cp "$temporary/extension.mobileprovision" "$extension/embedded.mobileprovision"

keychain_password=$(openssl rand -hex 32)
security create-keychain -p "$keychain_password" "$keychain"
# codesign also uses the search list for certificate-chain resolution. Creating
# a keychain does not reliably add it on runners with an explicit search list.
if [[ ${#original_keychains[@]} -gt 0 ]]; then
  security list-keychains -d user -s "$keychain" "${original_keychains[@]}"
else
  security list-keychains -d user -s "$keychain"
fi
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$temporary/distribution.p12" -k "$keychain" -P "$IOS_DISTRIBUTION_P12_PASSWORD" -T /usr/bin/codesign
unset IOS_DISTRIBUTION_P12_PASSWORD
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain" >/dev/null
# Include Apple's intermediate even on a clean CI runner.
curl --fail --silent --show-error --retry 3 https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer \
  -o "$temporary/wwdr.cer"
security import "$temporary/wwdr.cer" -k "$keychain"
security find-identity -v -p codesigning "$keychain" | grep -Fq "$identity" || {
  echo "The imported signing identity does not match the profile's valid certificate." >&2; exit 1;
}

mkdir -p "$app/Frameworks" "$temporary/package/SwiftSupport"
xcrun swift-stdlib-tool --copy --platform iphoneos --scan-executable "$app/Glossia" \
  --scan-executable "$extension/GlossiaActivity" \
  --scan-folder "$app/Frameworks" --destination "$app/Frameworks" \
  --unsigned-destination "$temporary/package/SwiftSupport" --strip-bitcode
# Apps using only the OS Swift runtime need no empty SwiftSupport directory.
find "$temporary/package" -depth -type d -empty -delete
while IFS= read -r -d '' code; do
  codesign --force --sign "$identity" --keychain "$keychain" --timestamp=none "$code"
done < <(find "$app" -depth \( -name '*.framework' -o -name '*.dylib' \) -print0)
codesign --force --sign "$identity" --keychain "$keychain" --timestamp=none \
  --generate-entitlement-der --entitlements "$temporary/extension.entitlements" "$extension"
codesign --force --sign "$identity" --keychain "$keychain" --timestamp=none \
  --generate-entitlement-der --entitlements "$temporary/app.entitlements" "$app"
codesign --verify --deep --strict --verbose=2 "$app"
plutil -lint "$app/Info.plist" "$extension/Info.plist" "$temporary/app.entitlements" "$temporary/extension.entitlements"
mkdir -p "$(dirname "$OUTPUT")"
ditto --norsrc --noextattr -c -k "$temporary/package" "$OUTPUT"
printf 'Signed Glossia %s (%s) and Glossia Activity extension for %s: %s\n' "$VERSION" "$BUILD" "$team" "$OUTPUT"

# Glossia native

Native iOS and Android clients, built with [Once](https://github.com/tuist/once)
using the same architecture as Tuist's Atlas native app:

| Layer | Implementation |
| --- | --- |
| Business logic | Shared Rust core: OAuth, token refresh, API requests, workspace selection |
| iOS | Standard SwiftUI tabs, navigation stacks, lists, forms and pickers; C ABI; Keychain |
| Android | Material 3 Views, native lists, JNI, system browser, Keystore-encrypted storage |
| Builds | Once 0.68.2; Cargo supplies Rust dependencies; Gradle/AGP packages Android |

This is separate from the older Expo prototype in `mobile/`. It does not require
Node or an Xcode project. Commands below run from `mobile/native/`.

The UI follows Apple's Human Interface Guidelines on iOS and Material Design on
Android. System components own navigation chrome, control shapes, typography,
feedback, safe areas, and light/dark appearances. Branding is limited to the logo
and an adaptive accent color. Android 12+ also supports the device's dynamic
color theme. There are no hand-painted tab buttons or custom card surfaces.

## Sign-in and workspace

The welcome screen offers hosted Glossia or a self-hosted HTTPS origin. Rust
discovers `/.well-known/oauth-authorization-server`, dynamically registers a
public client (`token_endpoint_auth_method=none`), and uses authorization code
flow with S256 PKCE, random state, and `glossia://oauth/callback`. Provider
selection and consent happen in the server's browser login, not in the app.
OAuth endpoints must stay on the chosen server's origin. No client secret is
embedded in either app.

Requests use `organization:read project:read voice:read glossary:read`. The
registration controller change in this repository is required on the server for
secretless refresh. Deploying the mobile files alone does not update that server.

Credentials stay in platform secure storage. Requests and refreshes run serially
off the UI thread; rotated credentials are persisted before fetching workspace
data. Superseded resource requests are discarded before starting; sign-out waits
for at most the active request, not a queue of historical tab selections.
Transient failures retain the session and offer retry. Sign-out removes the
local session; it does not revoke other sessions or clear browser cookies.
If the server has deleted a cached OAuth client, **Reset saved sign-in** on the
welcome screen clears its registration so the next sign-in registers again.
Unrelated Android callbacks do not consume the current pending PKCE grant.

The navigation bar's workspace action opens native organization and project
pickers. The selection persists across tabs and launches and appears in Android's
app-bar subtitle. Organization changes reset the selected project; deleted or
inaccessible selections fall back to the first available workspace. Project
lists follow all API pages. There is no bundled demo data in the app.

- **Overview:** selected project, setup status, and linked repository.
- **Voice / Glossary:** real read-only organization-wide resources, with loading,
  error, empty, and retry states. These are not project-specific in Glossia's API.
- **Settings:** server, global selection, and sign-out.

Editing, offline sync, push notifications, store publishing, and production
signing are not included. Native UI currently uses English copy.

## Shared core checks

Install [mise](https://mise.jdx.dev), then:

```sh
mise install rust github:tuist/once
mise exec -- rustup component add rustfmt clippy
mise run check
```

Once 0.68.2 requires dependencies to be materialized before graph resolution.
`mise run prepare:rust` vendors `Cargo.lock` into ignored `.once/vendor`;
all check/build tasks depend on it. Use that task before calling Once directly.
The Linux Once binary needs a recent glibc (Ubuntu 24.04 or newer works).

## Android 8.0+ (arm64)

Install the Android command-line SDK and accept its licenses, then:

```sh
mise install java gradle
export ANDROID_HOME=/path/to/android-sdk
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
sdkmanager "platforms;android-35" "build-tools;35.0.0" "ndk;27.3.13750724"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/27.3.13750724"
mise exec -- rustup target add aarch64-linux-android

# Once needs a debug-signing key; never use this key for production releases.
mkdir -p .once
export ANDROID_DEBUG_KEYSTORE="$PWD/.once/debug.keystore"
if [ ! -f "$ANDROID_DEBUG_KEYSTORE" ]; then
  mise exec -- keytool -genkeypair -noprompt \
    -keystore "$ANDROID_DEBUG_KEYSTORE" -storepass android -keypass android \
    -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"
fi

mise run build:android
adb install -r .once/out/GlossiaAndroid/GlossiaAndroid.apk
adb shell am start -n ai.glossia.mobile/.MainActivity
```

The debug APK contains `lib/arm64-v8a/libglossia_core.so`. It is not a Play Store
release bundle. The native library and APK are aligned for 16 KB-page devices;
CI checks both ELF segments and APK ZIP alignment. Use an arm64 device or a
supported external emulator.

`once build GlossiaAndroid` still owns the build: it first builds Rust JNI, then
the project-local `glossia_android_application` rule invokes Gradle 8.13 / Android
Gradle Plugin 8.9.3 to compile Kotlin and package the app. Once 0.68.2 cannot import
Maven AARs or merge their manifests; AGP supplies that required support for the
real Material and AppCompat components. Dependency versions are locked in
`android/gradle.lockfile`. Gradle owns its local incremental cache; its packaging
action does not publish mutable Gradle state to Once's shared cache.

## iOS 17+ (Apple Silicon macOS with Xcode)

```sh
mise exec -- rustup target add aarch64-apple-ios-sim aarch64-apple-ios
mise run build:ios
xcrun simctl install booted .once/out/GlossiaIOS/Glossia.app
xcrun simctl launch booted ai.glossia.mobile

# Compile the device bundle, without distribution credentials:
mise run build:ios-device
```

The simulator target includes its own Keychain entitlement. The device target
still needs an app-specific Apple provisioning profile and signing identity
before installation on a physical device. No signing credentials are committed.
`modules/apple_sdk.star` carries Atlas's Once 0.68.2 SDK-linker workaround.

## CI and validation

`.github/workflows/mobile-native.yml` checks Rust and builds Android, the iOS
simulator app, and the iOS device bundle. It retains build artifacts without
publishing previews or releases. The server's OAuth regression tests run in the
existing app workflow.

In this Linux orb, Once's Rust tests and the signed Android build were executed.
Android native widgets were also rendered in a temporary Robolectric harness
with fixture data; project selection, tab scope, stale/duplicate callbacks,
registration reset, and skipping queued requests were checked. Login captures
cover light/dark mode and a narrow screen at 150% font scale. Those captures
are not device tests or a completed browser sign-in. Swift sources passed a
syntax parse; the unchanged runtime actor was also exercised on Linux with
substitute storage/network boundaries to check cancellation, durable token
rotation, and registration reset. The iOS build, Keychain runtime, browser
handoff, 16 KB-device JNI loading, and physical device behavior still require
macOS/device verification.

Tuist's MIT attribution is included in both app bundles through
[`third_party_notices.txt`](android/res/raw/third_party_notices.txt).
Android's Material icons are covered by the bundled
[`Apache 2.0 license`](android/res/raw/material_icons_license.txt).

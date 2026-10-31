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
Android. System components own navigation, typography, feedback, and safe areas.
Glossia's warm surface and violet accent tokens adapt to light/dark appearances.
Toki uses six transparent sprite poses; see `resources/README.md` for regeneration.

Both iOS dependency targets select the Rust core's `system-tls` feature with
default features disabled. HTTPS and secure WebSockets use Apple's Security
framework through `native-tls`; Android and default core builds retain Rustls.
Ad-hoc Cargo builds using Apple's TLS need `--no-default-features --features system-tls`.
Select the backend explicitly: Once 0.68.2's Cargo metadata resolution combines
features from target-conditional dependency declarations. CI checks the compiled
iOS binaries for system TLS imports and rejects bundled Rustls or OpenSSL symbols.

## Server-owned appearance

Like Atlas, both clients fetch the public `/api/native/themes` catalog at runtime
from the selected HTTPS server. The hosted login uses `https://glossia.ai`;
self-hosted sign-in and session restoration select that server's own catalog.
The server compiles light/dark colors and control radii from the canonical tokens
in `app/priv/static/assets/styles.css`, with a content revision and five-minute
cache policy. Toki appears in new conversations, not on the welcome screen.

Rust validates schema compatibility, bounded values, colors, and text contrast
before either platform applies tokens. Native clients cache validated catalogs
per normalized server origin, reject stale responses after switching servers,
and refresh on foreground entry at most once every five minutes. A failed fetch
keeps that server's last valid catalog, or bundled Glossia tokens on first use.
It never blocks OAuth or invalidates credentials. Appearance networking runs
independently of credential rotation and feature requests. System typography,
accessibility, and native navigation behavior remain platform-owned.

## Feature boundaries and concurrency

Rust owns OAuth, validation, fixed REST routes, authenticated transport, and
workspace discovery. `toki`, `translations`, `analytics`, and `profile` are
independent core modules. SwiftUI and Kotlin own native presentation, lifecycle,
secure storage, and feature state. The JSON C/JNI boundary accepts explicit
commands and returns one result; it does not hold mutable global feature state.

Each tab has an independent model. Credential refresh and secure-storage writes
are serialized; feature requests take a durable credential snapshot and run on
up to four workers sharing Rust's thread-safe HTTP client. Project/session
generation checks discard obsolete responses. This lets tabs and features evolve
independently without a global networking queue or competing refresh rotations.
No automatic retries are applied to message writes: the native model retains the
same client-generated UUID and content for an explicit retry.
Responses are bounded to 1 MiB for OAuth and 8 MiB for APIs, enough for the
server's complete, bounded conversation history including JSON escaping.

## Sign-in and workspace

The welcome screen offers hosted Glossia or a self-hosted HTTPS origin. Rust
discovers `/.well-known/oauth-authorization-server`, dynamically registers a
public client (`token_endpoint_auth_method=none`), and uses authorization code
flow with S256 PKCE, random state, and `glossia://oauth/callback`. Provider
selection and consent happen in the server's browser login, not in the app.
OAuth endpoints must stay on the chosen server's origin. No client secret is
embedded in either app.

Requests use `user:read user:write organization:read project:read voice:read glossary:read
translation:read translation:write analytics:read toki:read toki:write`. The server must support
these scopes and secretless public-client refresh. Deploying the mobile files
alone does not update the server.

Credentials stay in platform secure storage. Rotated credentials are persisted
before feature requests start. Superseded resource responses cannot replace the
active project's data; sign-out is not queued behind feature networking.
Transient failures retain the session and offer retry. Sign-out removes the
local session; it does not revoke other sessions or clear browser cookies.
If the server has deleted a cached OAuth client, **Reset saved sign-in** on the
welcome screen clears its registration so the next sign-in registers again.
Unrelated Android callbacks do not consume the current pending PKCE grant.

The toolbar shows the active organization/project and opens a focused selector:
an organization menu, searchable projects, and a checkmark on the active project.
Browsing organizations is staged; Cancel preserves the existing context, and
choosing a project applies both fields together. Selection persists across tabs
and launches. Switching projects clears unsent Toki drafts. Inaccessible saved
selections fall back to an accessible workspace. Project discovery follows every
API page. Production bundles contain no fixture data.

This follows Apple's [sheet guidance](https://developer.apple.com/design/human-interface-guidelines/sheets)
for a scoped task with cancellation, [menu guidance](https://developer.apple.com/design/human-interface-guidelines/menus)
for selection, and [search-field guidance](https://developer.apple.com/design/human-interface-guidelines/search-fields)
for finding items in a growing collection. Project context remains visible in the
toolbar rather than being hidden in Profile or encoded as extra tabs.

- **Toki:** private project conversations, durable messages, queued/running reply
  states, explicit retry, and native work-status presentations.
- **Translations:** paginated project sessions, with foreground live file progress
  over an authenticated Phoenix WebSocket and durable reconstruction on reconnect.
- **Analytics:** project pageviews, visitors, locale gaps, and top pages over
  7, 30, or 90 days. iOS uses Swift Charts for server-provided UTC traffic buckets;
  unique-visitor totals come from the server summary, not summed buckets.
- **Profile:** signed-in identity, server, project context, and sign-out.

The REST API exposes `/api/me` and project-scoped `translations`, `analytics`,
and `toki/conversations` under `/api/:handle/projects/:project`. Toki writes use
client UUIDs for replay safety. The server enforces OAuth scopes and LetMe project
permissions; conversations are also private to their creator. Apply the server
migration through your normal deployment procedure, configure an inference
provider, and run the Toki Oban queue before expecting live replies. See the
server's API reference and OpenAPI document for request and response schemas.

Editing and offline sync are not included. App Store distribution automation is
described below; Apple credentials and store approval are still required.

## iOS App Store distribution

The setup follows Habibi's Once → distribution signing → App Store Connect
pipeline. `.github/workflows/ios-release.yml` uploads the exact commit after
**Mobile Native** succeeds on a push to `main`. Fork/PR runs, failed checks and
superseded commits cannot publish. Manual dispatch is restricted to current `main`.
Uploads remain disabled until the repository variable `IOS_INFISICAL_IDENTITY_ID`
is configured. After upload and receipt publication, a separate job reconciles
TestFlight access for `pedro@pepicrft.me`. It never creates Apple team users,
grants team roles, changes Infisical policy, or publishes to the public App Store.

`ios/distribution/check.sh` uses `mobile/native/cliff.toml` and independent,
reachable stable `ios@x.y.z` tags, starting at `0.1.0`. Features bump minors,
fixes bump patches, and breaking changes bump majors even during `0.x`.
Maintenance and unrelated server/Expo changes do not release iOS. Both app and
extension get the same version and `GITHUB_RUN_NUMBER.GITHUB_RUN_ATTEMPT` build
number. Preserve the release workflow's run-counter history. Local bootstrap
uploads should use `1.0.N`, below CI's first `1.1`.

### Apple account requirements

Use an active Apple Developer Program team with its agreements accepted:

1. Register the explicit app ID **`ai.glossia.app`**, enabling **Push
   Notifications**, and extension ID **`ai.glossia.app.activity`**.
   The current Live Activity uses no App Group or ActivityKit push entitlement.
2. Create the **Glossia** iOS app record in App Store Connect using
   `ai.glossia.app` (choose a unique SKU, for example `glossia`). The same app
   record and bundle ID can include a future macOS version. There is
   no separate store record for the extension. Supply the team ID and numeric
   App Store Connect app ID when handing over the account setup.
3. Supply an **Apple Distribution certificate and its matching private key** as
   password-protected `.p12`. A `.cer` alone cannot sign. An existing certificate
   can be reused only if it belongs to this same team and its private key is
   available; Habibi's personal-team identity does not cover a different team.
4. Generate **two App Store Connect provisioning profiles**, one per bundle ID,
   permitting that distribution certificate. Do not use development or Ad Hoc
   profiles. Regenerate the app profile after enabling Push Notifications.
5. Create a **team App Store Connect API key** under Users and Access →
   Integrations → App Store Connect API. **Developer** is sufficient for build
   uploads; provide its key ID, issuer UUID and downloaded private `.p8`.
   **App Manager** access is needed for external TestFlight tester/group management
   (and metadata/review). The distribution job reuses this same key, with no new
   secrets. Listing team users may require greater permissions; if unavailable,
   the helper cannot infer internal eligibility and uses an external group.
   This is not an APNs key. No Apple ID password or two-factor code is needed.

Keep private keys and passwords out of Git and chat. Place them directly in
Infisical or provide local file paths through an agreed secure handoff.

### Infisical and GitHub activation

In the existing Infisical EU `glossia` project, environment `prod`, create a
dedicated `/glossia-ios-releases` folder with these seven secrets:

| Secret | Value |
| --- | --- |
| `IOS_DISTRIBUTION_P12_BASE64` | Base64 password-protected certificate + private key export |
| `IOS_DISTRIBUTION_P12_PASSWORD` | That export's password |
| `IOS_APP_STORE_PROFILE_BASE64` | Base64 app App Store profile |
| `IOS_EXTENSION_APP_STORE_PROFILE_BASE64` | Base64 Glossia Activity extension App Store profile |
| `ASC_API_KEY_ID` | Team API key ID |
| `ASC_API_ISSUER_ID` | Team issuer UUID |
| `ASC_API_KEY_P8_BASE64` | Base64 API private key |

Create a dedicated read-only machine identity restricted to that folder, with
15-minute OIDC tokens. Bind GitHub's issuer/discovery URL
`https://token.actions.githubusercontent.com`, audience `https://github.com/glossia`,
the repository/owner immutable IDs, `refs/heads/main`, and exact workflow claim
`glossia/glossia/.github/workflows/ios-release.yml@refs/heads/main`.
Inspect `gh api repos/glossia/glossia/actions/oidc/customization/sub` before
setting the bound subject; the inspected setup uses the default mutable subject
`repo:glossia/glossia:ref:refs/heads/main`, unlike Habibi's immutable subject.
Use the numeric IDs as additional bound claims. Set `IOS_INFISICAL_IDENTITY_ID`
to the new identity UUID **only after** its policy and all secrets are ready.
Do not broaden the existing infrastructure/release identity or put persistent
Infisical tokens in GitHub. Account policy/secret changes require approval.

The build runs before credentials are fetched. Packaging works on a copy of the
device bundle, validates both profiles/team/certificate, scopes entitlements,
embeds production APNs metadata, stamps Apple SDK/ARM64/iPad metadata, signs the
extension before its containing app, verifies the signature, and deletes its
temporary Keychain/private files. The source plist and Once cache are unchanged.
Signed CI uploads have succeeded for `ios@0.1.0` (8.1) and `ios@0.1.1` (10.1).
Upload success alone does not prove Apple processing or TestFlight access.

Apple validation precedes upload. A successful upload creates an exact-SHA
GitHub release/tag, without a public IPA artifact, **before** TestFlight runs.
If upload outcome is uncertain, inspect App Store Connect before retrying. If
only GitHub release creation fails, create the tag/release for that uploaded SHA
rather than uploading another build.

### TestFlight access and distribution-only retries

`bash ios/distribution/testflight.sh VERSION BUILD` uses Bash, curl, jq, OpenSSL,
and xxd with the existing three `ASC_API_*` credentials. Its private-key file is
temporary, owner-readable only, and deleted on success/failure; credentials,
JWTs and Apple response bodies are never logged. The TestFlight helper, its tests,
and the workflow receipt check do not use Python. The tools are available on the
GitHub-hosted macOS release runner.

The helper resolves `ai.glossia.app` and matches **both** the iOS marketing version
and build number, never the latest build. It waits up to 10 minutes for processing
(configurable with `--timeout 1..1200`), fails on invalid/failed/expired builds,
and reads back tester/group/build relationships before reporting success.
Writes are read-before-write and never automatically retried. An uncertain write
requires a distribution-only rerun, which first reads Apple state again.

An existing internal group already containing Pedro is preferred. Otherwise,
the helper checks existing ASC user roles and app visibility before resolving
the unique **Glossia internal** group or creating it. It fails on duplicate named
groups rather than picking an unrelated internal cohort. It does not create or
promote team users. Without confirmed internal eligibility it creates/reuses
the private, email-invitation-only
**Glossia beta** external group. If Apple has no internal group yet, an empty
**Glossia internal** prerequisite group is created, without adding team users.
New internal groups allow all builds; existing groups are not broadened. Each
future releasable native build is explicitly reconciled into the selected group.

External distribution can require **TestFlight App Review**, beta test information,
and export-compliance answers. The helper does not invent legal declarations,
review credentials, contact information or test notes, and does not submit reviews.
It preserves tester membership but fails the job with the exact Apple beta state
in the workflow summary until the build is approved/ready for testing. Complete
the real metadata and beta review in App Store Connect, then retry distribution.
For ready external builds it enables automatic tester notifications and assigns
the build. Notifications alone do not prove an invitation was sent: external
tester readback must report `INVITED`, `ACCEPTED`, or `INSTALLED`. `NOT_INVITED`,
`REVOKED`, missing, or unknown states fail with an actionable blocker. Send/resend
the invitation or restore revoked access in App Store Connect, then retry
distribution only; the helper does not send or retry invitation requests.
Confirm invitation acceptance and installation separately on the device.

After this workflow is on `main`, an operator can retry an existing receipt:

```sh
gh workflow run ios-release.yml --ref main \
  -f distribution_only=true -f version=0.1.1 -f build=10.1
```

This path checks the exact `ios@VERSION` upload receipt and **never builds, signs,
validates, uploads, or creates another release/tag**. Normal upload/version jobs
are skipped. A failed distribution job can also use GitHub's **Re-run failed jobs**;
do not rerun all jobs after an accepted upload. A missing receipt must be repaired
against the actually uploaded SHA/build first, not bypassed by uploading again.
Distribution failures retain the existing upload receipt, so subsequent release
version selection will not consider that upload unreleased.

Before public release, complete the listing/screenshots, support/privacy URLs,
age rating, App Privacy and encryption/export-compliance declarations (including
Rust TLS), review contact and working reviewer sign-in. Then select the processed
build and submit for App Review. APNs delivery separately requires server-side
provider credentials; they never belong in the app or upload secrets.

From `mobile/native/`, run `mise run test:ios-distribution` for disposable release
histories, profile fixtures, and mocked TestFlight reconciliation/signing tests,
or `mise run release:ios-check` on a clean, committed checkout to inspect the next
version without publishing. Fixture tests make no live Apple calls and cannot
prove current credentials, beta approval, or actual tester access.

## Remote push opt-in

Profile has an explicit, optional push-notification control. Permission denial,
missing provider configuration, or an older server never blocks sign-in, reading,
or sending. The shared core enrolls through bearer-authenticated
`PUT /api/me/push-devices/{installation-uuid}` and idempotent `DELETE` on the same
fixed route. The server requires a native OAuth-client-bound grant. Installation
IDs and opt-in state live per HTTPS origin in Keychain/Keystore-encrypted storage.
Rotation and foreground entry reconcile provider tokens and OS permission
revocation. Sign-out clears opt-in before deleting credentials, performs best-effort
server cleanup, and retains a disabled tombstone for the next authenticated retry.
Late callbacks cannot enable a replacement session. New opt-ins use new UUIDs;
the server must retain DELETE tombstones to reject late enrollment requests.

Notification alerts are generic, never conversation titles, translations, prompts,
or replies. The fixed data contract is `v: "1"`, `registration_id: installation-uuid`,
and `url: glossia://navigate/...` for a translation-session or Toki-conversation UUID.
Receipts must match the current encrypted registration and server. Taps use the
existing typed navigation and authorization, including cold launch and draft
protection. They cannot switch origins, start login, create a conversation, or
perform a mutation. Android uses **data-only FCM**, never an FCM `notification`
payload that the SDK could display without the app's checks.

Android uses the official `com.google.firebase:firebase-messaging:24.1.0` SDK through
Gradle/AGP, including its merged manifest and locked transitive dependencies. Before
building a provider-enabled APK, supply the public identifiers for the
`ai.glossia.mobile` Firebase Android app in your user-level `~/.gradle/gradle.properties`:

```properties
glossiaFirebaseApplicationId=1:PROJECT_NUMBER:android:APP_ID
glossiaFirebaseProjectId=PROJECT_ID
glossiaFirebaseSenderId=PROJECT_NUMBER
glossiaFirebaseApiKey=PUBLIC_ANDROID_API_KEY
```

These are public project identifiers, not service-account credentials. Never embed
private provider keys. Missing identifiers leave the build explicitly unavailable.
FCM auto-init and analytics collection are off; obtaining the token requires opt-in.
Real delivery requires Google Play services and the matching server FCM project.

iOS simulator and unsigned-device builds intentionally have no APNs environment.
Use an existing explicit app profile with Push Notifications enabled. After building
the device bundle, before signing it through your existing distribution workflow:

```sh
bash ios/distribution/push.sh /path/to/app.mobileprovision \
  .once/out/GlossiaIOSDevice/Glossia.app /tmp/glossia-push.entitlements
# Sign the extension, then the app with that profile's identity and these entitlements.
python3 -B ios/distribution/push_test.py
```

The preparation script validates the app identity and profile expiry, derives both
`aps-environment` and the signed `GlossiaPushEnvironment` metadata from the decoded
profile, and embeds the profile. Development maps to APNs sandbox; production maps
to APNs production. The script does not create profiles, sign, publish, or provision
providers. APNs/FCM credentials belong only on the server. Provider delivery and
signed-device validation remain external requirements.

## Native work status and background limits

Toki's status presentation uses observed queued/running/completed/failed states,
a companion mark, and elapsed time since observation. It never invents steps,
percentages, or pause/stop controls that the backend does not support. iOS embeds
a WidgetKit extension for ActivityKit Lock Screen and Dynamic Island views.
Android uses a standard ongoing notification, not promoted Android Live Updates
intended for time-sensitive navigation or delivery tracking. Notification
permission denial does not prevent sending a message.

System surfaces contain generic Toki status, never conversation titles, prompts,
or replies. Their links use Rust's canonical navigation contract and reauthorize
when opened. Account/workspace changes and detected access loss clear the
associated status. Elapsed time is not an inferred server execution duration.

These clients observe Toki through authorized foreground requests. Their native
status surfaces do not keep networking alive after the OS suspends the app.
The iOS activity becomes stale and asks the user to open Glossia rather than
claiming work is still running indefinitely. Reliable suspended-app completion
alerts use the optional remote-push registration above and require configured
server providers. Remote push does not keep these foreground observers alive or
update ActivityKit remotely; ActivityKit push remains outside this implementation.

Translation subscriptions also close in the background. Rust owns the persistent
socket, heartbeat, bounded latest-only complete snapshots, reconnection, and
opaque `open` / `next` / `close` handles. `next` waits locally, outside credential
serialization and feature-network slots; it is not HTTP polling. The server
subscribes before reconstructing progress, rechecks current OAuth scopes and
LetMe permissions before pushing, and repairs missed broadcasts periodically.
The local delivery sequence is distinct from the durable progress sequence:
status and publication changes can occur without another file-progress event.
Raw output, provider payloads, and model reasoning are not sent to native clients.

## Navigation and translation discussions

External links and in-app actions use the same typed, server-bound destination.
Rust owns parsing, validation, and canonical link generation. Native navigation
owns the tab, parent stack, pending intent, and draft protection; each feature
continues to own its data and requests.

Supported custom-scheme routes are:

```text
glossia://navigate/{organization}/{project}/toki?server={https-origin}
glossia://navigate/{organization}/{project}/toki/{conversation-uuid}?server={https-origin}
glossia://navigate/{organization}/{project}/toki/new?server={https-origin}&translation_id={session-uuid}
glossia://navigate/{organization}/{project}/translations?server={https-origin}
glossia://navigate/{organization}/{project}/translations/{session-uuid}?server={https-origin}
glossia://navigate/{organization}/{project}/analytics?server={https-origin}
glossia://navigate/profile?server={https-origin}
```

`server` is required and URL-encoded. `translation_id` is optional and accepted
only on `toki/new`. Links contain references, never credentials, message content,
or instructions to execute. OAuth's `glossia://oauth/callback` remains separate.
Unknown routes, extra/duplicate parameters, ambiguous paths, invalid IDs and
non-HTTPS server origins are rejected.

For example, a translation on the hosted server can be shared as:

```text
glossia://navigate/acme/website/translations/abc12345-802e-4f91-9112-77d8a919efc5?server=https%3A%2F%2Fglossia.ai%2F
```

The Rust bridge exposes `operation: "navigation"` with `action: "parse"` and a
`url`, or `action: "link"` and a `destination`. Both return the canonical
`destination` and `url`. Destinations contain `screen`, `server`, `organization`,
`project`, `id`, and `translation_id`; absent fields serialize as null. Screens
are `toki`, `conversation`, `new_conversation`, `translations`, `translation`,
`analytics`, and `profile`.

Signed-out links wait in memory until authentication and workspace discovery
finish. The latest link wins. Links cannot initiate sign-in or switch servers,
and an inaccessible workspace never falls back to a different project. Pending
intents clear on explicit sign-out. Hidden drafts and pending writes block
navigation that could replace unfinished work; the person can finish or
explicitly discard local drafts. Obsolete lookups cannot replace newer intent.

Translation records load directly by UUID, independently of loaded list pages,
with native Back, loading, unavailable and Retry states. **Discuss with Toki**
opens a local conversation draft carrying the translation-session UUID. Opening
a link does not create a conversation or send a message. An explicit Send
creates the private conversation with its immutable `translation_session_id`,
then sends using the same conversation/message UUIDs on retry. A source link in
the conversation returns to the translation.

The backend rechecks project and translation-read authorization before attaching
source context. Provenance currently identifies a session and its summary, not
individual source/target segments. It does not approve or publish voice/glossary
changes; that review workflow remains separate.

### Linguistic input inside translation detail

Linguistic reviews load with the translation, not a separate tab. The native
`translation_reviews` command accepts `action: "list"` and the session `id`, or
`action: "answer"` with `id`, `review_id`, and `answer`. Rust owns the fixed
`translations/:id/reviews` and `translations/:id/reviews/:review_id/answer` routes.
Listing requires `translation:read`; answering requires `translation:write` and
project authorization. Existing sign-ins need fresh consent for the new scope.

Each review shows the question, exact source/translation excerpts, locale and
paths. Answers contain 1–8000 characters. Optional reusable guidance has its own
editable 1–8000-character rule and `context_scope` (`locale` or `project`); one-off
answers omit both fields. The server chooses the nearest appropriate `L10N.md`
or `L10N/<locale>.md`. Guidance is a reviewed diff in the normal translation PR,
never a direct repository mutation. Stale and answered reviews are read-only.
Unconfirmed writes require a review reload before an explicit retry, not an
automatic replay. Drafts and pending writes protect navigation; obsolete project
and session responses cannot restore their content.

`awaiting_input` is not failure. File progress supports the same state and a
summary count. The original run remains historical after its questions are
answered. Once its runner releases and all questions are answered, the backend
queues a new session. A review's optional `resumed_session_id`, including one
exposed by a later reload, shows **Translation resumed** and opens that new
translation using existing typed navigation. There is no extra deep-link route.

This slice registers custom-scheme navigation, not verified HTTPS Universal Links
or Android App Links. Those require hosted association documents and stable signed
application identities; arbitrary self-hosted domains are not claimed.

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

# Builds the same JNI/APK, then runs model/render tests and lint:
mise run test:android
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
xcrun simctl launch booted ai.glossia.app

# Compile the device bundle, without distribution credentials:
mise run build:ios-device

# Model tests and simulator interaction tests:
mise run test:ios
mise run test:ios-ui

# Isolated fixture bundle, never linked into production:
mise run preview:ios
xcrun simctl install booted .once/out/GlossiaIOSPreview/GlossiaPreview.app
xcrun simctl launch booted ai.glossia.mobile.preview workspace
```

The simulator target includes its own Keychain entitlement. The device target
still needs an app-specific Apple provisioning profile and signing identity
before installation on a physical device. No signing credentials are committed.
`modules/apple_sdk.star` carries Atlas's Once 0.68.2 SDK-linker workaround.

## CI and validation

`.github/workflows/mobile-native.yml` runs independent Rust, Android, iOS build,
and iOS test jobs. The iOS build matrix compiles simulator and device bundles in
parallel and verifies the embedded Live Activity extension, mascot resource, and
bundle signing. Model tests exercise message replay, access-loss clearing, and
paginated retry; UI tests exercise staged workspace changes, self-hosted URL entry,
live progress, charts, and chat/status placement. Android tests also render both
themes with native Robolectric graphics, using test-only transports rather than
production fixtures.
Artifacts include APKs, app bundles, and test results without publishing releases.
Server authorization and API regressions run in the existing app workflow.

The preview bundle supports `login`, `empty`, `toki`, `chat`, `thinking`, `failed`,
`empty-chat`, `translations`, `translations-empty`, `analytics`, `analytics-empty`,
`profile`, `workspace`, `no-project`, `translation-detail`, `translation-live`, and
`source-chat` launch arguments. `activity-queued`, `activity-running`,
`activity-completed`, `activity-failed`, and `activity-stale` render Toki work states
and exercise the real ActivityKit extension using isolated fixture conversations.
`profile-push-enabled`, `profile-push-denied`, and `profile-push-unavailable` render
the real Profile push controls with isolated storage, permissions, and provider responses.
`review-open`, `review-answered`, `review-stale`, `review-denied`,
`review-loading`, and `review-error` render the production translation detail with
deterministic linguistic goal rows, opening the existing shared Toki thread.
`goal-active`, `goal-editing`, `goal-resolved`, `goal-stale`, `goal-error`,
`goal-permission`, `goal-denied`, and `goal-closed-draft` exercise production Toki
models and views with authorized fake API responses. `goal-rtl`, `goal-hebrew`,
and `goal-rtl-large` render mirrored Arabic/Hebrew content and accessibility text.
The decision fixture includes independently edited reusable guidance; resolved
goals expose the new resumed translation rather than restarting the historical run.
Append `--link URL` to exercise the production navigation adapter against isolated
fixture records; this option is not linked into the production app. To inspect
a server catalog without authenticating, append
`--theme-catalog BASE64_JSON` to a preview launch; it passes through the same Rust
validator and appearance owner. This argument is not in the production bundle.
A fixture capture does not verify a real browser sign-in or inference provider. Physical-device
secure storage, browser handoff, production signing, and live-provider integration
still need deployment/device validation.

## Shared linguistic goals and input

Translation detail links each goal to its server-created, project-shared Toki
conversation. The nested `linguistic_review` on every thread read is authoritative.
Ordinary Toki conversations remain private. Visible, foreground open goals poll
even while idle or editing a resolution, without changing the reviewed reply UUID,
discarding drafts, or automatically approving a teammate's newer reply. Closed
goals retain unsaved decisions until explicitly discarded. An uncertain save must
refresh authoritative state before an explicit retry. Resolution requires a
completed assistant reply to the latest human message, not the opening question.

The composer follows Atlas's final glass-pill layout (Tuist commit `9af36c01be`):
iOS 26 uses regular glass, earlier iOS uses material, and transparency/contrast
accessibility settings use an opaque surface. Android uses the native Material
adaptation with 48 dp targets. Both mirror leading/trailing controls for RTL.
On-device dictation returns editable text, never automatically sends, uses measured
audio/RMS levels, and fences cancelled/late callbacks. Android requires API 31+
and an installed on-device recognizer; iOS requires on-device speech support and
microphone/speech permissions. Fixture waveforms test callback rendering only;
they are not evidence of real device recording, recognition quality, or permissions.

Choose Files imports local UTF-8 text into the editable draft, with strict decoding,
a 16 KiB byte cap and the chat's 4,000-character combined limit. Binary, empty,
oversized and image files are rejected without changing the draft. Photo Library
is explicitly unavailable: the current API is text-only. Real image/document
attachments require a separately specified authorized upload/storage/message API.
Profile fluent-language tags are independent of app locale and never grant access.

## Native localization

Run `mise run localize:extract` on macOS after changing static UI copy. It updates
English Apple `.strings`, permission descriptions from `ios/Info.plist`, and Android
XML resources. User/server questions, messages, names and paths remain verbatim.
Static model errors are localized when created, and format templates preserve their
arguments. `mise run localize:check` checks freshness without modifying catalogs or
translations. The Mobile Native workflow runs it on pull requests and `main`, plus
the extractor regression test and translation-validator tests.

Root `L10N.md` mappings include all three catalogs in the existing default-branch
continuous-translation flow. They inherit the repository's targets: Spanish,
French, German, Japanese, Simplified Chinese, Korean, and Brazilian Portuguese.
Glossia proposes translated catalogs in its normal translation pull request; no
separate mobile translation workflow or token is needed. Once packages translated
`.lproj/*.strings`; Gradle stages `locales/<BCP47>/android/strings.xml` into
`values-b+…` resources before building. Add target languages in root `L10N.md`.

The scoped `L10N.md` validation command runs on Node 22 without Xcode, Android,
Python or external packages in the translation sandbox. It validates candidate
syntax, source keys and printf/bidi placeholders at their real output paths:

```sh
mise exec -- node --test tools/validate_localizations.test.mjs
GLOSSIA_SOURCE_PATH=ios/Resources/en.lproj/Localizable.strings \
GLOSSIA_TARGET_PATH=ios/Resources/en.lproj/Localizable.strings \
mise exec -- node tools/validate_localizations.mjs
```

Model tests include temporary translated runtime resources for button/error copy
and formatting arguments. `TokiInputTest` can also validate staged translated
Android resources with `-PnativeLocalizationSentinel=true`; the temporary German
sentinel catalog used for verification is not shipped. Android production-view
renders can be directed with `-PandroidScreenshotDirectory=/absolute/path`.

Tuist's MIT attribution is included in both app bundles through
[`third_party_notices.txt`](android/res/raw/third_party_notices.txt).
Android's Material icons are covered by the bundled
[`Apache 2.0 license`](android/res/raw/material_icons_license.txt).

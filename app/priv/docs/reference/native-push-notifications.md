%{
  title: "Native push notifications",
  summary: "Provider configuration, opt-in device registration, delivery policy, and native payloads.",
  category: "reference",
  section: "platform",
  order: 30
}
---

## Transport and credentials

Glossia sends directly to APNs for iOS and FCM HTTP v1 for Android. PostgreSQL stores registrations; Oban queues delivery. No messaging service or Firebase iOS SDK is needed. Provider acceptance is not a delivery or read receipt. Ambiguous network failures can produce duplicate alerts.

Provider secrets belong only in the server's existing secret-management system. Never put APNs private keys or Firebase service-account JSON into mobile builds, repository files, logs, or client-visible configuration. Firebase's public Android app identifiers are not service-account credentials.

| Environment variable | Meaning |
| --- | --- |
| `GLOSSIA_APNS_TEAM_ID` | Ten-character Apple team ID. |
| `GLOSSIA_APNS_KEY_ID` | Ten-character Apple signing-key ID. |
| `GLOSSIA_APNS_PRIVATE_KEY` | PEM-encoded private P-256 signing key, preserving newlines. |
| `GLOSSIA_APNS_TOPIC` | The signed iOS application's exact bundle identifier. Clients cannot choose it. |
| `GLOSSIA_APNS_ENVIRONMENT` | `production` (default), `sandbox`, or explicitly `both` for a key that supports both. |
| `GLOSSIA_FCM_SERVICE_ACCOUNT_JSON` | Android Firebase service-account JSON with `type`, `project_id`, `client_email`, and RSA `private_key`. |

Absent APNs credentials disable only iOS. Absent FCM credentials disable only Android. Partial or malformed configured providers fail configuration parsing with a secret-free error. APNs environment is checked at registration and delivery; derive it from the signed provisioning profile, not build-mode assumptions. APNs uses a dedicated HTTP/2-only Finch pool and ES256 authentication. FCM exchanges an RS256 service-account assertion at Google's fixed OAuth endpoint, then uses its fixed HTTP v1 endpoint. Redirects and HTTP-client retries are disabled.

## Registration API

All routes require a bearer OAuth access token issued to the native app's per-installation dynamically registered public PKCE client. Its only redirect URI must be `glossia://oauth/callback`; refresh and revoke must be public, with no client-secret authentication methods. The legacy shared Expo client, account tokens, browser sessions, and other OAuth clients are not installation identities and cannot register devices. This checks client shape, not device attestation.

`PUT /api/me/push-devices/:installation_id` accepts exactly:

```json
{"platform":"ios","token":"<OS device token>","environment":"production"}
```

- `installation_id`: client-generated UUID. It is also the returned and delivered `registration_id`.
- `platform`: `ios` or `android`.
- `environment`: `sandbox` or `production` for iOS; only `production` for Android.
- iOS tokens: 32–512 hexadecimal characters, even length, normalized to lowercase.
- Android tokens: 16–4096 printable non-space ASCII characters.
- Successful PUT: `{"registered":true,"registration_id":"<installation UUID>"}`.
- Unknown fields, including owner selectors, topic, host, and provider URLs, are rejected.

`DELETE /api/me/push-devices/:installation_id` returns `{"deleted":true}` idempotently. Unknown IDs become tombstones, so a delayed PUT cannot resurrect an installation after sign-out. A different user's unrelated installation is never changed. The same native OAuth client may retire its previous user's installation during offline sign-out recovery, but ownership never moves. Rotate to a fresh installation UUID after `409 installation_retired`.

`GET /api/me/push-devices/capabilities` returns `{"ios":true,"android":false}` according to configured providers; it has the same authentication requirement. A true iOS capability does not override APNs environment restrictions.

Responses are `no-store`. Mutations are limited to 120 requests per user per hour, in addition to the API limit. Missing/invalid bearer authentication returns 401; non-native credentials return 403; invalid device data returns 400; retired/conflicting installations return 409; unavailable providers return 503. Cleanup remains available when a provider is disabled.

## Delivery intents

Internal callers use the fixed API after their source transaction commits:

```elixir
Glossia.Push.notify_user(user_id, "toki_completed", %{
  conversation_id: conversation.id,
  message_id: completed_user_message.id
})

Glossia.Push.notify_user(user_id, "linguistic_input_needed", %{
  translation_session_id: session.id,
  review_id: review.id
})
```

The kind may also be the corresponding atom. The return is `{:ok, queued_count}` or `{:error, :invalid_notification}`. There is no arbitrary-recipient public send API, custom notification text, inference retry, or implicit opt-in.

`toki_completed` requires the exact completed **user** message and its completed assistant reply. In private conversations the recipient must own the history; in shared goal conversations they must still be an eligible invited fluent participant and the goal must be open. It checks current Toki/project access and, for source-linked conversations, current translation read access and source existence. A different completed message or an assistant message ID is not a substitute.

`linguistic_input_needed` requires the identified open goal on the specified translation session and an eligible invited fluent participant. A session-only source remains accepted for compatibility and resolves an eligible open goal. Reviews on another session do not qualify. All matching authorized teammates join the same Toki conversation; delivery independently rechecks current fluency, Toki/translation/project access, and membership.

There are at most ten live registrations per user. Tokens are encrypted with the existing Cloak vault and indexed by a SHA-256 digest. Token movement retires the old registration, and provider invalidation compares the attempted digest/environment before clearing anything. APNs last-invalid timestamps do not retire registrations refreshed after that timestamp.

Delivery jobs contain only IDs, kind, source IDs, and expiry. Every attempt rechecks the registration, owner, current persisted native OAuth refresh grant and scopes, source, membership, and expiry. It checks again after provider credential acquisition, immediately before transport. Access-token expiry alone does not end a still-valid refresh session. Revocation, refresh expiry, missing source access, sign-out, or resolved reviews cancel delivery.

Both kinds expire after one hour. There are at most five provider attempts, including provider-backpressure snoozes. Retry-After is honored only within the notification lifetime. No provider response body or token is returned as a job error. Refresh registrations on foreground; registrations not refreshed for 60 days are retired. The hourly prune worker scans a bounded rotating batch of 1,000 rows and removes tokens for stale or ended sessions. Tombstones retain only installation/client IDs, platform/environment, and lifecycle timestamps indefinitely to fence delayed requests; retired rows have no user, token, or digest. Account deletion severs the user reference, prevents all delivery immediately, and the prune worker clears the retained token.

Provider credentials use a bounded, expiry-aware Cachex cache. Key rotation changes cache identity. APNs JWTs are reused for 50 minutes; FCM credentials expire five minutes before provider expiry (at most 50 minutes). Failures are not cached.

## Payload version 1

APNs includes the generic alert **Glossia / You have an update in Glossia.** FCM sends data-only messages with the same `title` and `body`, for local rendering. Neither includes private prompts, replies, questions, source excerpts, or project titles. Routing fields are strings:

```json
{"v":"1","url":"glossia://navigate/org/project/toki/CONVERSATION_UUID?server=https%3A%2F%2Fglossia.ai","registration_id":"INSTALLATION_UUID"}
```

Both notification kinds open `/org/project/toki/CONVERSATION_UUID`; linguistic help requests open their shared goal thread. The `server` is the configured Phoenix endpoint's HTTPS origin, never request headers or client input. HTTP-only endpoint configurations fail closed at delivery. Native clients must reject unknown versions, mismatched origins/registrations, and unrecognized routes; tapping never changes servers or executes mutations. The fetched destination must still pass normal API authorization.

## Runtime integration

The parent application starts `Glossia.Push.Supervisor` before Oban, providing the credential cache and dedicated APNs Finch pool. Runtime configuration calls `Glossia.Push.Config.parse!(System.get_env())`. Oban's `push` queue has concurrency five and runs `Glossia.Push.Prune` hourly. The three registration routes run in the existing bearer-authenticated API pipeline.

Request logging redacts device tokens. The endpoint extends Sentry's default body scrubber with Phoenix's parameter filter, preserving its existing protections:

```elixir
config :phoenix, :filter_parameters, ["password", "passwd", "secret", "token"]

# Endpoint request-body scrubber
plug Sentry.PlugContext, body_scrubber: {__MODULE__, :scrub_request_body}
def scrub_request_body(conn) do
  conn
  |> Sentry.PlugContext.default_body_scrubber()
  |> Phoenix.Logger.filter_values()
end

# Defense in depth: no Phoenix parameter logging for enrollment
put "/me/push-devices/:installation_id", PushDeviceController, :update, log: false
```

Do not retain raw push request bodies in custom telemetry or exception reports.

Only parent web/worker processes need the push supervisor and queue. Translation runner pods can enqueue IDs without credentials, an APNs pool, or a new messaging service. Apply the migration through the normal release workflow. Keep exported account data free of provider tokens. Do not delete tombstones as routine retention cleanup.

Physical-device checks remain necessary: configured signed iOS/Android builds, permission allowed/denied, foreground/background/terminated delivery, cold-start taps, provider token rotation, expired credentials, offline sign-out cleanup, and account switching. Stubbed provider tests do not establish live delivery. Native builds include notification lifecycle support and Android Firebase dependencies, but this code does not provision credentials, shared infrastructure, signed provisioning profiles, or Firebase app identifiers.

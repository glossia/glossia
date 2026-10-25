%{
  title: "Mobile and companion API",
  summary: "Native appearance, profile, translation activity, analytics, and private Toki conversations.",
  category: "reference",
  subcategory: "apis",
  order: 4
}
---

All endpoints except the public native appearance catalog require a bearer token. The [OpenAPI specification](/api/openapi.json) describes the complete schemas. Obtain tokens through the existing [OAuth PKCE flow](/docs/reference/apis/authentication). Never embed an inference provider key in a client.

## Authorization

| Endpoint | Token scope |
|---|---|
| `GET /api/native/themes` | None (public appearance metadata) |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

Token scopes are a ceiling, not a grant. Each project endpoint also checks the user's project-read permission. A second `project:read` **token** scope is not required, but an organization membership with explicit permissions must permit both project reads and the requested capability. New memberships include these mobile capabilities; existing explicit memberships are not automatically widened.

Personal projects follow the existing personal-organization membership rules. Account visibility controls public project reads; an authenticated outsider with the required scope can read a public project's translation activity and analytics. Toki writes require account membership, so public visibility alone does not spend an account's inference credits. Toki conversations remain private to their creating user within their project, even on public accounts. Organization and platform administrators cannot read another user's conversation. Knowing a conversation UUID does not grant access.

## Native appearance

`GET /api/native/themes` returns instance-wide appearance metadata from the selected Glossia server, without authentication or user/project data. Responses include `Cache-Control: public, max-age=300`. This does not change authorization for any project endpoint.

The response has four required fields:

| Field | Value |
|---|---|
| `schema_version` | Integer `1` |
| `revision` | Non-blank content revision, at most 128 characters |
| `default_theme_id` | `"glossia"` |
| `themes` | Array containing the default Glossia theme |

The default theme has `id: "glossia"`, `name: "Glossia"`, a non-blank `description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12`, and `light` and `dark` palettes. Radii are numeric logical pixels. Each palette contains all nine fields below, expressed as opaque `#RRGGBB` colors:

| Palette field | Light | Dark |
|---|---|---|
| `background` | `#FAF8F5` | `#1C1917` |
| `surface` | `#FFFFFF` | `#2A2621` |
| `subtle` | `#F2EFE9` | `#2A2621` |
| `text` | `#1C1917` | `#FAF8F5` |
| `secondary_text` | `#5C564E` | `#D1CDC5` |
| `border` | `#E4E0D9` | `#3D3833` |
| `accent` | `#6D3CC4` | `#D0BCFF` |
| `on_accent` | `#FFFFFF` | `#381E72` |
| `tint` | `#6D3CC4` | `#D0BCFF` |

The catalog is compiled from the canonical `:root` color and radius tokens in `app/priv/static/assets/styles.css`. The dark palette uses native-only semantic tokens and does not change web rendering. Rebuilding after a token change updates the catalog and its deterministic revision. The revision covers catalog content, not unrelated stylesheet edits. No per-user preferences or runtime theme configuration are included.

## Profile

`GET /api/me` returns only the authenticated user's profile:

```json
{
  "user": {
    "id": "30c92fe9-4477-4ba6-ae0a-0d874f9ff650",
    "name": "Alex Chen",
    "email": "alex@example.com",
    "handle": "alex"
  },
  "server_version": "0.1.0"
}
```

`name` can be `null`. The handle belongs to the user's personal account, not the selected organization. `server_version` is the running application's version.

## Pagination

Translation and conversation lists accept `page` (default `1`, range `1–10000`) and `page_size` (default `20`, range `1–50`). Invalid values return `400` rather than silently clamping. Metadata uses the same shape as other Glossia API lists:

```json
{
  "total_count": 23,
  "total_pages": 2,
  "current_page": 1,
  "page_size": 20,
  "has_next_page?": true,
  "has_previous_page?": false
}
```

Lists reflect current state, not a frozen snapshot. Conversation ordering is most recently updated first, with UUID as a deterministic tie-breaker.

## Translation activity

`GET /api/:handle/projects/:project/translations?page=1` returns:

```json
{
  "sessions": [{
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "completed",
    "commit_message": "Update installation guide",
    "source_language": "en",
    "target_languages": ["es", "ja"],
    "translated_content_count": 8,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": "Translated eight documents."
  }],
  "meta": {"total_count": 1, "total_pages": 1, "current_page": 1, "page_size": 20, "has_next_page?": false, "has_previous_page?": false}
}
```

Statuses are `pending`, `running`, `completed`, `failed`, or `cancelled`. Commit message, source language, and summary can be `null` while work is pending or when unavailable. Results are newest first and restricted to the addressed project.

`GET /api/:handle/projects/:project/translations/:id` returns `{session: {...}}` with exactly the list session fields plus nullable `commit_sha`. This is a direct, exact UUID lookup within the addressed project and account, independent of pagination or the session's age. Malformed, missing, and foreign-project IDs return `404` with `error: "not_found"`; authentication and project authorization still run first (`401`/`403`). Opening this resource never creates a conversation, sends a message, or starts inference. It provides **session-summary-level provenance**, not translated segment text or a review of translated output.

## Analytics

`GET /api/:handle/projects/:project/analytics?days=30` returns:

```json
{
  "summary": {
    "pageviews": 1350,
    "unique_visitors": 900,
    "locale_gap_visits": 180,
    "top_country": "DE",
    "top_browser_language": "de"
  },
  "top_pages": [{"pathname": "/docs", "pageviews": 420}],
  "days": 30
}
```

`days` defaults to `30` and must be an integer from `1` to `365`. The rolling UTC reporting window ends at request time. These are the same project-scoped ClickHouse aggregates as the dashboard, including its daily-rotated visitor identifiers. The top-pages list contains at most ten entries. Empty datasets return zero counts, empty top-value strings, and an empty page list. Storage failures return `503` with `error: "analytics_unavailable"`, never invented zero metrics.

## Toki conversations

### Create and list

`POST /api/:handle/projects/:project/toki/conversations` accepts a client-generated UUID:

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

It returns `201` with `{conversation, messages: []}`. Empty conversations have title `New conversation` and status `completed` (idle, not generating). Replaying the same UUID for the same actor, project, and origin returns the existing detail without creating another conversation. Reusing it for another actor, project, or origin returns `409` with `error: "id_conflict"`.

`GET /api/:handle/projects/:project/toki/conversations` returns `{conversations: [...], meta: {...}}`. A conversation contains `id`, `title`, `status`, `updated_at`, nullable `error`, and nullable `translation_session_id`. Titles are derived from the first user message, not from a second model call.

### Translation origin

Creation optionally accepts a translation session UUID from the same project:

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

The origin is immutable; omission and `null` both mean no origin. A retry must supply the same origin, including after sending messages. You cannot attach an origin later or remove one with a retry. A malformed origin returns `422`; a missing or foreign-project source returns `404`. Source-linked creation additionally requires `translation:read` token scope and current policy permission, alongside `toki:write` and project-read permission. Client-supplied source summaries, metadata, roles, and ownership are ignored. Only the UUID is persisted; the server resolves its authorized context at reply time.

**Source-linked conversations fail closed**, rather than merely redacting the UUID: without current `translation:read` scope or policy permission, detail, matching-origin create replay, message send, and message replay return `403`. A mismatched origin still returns `409` without returning history or source metadata. Lists omit the entire source-linked conversation, including its title and contribution to pagination counts. This protects earlier assistant messages that might mention the source. Missing scopes include the normal `WWW-Authenticate` challenge. Unlinked conversations keep their existing Toki-only authorization behavior.

Deleted or moved sources also fail closed: source-linked detail, sends, and matching create retries return `404`, and lists omit the conversation. The immutable UUID remains stored after source deletion so a retry cannot silently become unlinked. The reference has no cascading foreign key; every use checks current source existence and its exact project/account. No source reference confers access or changes a voice, glossary, or shared context.

Creating or opening a source-linked conversation does **not** send a message or enqueue inference. Native navigation should fetch the translation detail first; only an explicit user action should create the conversation, and a separate explicit message submission starts a turn. No proposal publication, shared discussion review, or agent write tools are provided.

### Send and poll

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` accepts a separate client-generated **message** UUID:

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

The request persists the user message and an Oban job in one database transaction. It does not call a model. It returns `202` with conversation status `queued` and the current messages. Poll `GET /api/:handle/projects/:project/toki/conversations/:id` while status is `queued` or `running`; stop on `completed` or `failed`.

Detail responses have this shape:

```json
{
  "conversation": {
    "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
    "translation_session_id": null,
    "title": "Which translations have completed?",
    "status": "queued",
    "updated_at": "2026-10-25T10:00:00Z",
    "error": null
  },
  "messages": [{
    "id": "17c3b189-80f0-4382-b7bb-1305b1db70ad",
    "role": "user",
    "content": "Which translations have completed?",
    "inserted_at": "2026-10-25T10:00:00Z"
  }]
}
```

Messages have role `user` or `assistant` and are chronological. A conversation holds at most 100 messages, so the detail endpoint returns its entire bounded history without an additional page request.

Replaying a message UUID with identical content never enqueues another inference, including after completion or failure. A settled replay returns `200`; a pending replay returns `202`. Reusing a UUID with different content or in another conversation returns `409`. A different message submitted while a turn is active returns `409` with `error: "conversation_busy"`.

### Model behavior and limits

- Each user message is non-blank text, at most 8,000 characters and 32,000 UTF-8 bytes. Invalid UUIDs, types, or content return `422`.
- Each user can hold at most 100 conversations per project and five queued/running conversations across projects. More than five pending turns returns `429`; conversation/history limits return `422`.
- New messages are limited to 30 per hour per user per server, in addition to normal API rate limits. Replays do not consume inference quota.
- The dedicated Oban queue runs two jobs concurrently per server. Each turn makes at most one provider HTTP request: ReqLLM prepares the provider request, then the Oban worker executes it synchronously with HTTP retries and redirects disabled after provider attachment. No Condukt session, detached inference task, tools, subagents, or filesystem instruction loading is involved. The provider receives a 2,048-output-token ceiling; assistant replies are also limited to 8,000 characters and 32,000 bytes.
- HTTP connection and pool waits are limited to five seconds and socket receive waits to sixty seconds. The Oban worker has a ninety-second hard wall-clock deadline, including trickling responses. Worker termination also terminates its local inference execution. Disconnecting cannot guarantee cancellation of computation already accepted by a remote provider, so ambiguous failures are never retried automatically.
- The model receives bounded project metadata and at most three recent translation summaries when both the token and current membership permit `translation:read`. The last ten conversation excerpts are bounded independently of storage. It has no write capabilities or general repository access, and no analytics are supplied to the model.
- For a source-linked conversation, the model additionally receives the exact persisted source, even if it is not recent: UUID, status, commit metadata, languages, count, and at most 1,000 summary characters. Context is labeled `provenance: "session_summary"`, and the prompt requires reporting this summary-level limitation. No segment text, repository files, or client-supplied source context is loaded.
- Credentials resolve through the account's existing generative model and server inference configuration. Interactive CLI/OAuth sessions are not used for Toki. Missing or unsupported credentials produce status `failed` with `error: "provider_unavailable"`.
- Provider failures produce `inference_failed`; empty or oversized output produces `invalid_provider_response`. Raw provider errors and secrets are not returned. No synthetic assistant reply is inserted on failure.
- Account/project access and source existence, project/account association, and translation authorization are checked again before and after inference. Revoked access or insufficient queued scopes fail the turn with `not_authorized`; a deleted or moved source fails with `source_unavailable`. No assistant response is persisted on either failure.
- A recovery job runs every minute and marks running work older than two minutes, or queued work older than fifteen minutes, as `failed` with `inference_interrupted`. This settles timed-out, terminated, and orphaned jobs without retrying inference. A delayed job cannot claim an expired message or overwrite a newer turn. A user may deliberately send a **new** message UUID after a failure.

## Errors

`401` means authentication failed. `403` means the scope or resource policy denied access; missing scopes include a `WWW-Authenticate` challenge. Unknown projects and foreign/private conversation UUIDs return `404`. Validation uses `422`, pagination uses `400`, UUID/busy conflicts use `409`, and quota exhaustion uses `429`.

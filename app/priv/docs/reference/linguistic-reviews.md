%{
  title: "Linguistic reviews",
  summary: "Source-bound human decisions, translation continuations, and reviewed repository guidance.",
  category: "reference",
  section: "translation",
  order: 31
}
---

## Escalation

Repository translation runs with a configured decision model can request linguistic input for missing source meaning or domain context, conflicting guidance, or consequential cultural adaptation. Low confidence alone does not trigger a question. Errors correctable from existing context use the ordinary correction budget; quality failures remaining after that budget can also request input. Without a decision model, automatic linguistic escalation is disabled.

Only the affected file/locale stops. Its unapproved candidate is not published. Independent files complete and can publish normally. After publication finishes, the session becomes `awaiting_input` and releases its runner. It does not consume a worker while a human is answering.

Each escalation opens one **shared Toki conversation with a defined linguistic goal**, linked to the translation session. Participants discuss the meaning, ask follow-up questions, and refine a proposed decision. Discussion alone never approves a translation or writes repository context. Ordinary Toki conversations remain private to their owner, including from administrators.

All currently authorized teammates whose declared fluent languages match the target locale are invited to the same conversation. Fluency is separate from the display language and does not grant project access or permission to approve decisions. A broad language such as `es` matches regional variants such as `es-MX`; incompatible explicit scripts do not match. Regional declarations such as `zh-TW` use their customary CLDR script, while broad `zh` remains unrestricted by script.

Eligible participants receive generic mobile push notifications only when they have opted in; delivery rechecks current fluency, membership, project access, and the open goal. Notifications open the shared conversation. Conversations and approvals are available from both native apps and the web dashboard. See [Native push notifications](/docs/reference/native-push-notifications) for provider configuration and delivery policy.

## Fluent-language profile

`GET /api/me` includes `user.fluent_languages`. `PUT /api/me/fluent-languages` requires `user:write` and accepts only `{"fluent_languages": ["es", "ar", "zh-Hant"]}`. It replaces the authenticated user's list and returns the profile envelope. Supported CLDR BCP47 tags retain explicit region/script specificity and use canonical casing; duplicates collapse. An empty array clears fluency. Invalid tags, unrelated fields, or more than 50 submitted entries return 422. This never changes the UI locale.

## Review API

`GET /api/:handle/projects/:project/translations/:id/reviews` requires `translation:read` and project access. It returns `{"reviews": [...]}`, with open questions first and then oldest first, limited to 500 entries. Refresh after answering to reveal any remaining questions; answered history never hides an open question behind the limit.

Each review includes `id`, `translation_session_id`, `conversation_id`, `participants` (`id` and nullable `name`), `status`, `source_path`, `output_path`, `locale`, `question`, bounded `source_excerpt` and `translation_excerpt`, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id`, and `inserted_at`. Status is `open`, `answered`, or `stale`.

Use the existing project Toki conversation and message endpoints for discussion. Shared goal conversations appear alongside the actor's private conversations in Toki history. Shared histories require current Toki read/write policy permission and translation read access; ordinary histories remain owner-only. Human messages include their author identity, and replies include `status` and `reply_to_id`. Toki receives bounded source/candidate excerpts and the goal, not repository write access.

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` requires both `translation:read` and `translation:write`, plus project access:

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` must identify the latest completed assistant **reply** in the goal conversation, not its opening question. `answer` is the human-approved decision and is required and non-blank. `guidance` and `context_scope` are optional; scope defaults to `locale` and can also be `project`. Answer and guidance each allow up to 8,000 characters and 32,000 UTF-8 bytes. Guidance cannot contain Glossia's reserved review-marker comments. The server chooses repository paths; a client-supplied path is never used.

A successful response is `{"review": {...}}`. Replaying the same decision, resolution message, guidance, and scope is idempotent. A busy conversation returns `409 conversation_busy`; a newer message or invalid resolution reference returns `409 resolution_outdated`. Reload and review the current discussion before approving again. A different decision on a resolved goal returns `409 already_answered`; approving a cancelled or superseded goal returns `409 stale`. Invalid text or unavailable scope returns 422. Missing and foreign-project IDs return 404. Normal authentication and project authorization apply on every request, including replays. Closed goals reject new discussion messages with `409 goal_closed`.

## Continuations and stale context

Decisions can be approved while independent work is still running. They never start a second runner then. Once the runner has released and every goal in that run is resolved, Glossia atomically queues one continuation session. `resumed_session_id` identifies it; the original session remains historical `awaiting_input`. Both dashboard and native conversations link to the continuation.

The continuation has a fresh execution identity and retains the translation publication branch and validated outputs. Each answer applies only to the identical source and resolved translation-context fingerprint. Changed source, voice, glossary, model, or repository instructions prevent answer reuse. A newer default-branch commit supersedes waiting sessions and marks open questions stale. Cancellation also marks open questions stale.

## Reusable repository guidance

Reusable guidance is a separate, explicit human edit. An answer alone does not become repository context, and private chat transcripts are never copied automatically.

`locale` targets the applicable locale overlay, such as `L10N/es.md`; `project` targets the applicable `L10N.md`. Existing scoped context files are respected. Missing locale overlays receive their locale frontmatter. Existing frontmatter and prose are preserved, and each decision is appended with its review UUID for provenance and idempotency.

Guidance is proposed in the normal translation pull request, not written silently to the default branch. The repository must still match the recorded context digest; a conflicting edit fails publication instead of overwriting it. Paths must be repository-relative localization documents without traversal or symlinks. Each context document is limited to 1 MiB. Merging the pull request makes the guidance ordinary versioned localization context for later runs.

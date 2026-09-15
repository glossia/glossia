%{
  title: "Translation recovery",
  summary: "How Glossia recovers from provider throttling and interrupted translations.",
  category: "explanation",
  order: 8
}
---

Glossia validates translated content before publishing it. Recovery preserves
that requirement: a retry must still preserve the source structure and required
placeholders, and every assembled file passes its configured validation commands.

## Catalog translation

Gettext catalogs are parsed into strings before translation. Requests carry at
most eight strings, with an 8,000-byte batching target. A single larger string
stays intact. The model returns an array with the same number of strings in the
same order. Glossia checks interpolation variables and rejects empty translations.

Headers are built in code using the target locale's plural rules. Source message
identifiers, comments, and catalog structure come from the parsed source. If a
batch returns malformed content, Glossia retries it once, then splits it into
smaller batches. Successful neighboring batches do not need to be translated again.

## Provider throttling

Workers using the same credential and model share request admission through the
database, including workers on different application replicas. A rate-limit
response extends their shared cooldown and increases spacing between new requests.
Successful traffic gradually reduces that spacing after a minute without throttling.
Already-running requests are allowed to finish.

Provider retry hints are minimum delays. Repeated failures also increase the
backoff, up to a 30-second base delay plus jitter; a longer provider hint takes
precedence, capped at five minutes. Together's `x-ratelimit-reset` header is
recognized alongside `retry-after`.

After eight unsuccessful request attempts, the repository run stops starting new
files. A delayed continuation inherits the translation branch and resumes its
unfinished work. The previous attempt remains visible in session history, linked
through the continuation. Delays increase from one minute to five minutes, with
at most six automatic continuations. Newer active sessions take precedence, and
cancelled sessions are never revived. Validation failures alone do not schedule
provider recovery.

## Durable progress

Completed files and their lockfiles are published to the translation branch as
before. Within unfinished files, locally validated segments and recovery batches
are also saved in the database for seven days. These checkpoints survive a worker
process stopping. They are scoped to the account, project, document input,
effective credential and model, context, and segment or repair attempt.

A resumed run can reuse a segment only when its inputs still match. It always
validates the final assembled document again. Rejected model responses are not
checkpoints. A document-level validation failure starts a separate repair attempt
because the validator may not identify a single responsible segment.

Expired checkpoints and inactive provider pacing records are removed by the
scheduled session recovery worker. These are operational records; users do not
need to add them to their repository or configure them in `L10N.md`.

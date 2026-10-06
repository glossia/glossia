%{
  title: "Translation recovery",
  summary: "How Glossia keeps Markdown intact and recovers from provider throttling and interrupted translations.",
  category: "explanation",
  section: "translation",
  order: 8
}
---

Glossia validates translated content before publishing it. Recovery preserves
that requirement: a retry must still preserve the source structure and required
placeholders, and every assembled file passes its configured validation commands.

## Markdown translation

Glossia never re-renders a translated Markdown document. It parses the source
only to find its prose: paragraphs, headings, list items, table cells, the
reader-facing attributes of components and HTML (`title`, `details`, `alt`,
`label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), and
the text of an HTML `<summary>`. Each translation is written back into the exact
bytes its source occupied, so code, link destinations, components, GitHub
alerts, explicit heading anchors such as `{#install}`, list markers, and blank
lines stay byte-for-byte identical.

Each paragraph or heading is translated as a whole sentence. Inline formatting
becomes numbered tags: `<gN>...</gN>` around linked or emphasized words, and
`<gN/>` for content that must not change, such as inline code or a component.
The model may move tags to follow the target language's word order, but must
keep every tag exactly once. Every request also carries the surrounding source
document, and the most recent translations from the same file, for reference.

A unit that drops or invents a tag is sent again on its own, with the reason,
up to three times. Units that came back valid are kept. After splicing, Glossia
parses the result and compares its structure to the source. A translation that
would turn into a heading, list, or emphasis by itself has its prose escaped,
which needs no further model call.

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

Glossia coordinates translation requests that use the same credential and model. A rate-limit
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

Completed files and their lockfiles are published to the translation branch in
batches: one commit for every 25 files, or every 15 minutes, and a final commit
when the run ends. Each push runs the repository's pull request checks, so
batching keeps a large run from starting one check run per file. A project has
a single translation pull request: a new commit on the default branch continues
the open one, and only translates what changed since. Once that pull request is
merged or closed, the next run starts a new one. Within unfinished files, locally validated segments and recovery batches
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

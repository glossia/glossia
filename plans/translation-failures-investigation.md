# Translation failures: investigation and fix plan

> Draft investigation and proposed fixes. No application fixes have shipped from this work. Historical attribution and the residual upgraded-workload failure remain under validation; this document is not deployment or recovery approval.

## Scope and conclusion

Investigated production session `01a14f57-94f4-7fb3-b8b5-592edb698901` from October 18, 2026. Its persisted results are **265 completed files, 101 generic failures, and 5 Markdown-structure failures**.

Two reproducible implementation defects are consistent with these failure classes. The subprocess defect is a leading explanation for the opaque historical failures, not an item-by-item attribution:

1. The pinned **MuonTrap 2.0.0-rc.1 silently truncates subprocess output while returning exit code 0**. This corrupts the Git change manifest during publication. The upstream fix is already released in 2.0.0 and 2.0.1.
2. Markdown unit extraction **reverses the parts inside nested inline formatting**. Two units in the glossary reference consequently generate malformed templates that can produce invalid bold syntax or silently reordered prose.

A third defect obscured the incident: publication errors are classified as generic translation failures and their safe cause is not retained.

No application source, dependency lockfile, production configuration, or session state was changed during this investigation. Proposed fixes were tested in isolated probes. Production diagnostics were limited to reads and ten bounded commands producing bytes from `/dev/zero`; no translation was launched or retried.

## Evidence: subprocess truncation and the 101 opaque failures

### Production evidence

All 101 generic failures recorded zero new model calls. Zero calls alone is not evidence of a failure before translation: successful checkpoint replays also record zero calls. Of the 265 successes, 250 likewise recorded zero calls.

The deployed application reports MuonTrap `2.0.0-rc.1`. In the deployed Linux release, ten calls to:

```elixir
MuonTrap.cmd("head", ["-c", "65536", "/dev/zero"], into: "", timeout: 5000)
```

returned these `{captured_bytes, exit_status}` pairs:

```text
{20480, 0}, {10240, 0}, {20480, 0}, {20480, 0}, {30720, 0},
{65536, 0}, {30720, 0}, {30720, 0}, {10240, 0}, {40960, 0}
```

Nine of ten successful commands lost output. This reproduction requires no Git activity, provider, concurrency, or repository content.

### Application failure path

- `app/mix.exs:110` and `app/mix.lock` pin the affected release candidate.
- `RepositoryRun.completed_item_changes/2` calls `collect_changes/1`, collecting the entire checkout before selecting the current output and lockfile.
- `collect_changes/1` trusts successful `git status --porcelain --untracked-files=all` output.
- A truncated final line is accepted as a filename by the porcelain parser.
- `attach_content/2` attempts `File.read!` on that nonexistent partial filename.
- `publish_completed_item/3` rescues the exception as `{:publication_callback_failed, message}`.
- The caller wraps it in `{:translation_publication_failed, reason}`, but `Failure.from/2` has no publication clause. It falls back to `translation-failed` and discards the underlying cause.

This explains how a validated translation restored from a checkpoint is reported as a translation failure without making a new model call. It also explains why unrelated legal and marketing files fail: collection reads the whole manifest, so a malformed entry for any other file can fail the current file's publication.

The original raw errors for the 101 historical failures were not retained. The exact truncated pathname for each historical event cannot be reconstructed. However, the failure mechanism is reproduced both in production and through the actual repository orchestration code, with the same classification and zero-call symptoms.

### Isolated application reproduction

Ran the actual `RepositoryRun` and `PublicationBatch` modules against a temporary Git repository containing the English Markdown corpus, expanded to seven locales: **343 items**. Context, credentials, translation, and lock generation were isolated with deterministic test doubles; the actual Git collector, porcelain parser, file reads, publication orchestration, and failure classifier were exercised. Publication itself was a successful in-memory callback, so GitHub and the model provider could not cause failures.

With the existing dependency:

- **172 of 343 items failed** with `translation-failed`.
- Captured raw errors included reads of nonexistent partial paths such as `app/priv/i18n/es/docs/explanation/continuous-local` and `.glossia/.../ko.loc`.
- The complete final status manifest was 40,873 bytes and 686 records.

Changing only MuonTrap to **2.0.1** made the same harness return:

```text
RESULT: {:ok, 686}
```

All 343 items succeeded and both artifacts per item were collected in that run. However, a subsequent stress rerun under the nominal 2.0.1 setup produced **34 similar failures**. After adding runtime-path and incomplete-manifest instrumentation, another upgrade-only run succeeded and verified every artifact. Therefore, the first clean run is not sufficient evidence that the dependency bump alone eliminates every loaded-workload failure. The residual result remains an explicit release concern, not an ignored outlier.

The plan was revised and a second prototype replaced only per-item whole-checkout scanning with reads of the item's two owned artifacts. With 2.0.1 plus that isolation, the initial run and **three additional fresh-repository runs** all succeeded. Each repeat verified the exact 686 paths, all 343 deterministic output contents, and valid lockfile contents. A final whole-repository collection still ran once, so its output completeness remains a Linux acceptance gate.

### Upstream confirmation and focused controls

Upstream commit [`92179bcad0da`](https://github.com/fhunleth/muontrap/commit/92179bcad0da) fixes this exact issue: the supervisor reaped the child and returned before draining captured output pipes. Its acknowledgment handling did not recover bytes still in those pipes. The fix first shipped after rc.1 and is included in stable 2.0.1.

Local controls, 50 runs per case:

| Case | 2.0.0-rc.1 incomplete captures | 2.0.1 incomplete captures |
|---|---:|---:|
| 65,536-byte stdout | 48/50 | 0/50 |
| stdout plus stderr sentinel | 40/50 | 0/50 |
| 65,536-byte output followed by exit 7 | 30/50 | 0/50 |

The nonzero-exit case also verifies that complete capture does not erase the command's actual failure status. Separately, 100 sequential and 200 concurrent fixed-version Git captures matched the complete 40,873-byte reference byte for byte. These focused controls do not invalidate the residual failure observed in the heavier repository workload. Fixed-version controls ran on macOS; Linux CI and repeated full-workload integrity tests remain release gates.

## Evidence: the five glossary structure failures

The five explicit structure failures are the German, Spanish, Japanese, Portuguese, and Simplified Chinese versions of `app/priv/docs/reference/glossary.md`.

In `MarkdownUnits.template/5`, collected parts are already returned in source order. `node_part/6` reverses those parts a second time at `app/lib/glossia/translations/markdown_units.ex:339`:

```elixir
parts = ["</g#{n}>", Enum.reverse(inner), "<g#{n}>" | parts]
```

For this source:

```markdown
**Missing `source`.** Every term needs a non-empty one.
```

the incorrect template is:

```text
<g1>.<g2/>Missing </g1> Every term needs a non-empty one.
```

It should be:

```text
<g1>Missing <g2/>.</g1> Every term needs a non-empty one.
```

The incorrect template renders a space immediately before the closing `**`, which changes how Markdown parses the bold span. Escaping translated prose cannot fix this: the malformed arrangement is in syntax restored by the application, not introduced by the model.

The same defect affects the adjacent `` **Duplicate `id`.** `` unit. These are units `u36` and `u37` in the current glossary document.

### Why existing tests missed it

`MarkdownUnits.render/3` has an identity fast path: if the translated template equals the source template, it returns the original raw bytes. Therefore, an unchanged-template round trip can pass even when the generated template is wrong. Existing examples also did not exercise multiple text/code pieces inside an inline container.

### Prototype and coverage

The prototype replaces only `Enum.reverse(inner)` with `inner`.

Across the current English Markdown corpus:

- **49 files, 1,490 translation units**.
- Before the fix, identity rendering passed all files, but prefixing or suffixing every unit with ordinary `ES` text deterministically failed the glossary document.
- After the fix, identity, prefix, and suffix transformations all preserved structure across all 49 files.
- Comparing templates before and after showed changes in exactly **two units of one file**, matching the production failure location.
- Running the actual `Engine.apply_item/5` with deterministic translation responses and translated frontmatter changed from **48/49 successful documents to 49/49**. Quality assessment and context were stubbed; this is not a linguistic-quality evaluation or a full production integration test.
- The existing ten `MarkdownUnitsTest` tests passed before and after the prototype in a standalone ExUnit run.

The affected segment is expected to get a different checkpoint key: `Engine.checkpoint/5` includes the segment, including its units, in the value passed to `Checkpoints.key/1`. An old-template checkpoint miss and an unrelated-segment hit still need an explicit regression test before recovery; the corpus probes do not establish cache behavior. A global checkpoint purge is not justified by the current evidence. Existing file-level locks do not automatically become stale merely because this implementation changes; an audit of any previously completed glossary locale should therefore be targeted rather than assumed to happen automatically.

## Adversarial review outcomes

The initial self-review was followed by a separate adversarial review with Claude. Claude reviewed the document and supplied source context but did not independently reproduce the experiments. The review supports publishing an explicitly draft investigation, not approving implementation, deployment, or recovery.

The unresolved 34-failure run has competing explanations: an unverified loaded port binary, another output-capture defect, or a whole-checkout filesystem race. A repeat must record the loaded version and executable hash, compare captured bytes with an independently retained manifest, and distinguish a truncated path from a complete transient pathname. Four clean isolated-manifest runs demonstrate promising behavior, not a correctness guarantee.

| Challenge | Finding and resulting decision |
|---|---|
| Could this be provider credits, rate limits, or low model quality? | The bad dependency truncates `/dev/zero` without a provider, and the publication harness fails with a successful fake translator. The glossary also fails on harmless deterministic text transformations. Do not change providers, budgets, or quality thresholds for this incident. |
| Could a shared Git index or file-write race also contribute? | Open. Capture fails without Git or concurrency, proving the rc.1 defect, but that does not exclude a second race in whole-checkout collection. Do not use the first clean upgrade run to dismiss that alternative. |
| Why not increase `stdio_window`, add sleeps, or retry missing-file reads? | Those mask timing or size thresholds. They neither guarantee complete output nor repair a partial filename that never existed. Use the upstream drain fix. |
| Why not switch to `System.cmd/3`? | It would bypass process-lifecycle protection and violate the project's external-command rule. Retain MuonTrap. |
| Is the first clean dependency-upgrade run enough? | No. A repeat produced 34 publication failures. Runtime-instrumented and focused captures then passed, but that does not erase the residual. Add per-item artifact isolation to the fix and require repeated Linux workload tests before rollout. |
| Should narrowing the manifest replace the dependency update? | No. It removes repeated whole-checkout reads and command launches, but a final Git collection and other subprocess callers remain. Ship the dependency correction and narrowly scoped artifact isolation together, not a broad publication rewrite. |
| Could removing the inner reversal accidentally reverse the wrapper? | Keep the outer accumulator and opening/closing-tag order unchanged. Exact nested-template assertions and forced non-identity rendering cover the changed boundary. |
| Could structure checks be too strict? | They correctly reject malformed bold syntax introduced by our extractor. Keep them enabled; do not teach the model to compensate for malformed input. |
| Should every cached translation be invalidated? | A global purge is not justified. Only two templates changed in this corpus, but cache invalidation still needs an explicit old-template replay regression. Preserve unrelated work and seven-day checkpoints where valid; review completed glossary locales separately. |
| Would a dependency update introduce a cgroup migration? | Comparing rc.1 with 2.0.1 shows no changes to the cgroup module or option definitions; the major-version migration predates this delta. Existing transitive version overrides still need the normal dependency-resolution check. Babel already locks stable 2.0.0 and is not part of this incident's dependency fix. |
| Is dumping raw exception text an acceptable diagnostics fix? | No. Publication messages can contain absolute paths or command output, just as provider errors can contain secrets. Persist an allowlisted stage/code and reconstruct canonical messages at normalization boundaries. |
| Would more model retries fix either defect? | No. One is a local output-capture bug, the other is deterministic template corruption. Retrying model calls is wasted work. |

## Recommended implementation plan

### 1. Fix subprocess capture first

Suggested commit: `fix: upgrade muontrap to preserve complete subprocess output`.

- Change the application requirement to `~> 2.0.1`, retaining `override: true`.
- Update only MuonTrap's lock entry and any strictly required dependency changes, not the entire lockfile.
- Add a fast-output regression with byte-for-byte assertions, not merely exit-code or byte-count assertions. Cover stdout, captured stderr, nonzero exit, and timeout/child cleanup.
- Add a repository collector regression with a manifest larger than the old flow-control window and assert every expected path/content pair is present.
- Run these tests on Linux and macOS. Run existing sandbox/process lifecycle tests because the dependency is shared across other external-command paths.

Use the published fix for the confirmed rc.1 defect rather than vendoring a C patch. If the residual workload failure reproduces on a verified fixed binary, preserve a minimal reproduction and investigate it separately upstream; do not assume the original upstream fix covers it.

### 2. Isolate per-file publication artifacts

Suggested commit: `fix: collect only the current translation artifacts for publication`.

- Replace `completed_item_changes/2`'s whole-repository scan with explicit reads of the completed output and its lockfile, after both writes finish.
- Preserve the existing manifest format and test added and modified files against the existing GitHub tree builder, which upserts both. Do not change branch, commit, or PR behavior.
- Never read or publish another worker's in-progress output through this per-item path.
- Return structured artifact-read failures with a relative path and allowlisted filesystem reason instead of raising and scraping exception strings.
- Cover missing files, unrelated changes, large files, concurrent writers, batch thresholds, failed publication retention, and final flush.
- Keep the final general collector covered by exact-manifest assertions. The prototype still used it once and passed all four isolated-manifest runs, but it remains subprocess-dependent.
- Pre-register the Linux stress workload, number of captures, and acceptance criterion. Record the loaded version and port executable hash; compare captured bytes against an independently retained manifest as well as expected artifacts. Report per-capture integrity, not only per-run success. Any recurrence on a verified fixed binary blocks production recovery until explained.
- Test unchanged-content behavior, manifest status consumers, and the final collection against the union of completed items' artifact pairs. Preserve containment and regular-file guarantees when replacing the Git-derived manifest with direct reads.

This is a narrow change to artifact collection, not a replacement of the batching or GitHub publication architecture.

### 3. Fix nested Markdown template ordering

Suggested commit: `fix: preserve nested Markdown template order`.

- Remove the extra reversal at the nested inline-container boundary, preserving the existing wrapper accumulator.
- Assert exact templates for bold/emphasis/link containers with multiple text fragments, inline code, and deeper nesting.
- Exercise both a genuinely changed translation and an unchanged translation. Do not rely on the identity fast path alone.
- Add the two real glossary sentences as focused regressions and an engine test covering translated frontmatter plus multi-batch prose.
- Keep structural checks and preserved-token checks unchanged.
- Verify a corrected affected segment does not reuse its old checkpoint while unrelated segments still can.

### 4. Make publication failures identifiable without leaking data

Suggested commit: `fix: distinguish publication failures from translation failures`.

- Add an explicit publication failure classification rather than falling through to `translation-failed`.
- Preserve a bounded, allowlisted operation and cause code for manifest collection, artifact reads, and final batch publication. Prefer structured filesystem reasons to exception-message scraping.
- Reconstruct safe human-readable messages from those codes in `Failure.normalize/1`, progress events, persisted session metadata, and the dashboard.
- Say that translated output could not be published, rather than implying the source or model output was invalid.
- Do not treat publication errors as provider failures or route them through model retries.
- Ensure a simultaneous translation failure and final batch-flush failure does not silently discard the latter. The current `{{:error, reason}, _flush_result}` branch loses that information.
- Test serialization/normalization round trips and the exclusion of source text, tokens, command output, stack traces, and absolute temporary paths.

### 5. Separate follow-up hardening

Not a prerequisite for the incident fix:

- Consider a dedicated NUL-delimited Git status parser for filenames containing newlines, tabs, quotes, or non-ASCII bytes. This is a separate correctness concern, not a substitute for fixing truncated subprocess capture. A truncated stream can end on a valid record boundary even with NUL framing.
- Add bounded observability for checkpoint hits, failure stage, and actual effective model/provider. Planned `model: nil` currently makes otherwise useful logs misleading.

## Deployment and recovery gates

These are proposed actions, not actions taken during the investigation.

1. Run the focused tests, full relevant application suites, Linux image-level capture smoke test, and repeated fresh-checkout publication stress tests. Resolve any recurrence of the residual upgraded-workload failure before rollout.
2. Deploy the fixed release and verify its runtime dependency version and image digest. The inspected production image was built October 7; a new repository lockfile alone does not update it.
3. Verify newly scheduled translation Jobs inherit the corrected web image before continuing the affected project.
4. Continue the existing rolling translation PR through the supported session flow. Preserve its branch, valid output locks, and unexpired checkpoints; do not mark failed files complete manually or clear caches globally.
5. Confirm that publication failures no longer occur and that the remaining glossary units preserve source syntax. Inspect all glossary locales, including any that previously completed because a model happened to repair the malformed template.
6. Require every planned item to reach an appropriate terminal state and verify the GitHub branch contains the expected output/lockfile pairs. UI counters alone are not a publication-integrity check.

## Reproduction artifacts and limitations

Unpublished, ignored local artifacts live under `tmp/translation-investigation/`; they are not included in this draft or available to other contributors from a checkout. Sanitized reproducible fixtures and executable regressions must accompany the implementation:

- `probe_capture.exs`: subprocess output controls, old versus fixed MuonTrap.
- `probe_repository.exs`: actual repository orchestration with deterministic external seams; `INVESTIGATION_MUONTRAP_VERSION` selects the dependency and `INVESTIGATION_DIRECT_MANIFEST=1` selects the owned-artifact prototype.
- `probe_git_capture.exs`, `probe_git_concurrent.exs`: exact Git stdout comparisons against a complete reference manifest.
- `probe_markdown.exs`, `inspect_glossary.exs`: minimal Markdown failure and malformed units.
- `probe_corpus.exs`: identity/prefix/suffix structural tests across the corpus.
- `probe_template_changes.exs`: exact scope of changed templates.
- `probe_engine.exs`: actual engine with deterministic translation responses.
- Corresponding `*-before.log`, `*-after.log`, and repository probe logs.

The probes pin MDEx 0.13.1 and mdex_native 0.2.2 from the application's lockfile and run under Elixir 1.18.3 / OTP 27. They do not call a model or GitHub to generate translations. Only pure/synthetic probes have exercised the proposed changes; the full application `mix test` suite and a fixed-version Linux release have not yet been run. The historical error classifier irreversibly discarded the individual publication error strings, so the investigation establishes the reproduced mechanism rather than recovering those missing strings.

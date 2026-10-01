# Translation history & human-edit reconciliation

**Status:** baseline writer shipped (2026-10-01). Phase 1 is the next workable unit — see "Carried forward from the baseline writer" for known gaps and the coordination log for what landed.

**Goal:** Stop silently overwriting human edits to target-language files when Glossia re-translates. Use the record of those edits as context for future translations. Solve it for both structured formats (JSON/YAML/PO) and markdown prose.

**Origin:** design conversation between Pedro and Claude (Opus 4.7), reviewed by Codex (xhigh). The original sketch used per-line `git blame` as the primary gate; that foundation was replaced after review with a three-way merge over per-segment baselines. See "Design foundations" below for why.

---

## How to use this plan

- Phases are ordered by dependency. Do them in order. Every later phase assumes the earlier ones landed.
- Each phase has concrete deliverables as checkboxes. Check them off when the associated PR merges to `main`. Include the PR number after the checkbox: `- [x] X (#123)`.
- Open questions inside a phase must be resolved before that phase starts. Resolve them by editing the plan (record the decision + one-line rationale) and by opening a PR that implements the decision.
- "Cross-cutting" items apply throughout; do not treat them as a separate phase.
- Multiple sessions can work on this. Coordinate by owning a phase or a specific deliverable, and by editing this file in the same PR that lands the work.

---

## Design foundations

Read this before touching any code in the plan. The pitfalls here were caught by Codex reviews of the initial sketch and the baseline writer that already shipped; a fresh session that skips them will re-derive the wrong design.

**Baselines, not blame, are the source of truth.** Protection asks "did this content diverge from a known generated baseline?" not "who last touched this line?" Blame is corroborating evidence, never the gate. The baseline for a target segment is the source revision it was actually translated from — which is not the same as the source revision present when a human edited the target. In async translation, English can be at commit B while a Spanish speaker corrects a translation that still represents A; blaming against source-at-commit-time gets that case wrong.

**Baselines are per-segment, not per-file or per-run.** A translation run may update some segments and preserve others. The preserved segments still represent the older source revision they were translated from. Advancing their baseline just because the run completed makes unresolved drift disappear.

**Protection must survive bot re-authorship.** If Glossia reconciles a human-edited paragraph (preserving their term, updating a fact), the result is bot-authored. On the next run, a naive gate would happily overwrite it — human preference laundered into bot authorship. Protection ends only on explicit release, revert, or supersede, never because a bot rewrote the line.

**"Human-authored" is really "external or unknown."** A bot identity is useful, but everything else is not necessarily human intent. Formatter runs, mass renames, squash-merges that collapse bot + human commits, and other tools that write to target files all show up as "not-Glossia." Call the category what it is.

**Blame is weaker than the initial sketch claimed.** Squash-merges collapse authorship. Formatters make bots the last-author without changing translation, and vice versa. Deleted content has no blame at all. `git blame` follows renames automatically without `--follow` (that flag belongs to `git log`).

**Markdown needs correspondence, not just structure.** MDEx source positions locate segments but do not establish identity across revisions. Parse-then-render round-trips will rewrite formatting and destroy the very history we are protecting. Preserve untouched original bytes; parse only to locate what changed. Paragraph is a reasonable *protection unit*, but not an identity — splits, merges, and reorders need one-to-many / many-to-one lineage.

**Prior art worth stealing.** Gettext's `fuzzy` flag and Weblate's "needs editing" / "needs rewriting" states. When we preserve a stale translation because source drifted, call it what it is (needs review), do not dress it up as "reconciled."

**`source_commit_sha` is the RUN commit, not a per-segment baseline.** For file-level formats (JSON/YAML/markdown/text) the run commit and the per-segment baseline coincide — every segment in the file was processed in the same run. For PO, that is false: the engine preserves unchanged msgids and retranslates only changed ones, so some msgstrs in the on-disk file still represent an older source revision than the commit the current lock records. Phase 2 adds per-msgid provenance. Until then, consumers must treat `source_commit_sha` as "most-recent-run SHA" and never conclude that a PO file's every msgstr was translated from the SHA it records.

**Baseline target content is retrieved from git, not stored.** The lock holds `output_hash` and `source_commit_sha` — both pointers. The three-way merge recovers the baseline target content by looking it up in git history (walk the lock file's git log for the matching `output_hash`, or query the target branch at `source_commit_sha`). The lock stays small; the content stays in git where it already lives.

**`protection_state` values are a reserved vocabulary.** `recorded` means "freshly written translation with intact baseline provenance" — the baseline writer's default. `unknown_provenance` means "we cannot vouch for the baseline" — legacy locks, nil-SHA runs, corrupted locks. `active`, `released`, and `superseded` are reserved for Phase 2 protection semantics and must not be used earlier for a different meaning. The write path validates against this set; a typo like `"activated"` must raise, not silently become policy.

**Learning ≠ protection.** Every non-Glossia commit is an *edit observation with provenance and alignment confidence*, not a translation-memory row. Distinguish learning a translation (a broadly applicable pattern — "customer→member" as brand terminology) from learning a correction (a locale-specific content override — "we removed this promo because it doesn't apply in Spain"). Both deserve preservation; only one should influence unrelated wording. Recency alone is too weak a ranking rule.

---

## Global open decisions

Resolved 2026-09-30. Rationale kept short; expand in the coordination log if any decision is revisited.

- [x] **Sidecar location and format** — per-file JSON under `.glossia/baselines/<target path>.json`. The `.glossia/` directory already exists as our namespace; per-file avoids the merge-conflict hotspot a repo-wide file would create when multiple locales translate in parallel, and it makes garbage collection trivial (target deleted → sidecar deleted). A separate branch was rejected as hostile to reviewers.
- [x] **Legacy content policy** — backfill + flag. On first exposure, record current source + current target as baseline so the machinery works; where current target diverges from what Glossia would produce right now, mark `protection_state = unknown_provenance` so we don't silently bless bad legacy translations. One-time re-translation cost per repo is acceptable.
- [x] **Segment identity scheme for markdown** — sidecar-only IDs, no inline anchors. Glossia mints a short stable ID per segment at generation time, stored alongside `{structural_path, content_hash, source_segment_ids}`. Recovery uses structural path + content similarity; unresolved ambiguity is flagged, never silently overwritten. Inline HTML anchors rejected per Codex's critique of their lifecycle mess.
- [x] **Bot identity for Glossia commits** — both a dedicated git user (`glossia-bot@glossia.ai`) and a `Glossia-Bot: true` commit trailer. Small marginal write cost, meaningfully more robust to squash-merges and other identity-collapsing operations.
- [x] **Rollout scope** — per-project feature flag, dogfood first on Glossia's own marketing site and docs. Kill-switch remains available for later broadening. Design has subtle failure modes (bot laundering, wrong-baseline comparison, alignment ambiguity) that we want to see in controlled repos first.

---

## Carried forward from the baseline writer

The baseline writer shipped (see coordination log 2026-10-01). The following items are known-deferred and must be handled by the phases they belong to:

- **Per-msgid `protection_state` and per-msgid `source_commit_sha` for PO** → **Phase 2**. Without this, PO files with partial preservation record a run SHA that is wrong for the preserved msgstrs. See "Design foundations" for the full caveat.
- **Per-segment markdown identity, structural path, content hash, and source-to-target correspondence** → **Phase 3**.
- **Backfill/upgrade for legacy locks** → **Phase 2**. The baseline writer only touches locks that are being (re)written; unchanged locks stay at `schema_version: 0` with `protection_state: "unknown_provenance"` until Phase 2 either backfills them or waits for the next re-translation. Phase 1's "no-op skip" counter must not count a legacy lock as "baseline present."
- **Atomic lock writes (write-to-temp + rename)** → not a regression (`write_lock/4` has always written directly), but worth revisiting before any phase consumes baseline fields in a way that cares about partial writes.
- **End-to-end verification on a real customer repo** → pending a translation run against production content so a human can inspect the written sidecar.

---

## Phase 1 — Cheap wins from baselines

Purely mechanical uses of the new data. No LLM changes.

**Prerequisites:** baselines have been accumulating in production for at least a week on dogfooded projects (per the "Global open decisions" rollout scope).

- [ ] **No-op skip.** When both source and target match their baselines for a segment, skip the LLM call entirely. Ship as a translation-time optimization; report per-run counters (skipped / retranslated).
- [ ] **External-edit detection.** When source matches baseline but target diverges, emit an informational note in the PR ("N segments in this file have external edits since our last run") — no protection action yet.
- [ ] Metrics: how often does no-op skip fire, how often does external-edit detection fire, per project.
- [ ] Docs: short entry in `app/priv/docs/explanation/` describing baselines and what the PR notes mean.

---

## Phase 2 — Three-way merge protection for structured formats

The first phase that changes user-visible behavior. Structured formats only (JSON/YAML/PO). Markdown is deferred to Phase 3.

**Prerequisites:** Phase 1 complete; external-edit detection has been running long enough to have baseline data in real repos.

- [ ] Implement the four-case decision per segment for structured formats:
  - source == baseline, target == baseline → skip (Phase 1 already)
  - source == baseline, target != baseline → **preserve**, mark segment `protection_state = active` if not already (Phase 2's meaning of `active`: externally edited content whose protection has been activated — distinct from the pristine `recorded` state the baseline writer writes)
  - source != baseline, target == baseline → retranslate normally, advance baseline
  - source != baseline, target != baseline → **needs review**, preserve current target, do not advance baseline, surface in PR
- [ ] PR report renders per-file: retranslated, preserved (external edit), needs review (both changed). Each item links to the git commit(s) where the target diverged.
- [ ] `protection_state` transitions: `active` set on first divergence; released only via explicit sidecar edit (a human reviewer says "this is now the canonical translation, treat it as baseline going forward"). Ship the mechanism; the UI to trigger it can come later.
- [ ] Handle PO plurals: each plural form has its own baseline. `msgctxt` changes count as source-identity changes.
- [ ] Handle YAML anchors/aliases: baseline the resolved value, not the alias reference.
- [ ] Handle target-only additions (segment exists in target, no corresponding source): keep as-is, do not delete, note in PR.
- [ ] Handle source deletions colliding with local additions: preserve target segment, note in PR.
- [ ] End-to-end test on one real repo: intentionally introduce an external edit, run translation, verify preservation + PR note.

**Open questions specific to this phase:**
- [ ] What is the review affordance for a "needs review" PR — a checkbox in the PR body that a reviewer ticks, a comment command, or a separate follow-up PR that Glossia opens once the reviewer decides?
- [ ] How does `protection_state = released` propagate — does the reviewer edit the sidecar directly, or does Glossia expose an API/CLI action?

---

## Phase 3 — Markdown correspondence and protection

Structural work: extend Phase 2's semantics to markdown, where segment identity is harder.

**Prerequisites:** Phase 2 complete and in use on at least one real repo.

- [ ] Baseline writer for markdown records per-target-segment source correspondence (1:1, 1:many, many:1). Segment types initially covered: paragraphs, headings, top-level list items.
- [ ] Explicitly deferred segment types (Phase 3.5 or later): tables, code blocks, nested list items, blockquotes containing multiple blocks, inline HTML.
- [ ] Retranslation flow shifts from "whole-file retranslate" to "translate only source segments that changed, splice into the current target preserving untouched bytes." Byte-preserving splice mechanism.
- [ ] Alignment between old and new source segments: positional first, content-hash tie-breaker, embedding-based fallback for reordered docs. Ambiguity → unresolved mapping (never a plausible-but-wrong overwrite).
- [ ] Alignment across source and target sides: from recorded correspondence in the sidecar. Legacy content (no correspondence recorded) follows the legacy policy from Global open decisions.
- [ ] Same four-case decision as Phase 2, per segment.
- [ ] PR report shows a paragraph-level diff, not a file-level diff, for each preserved/needs-review item.

**Open questions specific to this phase:**
- [ ] Ordinality: when a source paragraph is split into two, does the target sidecar record `[source_id]` twice with a split index, or `[source_id_a, source_id_b]` with a merge? Both need representation; pick a canonical form.
- [ ] Frontmatter: is `title` in a markdown file's YAML frontmatter a structured segment (subject to Phase 2 rules) or a markdown segment (Phase 3)? Answer likely: structured.

---

## Phase 4 — LLM reconciliation for both-changed cases

The first phase that puts the LLM inside the decision loop.

**Prerequisites:** Phases 2 and 3 both in use, with real "needs review" data accumulating.

- [ ] Reconciliation prompt receives: old source, new source, generated baseline target, current (human-edited) target, commit message(s) associated with the divergence. Instruction is "carry the source change into the current target while retaining external changes wherever compatible," not "translate fresh."
- [ ] Output is a proposed target segment plus a rationale. Rendered in the PR alongside the preserved current target so a reviewer can accept, reject, or edit.
- [ ] Mechanical guardrails around the model output: placeholder preservation (`{{name}}`, `%{count}`, ICU MessageFormat), link/URL preservation, markdown structure preservation, number preservation. Fail closed if a guardrail trips (fall back to "preserve + needs review").
- [ ] Track acceptance rate per reconciliation as a quality signal.

**Open questions specific to this phase:**
- [ ] Reconciliation as a separate model call or as part of the main translation call? Separate is easier to iterate on; joint is fewer round-trips.
- [ ] Cost budget: reconciliations are potentially expensive with reasoning models. Cap per-run, per-repo, or per-file?

---

## Phase 5 — Context / TM learning from human edits

Consume the baseline + divergence history as retrieval context for future translations.

**Prerequisites:** Phase 4 complete; enough real human-edit history to make retrieval meaningful (weeks to months, per repo).

- [ ] Extract edit observations: `(old_source, generated_target, human_final_target, commit_message, commit_time, author, scope=locale/project/domain, alignment_confidence, review_status)`.
- [ ] Retrieval at translation time: for each segment being translated, find similar prior edit observations, weight by scope match + recency + review status (approved > merged > unreviewed), inject top-N into the prompt as few-shot with the commit message as the "why."
- [ ] Distinguish translation examples (terminology, tone, register) from locale content overrides (removed/added content that doesn't apply elsewhere). Only the former inform unrelated segments.
- [ ] Explicit scope isolation between customers and projects (no cross-contamination).
- [ ] Metrics: does retrieval-informed translation reduce the human-edit rate on subsequent runs? This is the ultimate quality signal for the whole effort.

**Open questions specific to this phase:**
- [ ] Storage: keep the retrieval index in Postgres, in a dedicated vector store, or derive on-the-fly from git + sidecars per translation run? On-the-fly is simpler but slow; index is faster but adds a system.
- [ ] Embedding model and re-embedding cost when the model changes.

---

## Cross-cutting concerns (apply throughout)

- [ ] **Bot laundering prevention.** Once a segment has `protection_state = active`, subsequent bot writes to it do NOT reset the state; only explicit release does. Reflected in every phase's write path.
- [ ] **In-flight runs.** Protection is evaluated against the target revision actually being written, not the revision read at job start. Race handling: if the target file changed between job start and job commit, re-evaluate before writing.
- [ ] **Human deletions.** Blame cannot see them. Detect by comparing current target to baseline target. A missing baseline segment is a signal, not a no-op.
- [ ] **Naming.** Do not call preserved-but-stale segments "reconciled." Use "needs review" (or gettext-style `fuzzy`). Codex's critique specifically flagged the naming.
- [ ] **Terminology in code.** Use "external or unknown edit" in code and PR text, not "human edit." Reserve "human" for cases we can actually attribute.
- [ ] **Docs.** Every phase that ships a user-visible behavior gets a short entry in `app/priv/docs/explanation/` explaining what the PR notes mean.
- [ ] **Prior-art references.** Gettext `fuzzy`, Weblate "needs editing" / "needs rewriting," Weblate translation memory scopes. Link where relevant in code comments and docs.

---

## Coordination log

Append short entries as sessions pick up work. Format: `YYYY-MM-DD — session-name — what changed`.

- 2026-09-30 — initial — plan drafted from design conversation + Codex xhigh review
- 2026-10-01 — Phase 0 — Locks extended with baseline fields; `defimpl FunWithFlags.Actor, for: Glossia.Accounts.Project` added; tests green (29). Adversarial Codex review surfaced 6 findings; 4 fixed in code (nil-SHA downgrades to `unknown_provenance`, `recorded` replaces `active` as the pristine default, `protection_state` is now a validated vocabulary, `baseline/1` tolerates corrupted/non-map input), 3 captured as design foundations and phase-specific caveats (PO per-msgid provenance deferred to Phase 2 with explicit limitation call-out, three-way merge retrieves baseline target from git via output_hash, legacy locks aren't auto-upgraded by Phase 0).

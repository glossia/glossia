---
name: glossia-cli-review
description: Project-specific PR-review rules for the Glossia CLI (Rust) under `cli/`. Focuses on what only this repo knows — the `GLOSSIA.md` context tree, provider-agnostic context hashing, headless translation flow, locks/runtime-config separation, and release automation.
---

# Glossia CLI Review

This skill is intentionally narrow. **Generic Rust style, formatting,
clippy lints, and naming are already covered by `cargo fmt` and
`cargo clippy` in CI — do not flag those.** Focus on the rules below;
they catch real bugs and convention breaks specific to the CLI.

For each finding, cite `path:line` (or `module::function`) and quote
the relevant snippet.

---

## 1. `GLOSSIA.md` context tree — inheritance and overrides

`GLOSSIA.md` is the public contract: frontmatter inherits from root → leaf,
deeper files override parent keys, markdown bodies concatenate as
translation context, and locale-specific context lives in
`GLOSSIA/<locale>.md`.

### Flag (Severity: high)

- A change to `cli/src/context.rs` or related modules that breaks
  child-overrides-parent semantics for frontmatter, or that stops
  concatenating markdown bodies on the way down the tree, without
  a corresponding test in `cli/tests/`.
- A new frontmatter key that is silently dropped during inheritance
  instead of merging like its peers (no allow-list entry, no test
  case demonstrating the merge).

### Do not flag

- Refactors that preserve the observable inheritance/override behavior
  and are covered by existing tests.

---

## 2. Context hashing — must stay provider-agnostic

`cli/src/hash.rs` produces stable hashes that decide whether a target
is up to date. The hash must be deterministic and independent of the
LLM provider; otherwise switching providers invalidates every cache
entry on disk.

### Flag (Severity: high)

- A change that mixes provider/model identifiers, API endpoints, or
  any runtime-configurable value from `glossia.toml` into the context
  hash input.
- A hash input that depends on map iteration order, HashMap default
  hasher state, current time, or filesystem mtimes — anything that
  isn't reproducible across machines.
- A new field added to the hash payload without a comment or test
  documenting why the field is part of the cache key.

### Do not flag

- Adding fields to the hash that are demonstrably part of the
  translation *input* (source bytes, target locale, prompt template
  version) with a test that pins the hash output.

---

## 3. Runtime config vs GLOSSIA.md split

`GLOSSIA.md` carries content/translation policy. `glossia.toml`
(handled by `cli/src/runtime_config/`) carries provider, auth, and
endpoint settings. `provider` in `GLOSSIA.md` is accepted only for
backwards compatibility; `glossia.toml` takes precedence at runtime.

### Flag (Severity: medium)

- A change that starts reading endpoint/auth values out of `GLOSSIA.md`
  at runtime instead of `glossia.toml`.
- A change that ignores `glossia.toml`'s `provider` when both files
  set one (the runtime file must win).
- A new public CLI flag that overlaps with `glossia.toml` settings
  without a clear precedence rule in the public docs.

---

## 4. Headless flow — no interactive prompts in non-`init` commands

`translate`, `check`, `status`, `clean`, and `revisit` must run
headlessly (CI-friendly). Only `init` is allowed to prompt
interactively.

### Flag (Severity: high)

- A new `print!`/`stdin` read / `dialoguer` prompt added to a command
  other than `init` without a `--no-input` style fallback.
- A new error path that *requires* tty interaction to recover.

### Do not flag

- Progress reporting / spinners (those flow through `cli/src/reporter.rs`
  and `cli/src/output.rs`, which already handle non-tty environments).

---

## 5. Locks — single writer, no global state leaks

`cli/src/locks.rs` coordinates concurrent runs. Writes to translation
output and lock files must go through it.

### Flag (Severity: high)

- A new code path that writes to a target translation file outside the
  lock-acquired critical section.
- A new test that mutates the lock directory without cleaning up in
  teardown.

---

## 6. Paths — use `cli/src/pathing.rs`, not ad-hoc joins

Path resolution (`source` → `target` templating, locale placeholder
substitution) is centralized.

### Flag (Severity: medium)

- A new module that re-implements `{locale}` placeholder substitution,
  source-pattern resolution, or root discovery instead of calling into
  `cli/src/pathing.rs` / `cli/src/root.rs`.
- A `PathBuf::from(format!("..."))` that concatenates a glob/template
  string when an existing pathing helper covers the case.

---

## 7. HTTP/LLM clients — go through `cli/src/llm.rs`

LLM calls are funneled through a single client module so retries,
timeouts, and provider quirks live in one place.

### Flag (Severity: medium)

- A new direct `reqwest`/`ureq` call into a provider API from outside
  `cli/src/llm.rs` (or its submodules under `cli/src/translate/`).
- A new dependency on a provider-specific SDK crate (`openai-rs`,
  `async-openai`, etc.) when the existing generic client could handle
  it via configuration.

### Flag (Severity: high)

- URL construction via string concatenation/interpolation on values
  that include user-controlled paths. Use `url::Url::join` or
  equivalent.

---

## 8. Tests — use `cli/tests/` for behavior, snapshot deliberately

### Flag (Severity: medium)

- A new behavior added to a command without an integration test in
  `cli/tests/` exercising it (parsing args, reading GLOSSIA.md, writing
  outputs).
- A new snapshot test (`insta`, `expect-test`) that captures a value
  including absolute paths, timestamps, or env-dependent strings
  without redaction.

### Do not flag

- Unit tests inline next to the module they cover, in addition to an
  integration test.

---

## 9. Release automation — conventional commits, `cliff.toml`

The CLI ships via git-cliff release notes and conventional commits.

### Flag (Severity: low)

- A user-facing change (new flag, behavior change, breaking format
  change) without a `feat:` / `fix:` / `BREAKING CHANGE:` conventional
  commit prefix — release notes group on these.
- A `Cargo.toml` version bump that doesn't go through the release flow
  implemented in `.github/workflows/release.yml`.

### Do not flag

- Internal refactors with `refactor:` / `chore:` prefixes — those are
  intentionally omitted from user-facing notes.

---

## 10. CI workflows — `.github/workflows/`

### Flag (Severity: medium)

- A workflow that builds the CLI without a release-artifact step
  matching the platforms published by `.github/workflows/release.yml`.
- Hard-coded secrets, tokens, or registry URLs in workflow YAML.

---

## Out of scope (handled elsewhere — do not flag)

- Rust style / naming / formatting → `cargo fmt` + `clippy`.
- Missing rustdoc on internal helpers.
- `unwrap()` in `cli/tests/` (test code; assertions are the point).

---

## Before submitting findings

For each finding, confirm:

1. The `path:line` is real and the snippet appears in the diff.
2. The category above is one of 1–10; if it isn't, downgrade to
   `uncertain: ...`.
3. Severity is set: **critical** (data corruption, cache poisoning),
   **high** (likely correctness bug), **medium** (convention gap),
   **low** (nice-to-have).
4. **The convention you are enforcing exists in the diff base.** If
   the rest of `cli/` doesn't follow the rule yet, the new code is
   consistent, not a regression. Downgrade to `uncertain: ...`.
   Correctness findings (rules 1, 2, 4, 5, 7) apply regardless of
   base-state.

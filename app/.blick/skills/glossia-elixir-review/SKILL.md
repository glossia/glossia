---
name: glossia-elixir-review
description: Project-specific PR-review rules for the Glossia Phoenix/Elixir app under `app/`. Focuses on what only this repo knows — the token-based design system, the `data-part` styling convention, the `LetMe.Policy` authorization model, NimblePublisher-backed docs, and Phoenix/Ecto conventions documented in AGENTS.md.
---

# Glossia Elixir Review

This skill is intentionally narrow. **Generic Elixir style, naming, pipe
chains, formatting, and nesting depth are already covered by
`mix format` and `credo` in CI — do not flag those.** Focus on the rules
below; they catch real bugs and convention breaks that humans care
about.

For each finding, cite `path:line` (or `Module.function/arity`) and
quote the relevant snippet.

---

## 1. Styling — `data-part` attributes + id selectors, never BEM/utility classes

Glossia uses a token-based design system (see `app/AGENTS.md` Design
system section). Components are styled via `data-part` attributes and
id selectors against `app/priv/static/assets/styles.css`. BEM-style
class chains and utility classes are not the project's convention.

### Flag (Severity: medium)

- A new HEEx template that uses BEM-style classes (e.g. `class="card__header--large"`)
  for layout/component styling instead of `<div id="card" data-part="header">`
  or analogous id+data-part composition.
- A new CSS rule that selects on BEM `.block__element--modifier` for a
  project component instead of `#component[data-part="..."]` selectors
  drawing from existing semantic tokens.
- Raw color / spacing / radius values in CSS where a token exists
  (`#1c1917` instead of `var(--color-stone-900)`, `16px` instead of
  `var(--space-3)`). The token system has three tiers (primitive →
  semantic → component); prefer the highest applicable tier.
- Duplicating a `border + radius + padding + shadow` recipe in two
  places instead of extracting a shared molecule (e.g. `.card`).

### Do not flag

- Existing template style unchanged by the diff.
- Inline conditional class lists like `class={[...]}` for utility
  toggles where the component is otherwise styled via tokens/data-part.

---

## 2. Internal paths — always the `~p` sigil

Phoenix verified routes via the `~p` sigil are required for all
internal URLs/paths in templates, redirects, and tests.

### Flag (Severity: medium)

- A new template, controller, LiveView, or test that constructs an
  internal path with string concatenation or interpolation
  (`"/accounts/#{slug}"`, `"/docs/" <> category <> "/" <> slug`) instead
  of `~p"/accounts/#{slug}"` / `~p"/docs/#{category}/#{slug}"`.
- A `push_navigate(socket, to: "...")` or `redirect(conn, to: "...")`
  whose target is a hard-coded string instead of `~p"..."`.

### Do not flag

- External URLs (`https://...`).
- Paths constructed inside helper modules that explicitly assemble
  query strings or fragments from validated maps.

---

## 3. API authorization — shared account-resolution plug, not nested case statements

API controllers under `GlossiaWeb.Api.*` must reach account state
through the shared `GlossiaWeb.ApiAuthorization` plug (or equivalent
declarative pipeline). Nested `case` statements that re-derive account
context and authorization on each action are a regression.

### Flag (Severity: high)

- A new API controller action that pattern-matches the account out of
  params and runs its own `case Accounts.get_account(...)` /
  `case Policy.authorize(...)` chains, when sibling controllers use
  the shared plug.
- A new API route added without a plug-level authorization step
  (account resolution + Policy check) in `router.ex`.

### Do not flag

- Controllers that already use the shared plug; changes inside their
  handlers don't need to re-do authorization.

---

## 4. Authorization — `Glossia.Policy` (`LetMe.Policy`)

The policy DSL is `LetMe.Policy`, declared in `app/lib/glossia/policy.ex`.
Categories are declared via `object :foo do ... end` blocks and each
action allows a list of checks (`allow(:authenticated)`,
`allow(:super_admin)`, `allow(:organization_admin)`, etc.).

### Flag

- **A new `action` that uses `allow(true)`** — existing actions
  uniformly require an authenticated/role-based check. Re-introducing
  anonymous access (especially on a write category like `:write`,
  `:create`, `:delete`) is almost certainly a regression. **Severity: critical.**
- **A new `object` declared in the policy without any `action` blocks**,
  or `action` blocks with no `allow(...)` lines. Default is deny, so
  this is usually a copy-paste bug. **Severity: medium.**
- **A controller / LiveView that performs a write but is reached
  through a route in the unauthenticated `:browser` pipeline** (no
  `:require_auth` or equivalent on_mount). **Severity: high.**
- A new write that bypasses `Glossia.Policy.authorize/3` when sibling
  writes in the same context module call it. **Severity: high.**

### Do not flag

- Existing `object` / `action` blocks unchanged by the diff.
- Read paths on tables that have no authorization model yet — only
  flag if the PR introduces the first Policy usage for that area.

---

## 5. Module organization — flat namespaces in libs, no `XxxComponents` wrappers

Glossia uses flat module namespaces for shared libraries. The root
module IS the API; don't introduce wrapper namespaces like
`Glossia.Foo.FooComponents.Button` when `Glossia.Foo.Button` suffices.

### Flag (Severity: medium)

- A new module placed under a redundant `*Components` / `*Utilities` /
  `*Helpers` wrapper namespace where the parent context module would
  serve as the public API.
- A web context module split into many sub-namespaces when sibling
  contexts in `app/lib/glossia/` keep a flat shape (one `context.ex`
  facade + a `context/` directory of internals).

### Do not flag

- `GlossiaWeb.*` separation from `Glossia.*` — that's the standard
  Phoenix split, not a wrapper.
- Existing module layout unchanged by the diff.

---

## 6. Documentation — NimblePublisher front matter + Diataxis categories

Docs live in `app/priv/docs/` and are served via NimblePublisher under
`/docs`. Each file follows the Diataxis taxonomy (tutorials, how-to,
reference, explanation) and ships with Elixir-map front matter
(`title`, `summary`, `category`, `order`).

### Flag (Severity: medium)

- A new docs page in `app/priv/docs/<category>/<slug>.md` missing one
  of the required front-matter fields (`title`, `summary`, `category`,
  `order`).
- A `category:` value that is not one of `tutorials`, `how-to`,
  `reference`, `explanation`.
- A docs page that mixes Diataxis modes (e.g. a "reference" page that
  contains a step-by-step tutorial walkthrough).

### Do not flag

- Existing pages unchanged by the diff.
- Front-matter wording / phrasing — that's an editorial concern.

---

## 7. Seeds — keep `seeds.exs` realistic and idempotent

`app/priv/repo/seeds.exs` should stay representative: when a PR
introduces a new domain feature (schema/context/API surface) without
extending seeds, exercising the feature locally becomes harder.

### Flag (Severity: low)

- A PR that adds a new schema or context module under
  `app/lib/glossia/` *without* updating `seeds.exs` to insert
  representative records (especially for: accounts public + access-gated,
  organization memberships, invitations, projects, voices/versions).
- A change to `seeds.exs` that breaks idempotency (no `on_conflict`
  guard, no `Repo.get_by` check) so re-running the seeds raises.

### Do not flag

- Bug fixes or refactors that don't touch the surface area `seeds.exs`
  covers.

---

## 8. HTTP client — `Req` only

Per `AGENTS.md`-adjacent conventions, the project uses `Req` for HTTP.
`:httpoison`, `:tesla`, and `:httpc` are not used.

### Flag (Severity: high)

- A new dependency on `:httpoison`, `:tesla`, or `:httpc` in
  `app/mix.exs`.
- A new call to `HTTPoison.*`, `Tesla.*`, or `:httpc.*` from
  application code. Suggest `Req.get/2`, `Req.post/2`, etc.

### Flag (Severity: medium)

- URL/path construction via string concatenation or interpolation
  (e.g., `"#{base_url}/#{path}"`). Require `URI` utilities
  (`URI.append_path/2`, `URI.to_string/1`) for proper encoding.

---

## 9. Migrations — naming + timestamp convention

In `app/priv/repo/migrations/`:

### Flag (Severity: low)

- A new migration whose timestamp prefix doesn't match
  `YYYYMMDDHHMMSS_*.exs` (almost certainly hand-named instead of
  generated via `mix ecto.gen.migration`).

### Do not flag

- **Migration timestamp column types.** Match the convention already
  used by sibling migrations; never suggest switching `timestamps()`
  to `timestamps(type: :utc_datetime_usec)` (or vice versa) just for
  the sake of it — consistency with the existing migrations matters
  more than the type choice.

---

## 10. Phoenix LiveView — forms + ecto preloads

### Flag (Severity: medium)

- A LiveView template that accesses changeset fields directly
  (`<.form for={@changeset}>` or `@changeset[:field]`). Forms must be
  built via `to_form/2` in the LiveView and accessed as `@form[:field]`.
- A `<.form>` without a unique DOM `id`.
- A template that accesses `record.assoc.field` without the query
  preloading `:assoc` — raises `Ecto.Association.NotLoaded` at render.

### Flag (Severity: high)

- Map-access syntax (`record[:field]`) on a struct that is not an
  `Ecto.Changeset`. Regular schema structs don't implement `Access`
  and this raises at runtime.

---

## 11. Mass assignment — programmatic FKs out of `cast/2`

Tenant / programmatic foreign keys (`account_id`, `user_id`,
`organization_id`, etc.) must be set explicitly on the struct, not
cast from user params.

### Flag (Severity: high)

- A changeset's `cast/2` allowed-fields list includes a
  tenant/programmatic FK that should be assigned server-side.

### Do not flag

- Top-level resources where the FK *is* the resource being created.
- Genuinely user-selectable FKs (e.g. a dropdown that picks a parent
  category).

---

## 12. Dynamic atoms — allow-list runtime strings

Creating atoms from runtime strings is a real risk because the app
parses provider keys, config values, webhook payloads, and LLM
outputs.

### Flag (Severity: high)

- `String.to_atom/1`, `:erlang.binary_to_atom/2`, or similar atom
  creation on values from params, env vars, application config, files,
  external APIs, webhook payloads, MCP inputs, or LLM output.

### Flag (Severity: medium)

- `String.to_existing_atom/1` on dynamic input without a `try/rescue`
  or explicit allow-list.

### Do not flag

- Explicit string→atom maps (`%{"openai" => :openai}`) or case
  expressions over known literals.

---

## 13. Tests — async by default, no global mutation

### Flag (Severity: medium)

- A new test module using `async: false` without a concrete reason.
- New tests that mutate application-wide state
  (`Application.put_env/3`, globally stubbed modules, shared registry
  names, global Oban testing mode) without restoring it.
- Test files that define extra top-level helper modules at the bottom
  of `*_test.exs` and pass them as callback implementations
  (classifiers, providers, agents, etc.). Put them in
  `app/test/support/...` as one-module-per-file helpers instead.

### Do not flag

- Existing async-false modules unchanged by the diff.
- Tiny local helper functions or test data that aren't passed as
  module-callback implementations.

---

## Out of scope (handled elsewhere — do not flag)

- Module / function naming, pipe-chain start, function ordering,
  parentheses-on-no-arg-calls → `mix format` + `credo`.
- Missing `@spec` / `@type` / `@doc` / `@moduledoc` on internal helpers
  unless Credo asks for them.
- `if/elsif/else if` — Elixir syntax errors, not review nits.

---

## Before submitting findings

For each finding, confirm:

1. The `path:line` is real and the snippet appears in the diff.
2. The category above is one of 1–13; if it isn't, downgrade to
   `uncertain: ...` rather than asserting a finding.
3. Severity is set: **critical** (auth bypass, anonymous writes),
   **high** (likely security/correctness bug), **medium**
   (convention/consistency gap), **low** (nice-to-have).
4. **The convention you are enforcing exists in the diff base.** If
   the rest of the codebase is consistent with the "violation" (no
   sibling controller uses the shared plug, no other module uses
   `~p`, etc.), the new code is consistent, not regressing.
   Downgrade to `uncertain: ...` or omit. Security and correctness
   findings (rules 3, 4, 8, 11, 12) apply regardless of base-state.

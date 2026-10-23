# AGENTS

## Commit and PR conventions

- Use Conventional Commits for both commit messages and PR titles (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, etc.).
- This keeps git-cliff release notes accurate and grouped correctly.

## Running shell processes from Elixir

- Always run external commands with `MuonTrap.cmd/3` (the `:muontrap` dependency), not `System.cmd/3`.
- MuonTrap supervises the OS process and kills it if the BEAM dies, so we never leak child processes (git clones, validation scripts, sandbox tooling).
- It is a drop-in replacement returning `{output, exit_status}`; pass `into: ""` for string output and a `timeout:` for anything that runs untrusted or long-running commands, matching the existing calls in `Glossia.Sandbox.Runner`.

## Elixir module directives

- Declare `alias`, `import`, and `require` only at module scope. Never place them inside function implementations.

## Caching

- Use [Cachex](https://hexdocs.pm/cachex) for in-memory caches. Do not hand-roll a GenServer that owns a public ETS table: those consistently ship without expiry reclamation (an entry read as expired still occupies the table forever), without a size bound, and without protection against concurrent misses stampeding the same expensive resolver. Cachex gives all three via `expiration(default: ...)`, a `Cachex.Limit.Scheduled` hook, and `Cachex.fetch/3`.
- Reach for `Cachex.fetch/3` rather than a read-check-write triple whenever the miss path is expensive (a network call, a heavy query). Its courier collapses concurrent misses for the same key into one resolver invocation. Return `{:ignore, value}` from the resolver for failures so a transient error is not cached for the whole TTL.
- Bound any cache whose key space is user- or attacker-influenced (client IPs, arbitrary hostnames) with a size limit hook. TTL alone does not bound a cache that keeps seeing new keys.
- Nebulex is **not** an alternative here. It is a cache abstraction (adapters, decorators, distributed topologies) rather than a cache, it only reaches us transitively through `boruta`, and `nebulex_adapters_cachex` 3.x requires Nebulex 3, which drops the `Nebulex.Adapters.Replicated` module that `Boruta.Cache` starts. Overriding the version resolves but breaks OAuth at boot.

### Cachex instances in tests

- Cache modules must accept a `:name` in `child_spec/1` and expose their public functions with an optional cache argument defaulting to the application-wide instance. See `Glossia.Analytics.SettingsCache`.
- Tests that exercise a cache module should `start_supervised!({TheCache, name: :"test_cache_#{:erlang.unique_integer([:positive])}"})` and pass that name in, so each test owns its own instance and the file stays `async: true`. Do not reach for `Cachex.clear/1` on the global instance and `async: false` — that serializes the suite and leaks state between tests.
- One caveat worth knowing: `Cachex.fetch/3` runs the resolver in a process the courier `spawn_link`s, which does not inherit `$callers`. Mimic stubs therefore do not reach it, and a test that both goes through `fetch/3` and stubs a module needs `set_mimic_global` (and so `async: false`). Prefer injecting the resolver directly in those tests; only fall back to global Mimic when the code under test owns the resolver.

## Routes and links

- Always use the `~p` sigil for paths and the `~pH` variant for HTTPS URLs. It gives us compile-time verification that the route exists, the right number of path segments, and the right types of dynamic segments. Examples:
  - `navigate={~p"/#{@handle}/-/members"}`
  - `href={~p"/projects/new"}`
  - `<.link patch={~p"/#{@handle}/#{@project}/-/translations?#{params}"}>`
  - `redirect(conn, external: ~pH"https://github.com/#{@org}/#{@repo}")`
- Never build paths with string concatenation, `String.replace`, or `Phoenix.VerifiedRoutes.unverified_url/1`. The whole point of `~p` is to fail at compile time when a route is wrong.

### URL and path manipulation

- Parse, modify, and build URLs and paths with the `URI` module, never with `String` surgery. `URI.parse/1`, `URI.to_string/1`, and `URI.merge/2` handle query strings, fragments, escaping, and scheme/host detection correctly; splitting on `"?"`, concatenating `"#"`, or checking `String.starts_with?(path, "//")` all get those cases wrong.
- Turning a path into an absolute URL is `base_url |> URI.merge(path) |> URI.to_string()`.
- Validating a user-supplied redirect target is a `URI.parse/1` plus a match on `%URI{scheme: nil, host: nil, path: "/" <> _}`, which is what keeps an open redirect out.

### Localized marketing links

The public marketing site is served once per locale: English unprefixed (`/blog`) and every translated locale behind a literal prefix (`/es/blog`, `/zh-hans/docs/...`, see `GlossiaWeb.MarketingRoutes`). Marketing links therefore wrap `~p` in `locale_path/1`, which prefixes the verified path with the locale of the current request:

- `href={locale_path(~p"/blog")}` renders `/blog` in English and `/es/blog` in Spanish.
- The route itself is still verified at compile time; only the prefix is added at runtime, from `Glossia.I18n`.
- Do **not** use `locale_path/1` for dashboard, auth, or API routes. Those exist at a single URL, and prefixing them produces a 404.


## Type annotations

- Do not write `@type` or `@spec` module attributes. Types are conveyed through `@moduledoc`, function names, the function signatures themselves, and the tests. `@type` / `@spec` add maintenance overhead (they drift, they are not enforced at runtime, and Elixir's tooling is stronger for code-as-documentation) without buying us anything the editor cannot infer.
- A custom Credo check (`Glossia.CredoChecks.NoTypeAnnotations`, ID `GL3001`) flags `@type` and `@spec` in `app/lib` and `app/test`. Run `mix credo` locally to see violations; do not introduce new ones.
- Typespecs on public APIs of third-party dependencies (e.g. behaviours we implement) are out of scope for this rule.

## Web analytics installation

- External installation snippets use `https://glossia.ai/assets/glossia-web.js`; the tracker derives `https://glossia.ai/v1/collect` from that origin. Keep the dashboard snippet, English setup guide, and `sdk/web` examples aligned. Cross-origin collection must use credential-free keepalive fetch; JSON beacons include credentials and cannot use the public collector's wildcard origin response.

## Documentation

Documentation lives in `app/priv/docs/` and is served at `/docs` using NimblePublisher (same pattern as the blog). It follows the [Diataxis framework](https://diataxis.fr/) to organize content into four categories:

### Diataxis categories

| Category | Purpose | Path prefix | Description |
|---|---|---|---|
| **Tutorials** | Learning-oriented | `tutorials/` | Step-by-step lessons that guide the reader through completing a task for the first time. They teach by doing. |
| **How-to guides** | Task-oriented | `how-to/` | Practical directions for accomplishing a specific goal. They assume the reader already knows what they want to do. |
| **Reference** | Information-oriented | `reference/` | Technical descriptions of the system (config fields, CLI flags, file formats). Accurate, complete, and terse. |
| **Explanation** | Understanding-oriented | `explanation/` | Discussions that clarify concepts, decisions, and design rationale. They help the reader build a mental model. |

### File format

Each doc page is a markdown file in `app/priv/docs/<category>/<slug>.md` with Elixir map front matter:

```elixir
%{
  title: "Getting started",
  summary: "Set up Glossia in your project in five minutes.",
  category: "tutorials",
  order: 1
}
---

Markdown content here...
```

### Front matter fields

- `title` (required): page title displayed in the sidebar and heading.
- `summary` (required): one-line description shown on the docs index page.
- `category` (required): one of `tutorials`, `how-to`, `reference`, `explanation`.
- `order` (required): integer that controls sort order within its category.
- `section` (optional): sidebar group within the category. One of `translation`, `platform`, or `analytics` (defined in `Glossia.Docs`). Pages without a section are listed first, without a heading. Translated pages always inherit the English page's section.

### Layout

The docs section uses a sidebar + content layout inspired by Micelio's documentation:

- **Index page** (`/docs`): lists all four Diataxis categories as cards with descriptions.
- **Doc page** (`/docs/:category/:slug`): sidebar with navigation on the left, content on the right, breadcrumbs above the content.

### Writing guidelines

- Keep pages focused on a single topic.
- Use concrete examples and real command output when possible.
- Tutorials should be completable from start to finish.
- Reference pages should be exhaustive and machine-parseable where possible.
- Do not mix Diataxis categories within a single page (e.g., do not put a tutorial inside a reference page).

## Design system

The UI across all surfaces (homepage, blog, docs, legal pages) must be visually consistent. We follow a token-based design system inspired by the [Theme UI / System UI specification](https://theme-ui.com/theme-spec) and [Atomic Design](https://atomicdesign.bradfrost.com/chapter-2/). All styles live in `app/priv/static/assets/styles.css`.

### Noora components only

The `noora` dep (pinned in `mix.exs`) is the source of truth for UI components — `<.card>`, `<.card_section>`, `<.table>`, `<.tag>`, `<.widget>`, `<.dropdown>`, `<.button>`, `<.text_input>`, `<.badge>`, `<.tooltip>`, etc. Use them. Do not introduce bespoke CSS classes, custom `<div>` widgets, or hand-rolled markup when a Noora component does the same job.

Reference: the Tuist server pages under `~/.codex/worktrees/*/server/lib/tuist_web/live/*_live.ex` and the matching `*.html.heex` files are the canonical examples of how to compose Noora components into full page layouts. Before introducing a new pattern, check there for the existing convention (card with `<:actions>` slot, widget grid inside a card section, dropdowns in the card header, etc.). The `use Noora` directive at the top of a LiveView module is what brings these components into scope.

If a need is not covered by Noora, add a new component to `noora` upstream rather than maintaining a parallel one in `glossia_web`. The token system (`--noora-spacing-*`, `--noora-surface-*`, `--noora-chart-*`, etc.) is consumed automatically through Noora's CSS — there is no Glossia-specific design-system layer above it.

### Data tables

Every data table follows the established Tuist table pattern: a debounced search field, the Noora filter dropdown, active-filter controls, and sortable column headers. Keep search, filter, sort column, and sort direction in the URL so a table view is shareable and survives navigation. Use `<.table>` column `patch` and `sort_order` attributes for sorting rather than bespoke header controls.

### Empty states

- Follow Tuist's empty-state pattern: use `<Noora.Table.table_empty_state>` with an `icon`, `title`, and contextual `subtitle`. Put it in the table's `<:empty_state>` slot instead of leaving only column headers or rendering a bare message.
- Keep resource cards visible when empty. Explain whether results are still pending, everything is already up to date, or the session finished without output. Replace the empty state when data arrives.
- **Noora 0.86 scopes empty-state styles to a `.noora-table` ancestor.** Outside a table (for example, an empty activity card), apply that styling scope to the containing `<Noora.Card.card_section>` only while empty. Preserve the card's background with a route-scoped override using `--noora-surface-background-primary`; the table scope otherwise gives it a table-header background. See `session_detail_page/1` and `app/assets/css/routes/translation-session.css`.
- Verify empty states in a real browser, including screenshots. Markup assertions alone do not catch missing CSS scope: check centered layout, icon treatment, typography, and background, as well as the transition to populated content.

### Three-tier token architecture

Tokens are CSS custom properties defined in `:root`. They are organized in three tiers:

1. **Primitive tokens** - raw palette values with no semantic meaning. Named by what they are.
   - `--color-pink-500`, `--color-gray-900`, `--space-4`, `--font-size-2`
2. **Semantic tokens** - reference primitives and carry meaning. Named by what they do.
   - `--color-text`, `--color-background`, `--color-primary`, `--color-border`, `--shadow-default`
3. **Component tokens** (optional) - override semantic tokens for specific components.
   - `--button-bg`, `--card-radius`, `--sidebar-width`

When adding or changing tokens, always prefer semantic tokens over raw values. Only introduce component tokens when a component genuinely needs to diverge from the semantic defaults.

### Token categories

Follow the System UI spec categories. Every CSS property that accepts a design decision should draw from a token:

| Category | Token prefix | Examples |
|---|---|---|
| Colors | `--color-*` | `--color-text`, `--color-background`, `--color-primary`, `--color-accent`, `--color-muted` |
| Typography | `--font-*`, `--text-*` | `--font-body`, `--font-mono`, `--text-sm`, `--text-base`, `--text-lg` |
| Spacing | `--space-*` | `--space-1` (4px), `--space-2` (8px), `--space-3` (16px), `--space-4` (32px) |
| Radii | `--radius-*` | `--radius-sm`, `--radius`, `--radius-lg`, `--radius-full` |
| Shadows | `--shadow-*` | `--shadow-sm`, `--shadow`, `--shadow-lg` |
| Borders | `--border-*` | `--border`, `--border-strong` |
| Transitions | `--transition-*` | `--transition` |
| Z-index | `--z-*` | `--z-sticky`, `--z-dropdown`, `--z-modal` |
| Breakpoints | media queries | `768px`, `960px` (not tokenizable in CSS, but keep consistent) |

### Atoms, molecules, and components

We borrow from Atomic Design to keep the stylesheet composable:

**Atoms** - the smallest visual elements. Each atom draws all its styles from tokens.
- `.button` (primary, secondary variants)
- `.badge`
- `.tag`
- Headings (`h1`-`h4` within `.prose`)
- Inline `code`
- Links

**Molecules** - small groups of atoms that form a functional unit.
- `.card` - surface with border, radius, padding, and hover shadow. Used for blog cards, doc page cards, feature cards, tool cards, FAQ items, and category cards. All cards must use the same base molecule.
- `.step` - number + heading + description (how-it-works section)
- `.breadcrumbs` - navigation chain with separators
- `.sidebar-section` - heading + link list

**Components** - composed of molecules and atoms, forming distinct page sections.
- `.hero` - page hero with heading, lead text, and optional CTA
- `.docs-layout` - sidebar + content grid
- `.feature-grid` - grid of feature cards
- `.prose` - long-form rendered markdown content

### Rules

1. **Never use raw color, spacing, or radius values.** Always reference a token. If the right token does not exist, add it to `:root` first.
2. **Extract shared patterns into molecules.** If the same combination of border + radius + padding + shadow appears in more than one place, it should be a shared class.
3. **Use semantic color names**, not presentational ones. `--color-primary` not `--color-pink`. `--color-muted` not `--color-gray`.
4. **Keep the spacing scale constrained.** Use a base-4 scale: 0, 4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px. Do not invent arbitrary spacing values.
5. **Typography must use the scale.** Define `--text-xs`, `--text-sm`, `--text-base`, `--text-lg`, `--text-xl`, `--text-2xl` and use them everywhere instead of raw `font-size` values.
6. **Variants over new classes.** When a component needs visual variations (e.g., primary/secondary buttons), use data attributes or modifier classes on the same base class rather than creating unrelated class names.
7. **Consistency across surfaces.** A card on the homepage must look and behave the same as a card on the docs page or blog index. If they differ, it should be through an intentional variant, not accidental divergence.
8. **Responsive design uses the same breakpoints everywhere.** Currently: mobile (< 768px), tablet (768px-960px), desktop (> 960px). Do not introduce new breakpoints without good reason.

### CSS file structure

- `app/assets/css/noora.css` is a thin manifest: it imports tokens plus one file per route and shared component. It must not accumulate component styles inline.
- Every route and shared component owns its own `#id` and a matching CSS file, and the directory hierarchy mirrors routes and components: shared components under `components/` (e.g. `components/translation-progress.css` for `#translation-progress`), route-specific styles under `routes/`.
- Scope each file to its `#id` and use native nested CSS (`& [data-part="..."]`, `&[data-status="..."]`) rather than repeating the id selector. esbuild bundles the `@import`s and preserves nesting.
- Because each block is scoped to a unique `#id`, import order does not affect the cascade.

### Current state and migration

The current CSS defines a token system in `:root` and shared UI molecules (like `.card`). Some gaps remain:

- `noora.css` still holds most existing styles inline; migrate them into per-route/component files under `components/`/`routes/` incrementally as you touch each surface.
- Some dashboard/utility "card" surfaces still use bespoke classes instead of `.card` + variants. Migrate incrementally.
- Some hardcoded pixel values remain for icons and decorative elements. Prefer tokens when possible.

When touching styles, incrementally fix these gaps. Do not attempt a full rewrite in one pass.

## Seeds

- `app/priv/repo/seeds.exs` must stay **realistic and up to date**. When adding a new domain feature (schema/context/API surface), extend seeds with representative data so developers and agents can exercise it end-to-end.
- Keep seeds idempotent (safe to run multiple times) and include data that covers: public accounts, organization memberships, invitations, projects, and voice/version history.

## Repository layout

Everything lives in a single repository:

- `app/` — the Elixir/Phoenix application. Includes the FLAME-managed runner
  pool, detached translation Job launcher, project-setup harness, and
  Kata-scheduled sandbox under `app/lib/glossia_enterprise/`. These modules
  are wired into the runner/launcher/project-setup seams
  (`config :glossia, :runners, module: ...` etc.) at compile time; dev and
  test revert them to the in-process defaults.
- `babel/` — the internal operations platform (Phoenix app deployed at
  `babel.glossia.ai`). Its own chart at `babel/chart/`, CI in
  `.github/workflows/babel.yml`, image published as
  `ghcr.io/glossia/babel`.
- `cli/` — the Rust CLI. Cross-compiled and released from
  `.github/workflows/release.yml`.
- `sdk/` — the JS SDK. Released from `.github/workflows/release-sdk.yml`.
- `deploy/helm/glossia/` — the Glossia app Helm chart. Deployed to
  production by Flux from this same repository.
- `infra/` — Kubernetes / Flux / Helm manifests for the mgmt cluster and
  workload clusters, plus the `cloudflare-operator` Go controller.

## Continuous deployment

Every push to `main` builds and publishes the production Docker image via
`.github/workflows/deploy.yml`, tagging `ghcr.io/glossia/glossia:main` and
the SHA. Flux, running in the mgmt cluster, watches that tag through the
`ImageRepository`/`ImagePolicy`/`ImageUpdateAutomation` triple under
`infra/k8s/mgmt/flux/glossia-image-automation.yaml`; a new SHA is committed
back to `infra/k8s/workload-apps/glossia-production/glossia-helmrelease.yaml`
and the HelmRelease reconciles the workload cluster.

There is no downstream wrapper repository, no enterprise/OSS split, and no
bump-PR indirection. A merge to `main` lands in production after one CI
build plus one Flux tick.


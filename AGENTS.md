# AGENTS

## Commit and PR conventions

- Use Conventional Commits for both commit messages and PR titles (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, etc.).
- This keeps git-cliff release notes accurate and grouped correctly.

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

### Current state and migration

The current CSS defines a token system in `:root` and shared UI molecules (like `.card`). Some gaps remain:

- Some dashboard/utility "card" surfaces still use bespoke classes instead of `.card` + variants. Migrate incrementally.
- Some hardcoded pixel values remain for icons and decorative elements. Prefer tokens when possible.

When touching styles, incrementally fix these gaps. Do not attempt a full rewrite in one pass.

## Seeds

- `app/priv/repo/seeds.exs` must stay **realistic and up to date**. When adding a new domain feature (schema/context/API surface), extend seeds with representative data so developers and agents can exercise it end-to-end.
- Keep seeds idempotent (safe to run multiple times) and include data that covers: public accounts, access-gated accounts (`has_access: false`), organization memberships, invitations, projects, and voice/version history.

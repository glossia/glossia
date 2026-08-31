# Babel application guidelines

## Commit and pull request conventions

- Use Conventional Commits for commit messages and pull request titles (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, and similar).
- Run `mix precommit` before handing off a complete change and fix all reported issues.

## Elixir

- Declare `alias`, `import`, and `require` only at module scope. Never declare them inside a function.
- Do not write `@type` or `@spec` module attributes. Keep intent clear through module documentation, function names, signatures, and tests.
- Use `MuonTrap.cmd/3` for external commands. It ensures child operating-system processes are supervised and shut down correctly.
- Use `Req` for Hypertext Transfer Protocol requests. Do not add another client without a specific reason.
- Do not use `String.to_atom/1` with user input.
- Predicate function names should end in `?`; reserve `is_` prefixes for guards.
- Give `DynamicSupervisor` and `Registry` processes a name in their child specification.
- Use `Task.async_stream/3` for concurrent collection processing, with back-pressure and an explicit timeout.
- Use `Briefly` for temporary files and directories in non-test code. In tests, use ExUnit's `@tag :tmp_dir` instead.

## Ecto and tests

- Keep test modules asynchronous. Avoid shared application configuration, named processes, and public Erlang Term Storage tables that would require `async: false`.
- Start test processes with `start_supervised!/1`.
- Never insert literal values into uniquely indexed columns in concurrent tests. Use `System.unique_integer([:positive])` for the unique part of fixtures.
- Use `Ecto.Changeset.get_field/2` to read a changeset field.
- Do not cast programmatically assigned fields such as an owner identifier from user input.
- Generate migrations through `mix ecto.gen.migration` so timestamps and naming conventions remain correct.
- When adding a user-facing domain feature, add realistic and idempotent seed data unless that would be noisy or misleading.

## Routes and user interface

- Use the `~p` sigil for all routes, and `~pH` for Hypertext Transfer Protocol Secure URLs. Do not assemble paths with string concatenation.
- Parse, change, and build URLs with [`URI`](https://hexdocs.pm/elixir/URI.html), never string manipulation.
- Begin LiveView templates with `<Layouts.app ...>`.
- Use `Phoenix.Component.form/1` and `to_form/2` for forms.
- Give forms, buttons, tables, and other key elements a stable unique identifier.
- Use Noora components for cards, tables, badges, buttons, inputs, and sidebars. When styling is needed, use `data-part` attributes rather than classes.
- Every data table follows the established Tuist table pattern: a debounced search field, the Noora filter dropdown, active-filter controls, and sortable column headers. Keep search, filter, sort column, and sort direction in the URL so a table view is shareable and survives navigation. Use `<.table>` column `patch` and `sort_order` attributes for sorting rather than bespoke header controls.
- Follow the three-tier token system: primitives feed semantic tokens, and component tokens are only used for intentional local overrides. Do not introduce raw visual values outside primitive tokens.
- Put each route or component's styles in its own scoped Cascading Style Sheets file, imported by the thin `assets/css/noora.css` manifest.
- Keep responsive breakpoints consistent: mobile below 768 pixels, tablet from 768 to 960 pixels, desktop above 960 pixels.

## Caching and operational traceability

- Use [Cachex](https://hexdocs.pm/cachex) for in-memory caching. Prefer `Cachex.fetch/3` for expensive miss paths, return `{:ignore, value}` for failures, and bound user-controlled keys.
- When an action becomes operationally significant, capture who initiated it, the interface, action, target, useful metadata, and the dashboard path when applicable. Record that at the domain boundary rather than only in the user interface.

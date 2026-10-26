%{
  title: "Elixir and Phoenix (Gettext)",
  summary: "Configure Gettext translation, preserve catalog metadata, and reduce merge conflicts.",
  category: "how-to",
  section: "ecosystems",
  order: 1
}
---

Use this guide to connect an existing Elixir or Phoenix application using
[Gettext](https://hexdocs.pm/gettext/) to Glossia and keep its catalogs
merge-friendly. Run Mix commands from the directory containing `mix.exs`.

## 1. Configure deterministic extraction

Add these options to your existing `project/0` configuration in `mix.exs`:

```elixir
def project do
  [
    # Keep the application's other project options here.
    gettext: [
      write_reference_line_numbers: false,
      sort_by_msgid: :case_sensitive
    ]
  ]
end
```

Keep any other Gettext options you already use. `sort_by_msgid: :case_sensitive`
is supported by the Gettext version used by Glossia; check your dependency's
[extraction options](https://hexdocs.pm/gettext/Mix.Tasks.Gettext.Extract.html)
when applying this to another project.

Regenerate the templates and locale files:

```sh
mix gettext.extract --merge
```

Review and commit this one-time normalization separately from wording changes.
Message ordering should change, not existing translations. Coordinate this
normalization with open pull requests so their catalogs can be updated to the
same order.

Sorting places independent new messages in their canonical positions instead
of appending every addition to the end of the file. Omitting reference line
numbers avoids unrelated diffs when code moves; source file references remain.
These options reduce conflicts, but cannot eliminate conflicts over the same
message or guarantee that every pair of insertions merges automatically.

## 2. Translate templates, not application source

Create an `L10N.md` alongside `mix.exs`, or add the following mappings to your
existing configuration:

```yaml
---
source_language: en
sources:
  "priv/gettext/default.pot": "priv/gettext/{locale}/LC_MESSAGES"
  "priv/gettext/errors.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
---

Translate user-facing messages naturally and preserve all Gettext metadata.
Keep interpolation placeholders unchanged, including their names and syntax.
```

Only include domains present in your application. Add a mapping for each
additional domain, such as `dashboard_projects.pot`. The destination is a
directory: the portable-object handler writes `default.po`, `errors.po`, and
other matching domain filenames there.

Use `.pot` templates as sources and locale `.po` files as outputs. Do not use
one translated locale as the source for other locales. See the
[L10N.md reference](/docs/reference/l10n-md) for nested configurations and
the [getting-started tutorial](/docs/tutorials/getting-started) to connect
the repository to Glossia.

## 3. Extract before publishing source changes

When a pull request changes a `gettext`, `dgettext`, or `ngettext` call:

1. Update the application code.
2. Run `mix gettext.extract --merge`.
3. Review the template and locale diffs together with the code change.
4. Commit the generated changes before merging the pull request.

After the source changes merge, Glossia translates the updated templates and
publishes the locale changes in a translation pull request. Review those
translations through the repository's normal process.

Keep `msgid` and `msgctxt` as source identifiers. Translate `msgstr` values,
including the required plural variants. Preserve interpolation placeholders,
plural-form headers, source references, translator comments, and flags.
A `fuzzy` entry needs review: do not remove the flag just to make a check pass,
and do not assume its previous translation is correct for a changed message.

## 4. Validate catalog changes in CI

Run:

```sh
mix gettext.extract --merge --check-up-to-date
mix compile --warnings-as-errors
```

The extraction check catches templates or locale files that no longer match
the application source. Compilation checks that Gettext can compile the
catalogs. Neither command verifies linguistic quality or proves that every
message has a reviewed translation.

If extraction reports stale files, regenerate locally, review the diff, and
commit it. Do not bypass the check or repeatedly rewrite templates in the
translation worker to conceal a source mismatch.

## 5. Resolve catalog conflicts by message identity

When updating a branch from the default branch:

1. Resolve application source conflicts first, preserving the intended UI text.
2. Reconcile catalog entries from both branches using their context and source
   message identity, including plural identifiers where present. Preserve
   existing translations, comments, flags, and plural forms; remove conflict
   markers and duplicate entries before running the parser.
3. Run `mix gettext.extract --merge` against the resolved source.
4. Run the CI checks above and review the resulting catalog diff.

Do not resolve a catalog conflict by blindly accepting an entire side, enabling
a text-union merge driver, or concatenating the catalogs. Those approaches can
lose valid translations, duplicate identifiers, or leave an invalid file.
For recurring conflicts, add a regression test that generates catalogs on two
branches with different new messages and verifies that Git merges both the
template and translated catalog without losing entries.

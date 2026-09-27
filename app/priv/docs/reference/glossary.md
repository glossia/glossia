%{
  title: "Glossary",
  summary: "Reference for the glossary field in L10N.md and in each language's override file.",
  category: "reference",
  section: "translation",
  order: 2
}
---

A repository glossary is split across two files. Glossia merges it with the account's server glossary for every file it translates. See [Glossary](/docs/explanation/glossary) for how the two combine.

| File | `glossary` holds | Example |
|---|---|---|
| `L10N.md` | A list of **terms**, the same for every language. | `- source: commit` |
| `L10N/<locale>.md` | A map from term to its **translation** in that language. | `commit: commit` |

## Terms in L10N.md

```yaml
---
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
  - id: vcs-branch
    source: branch
    definition: A line of development in version control.
---
```

| Field | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The term as it appears in the source text. |
| `definition` | string | no | Short guidance the model reads to decide whether a match is really this concept. |
| `case_sensitive` | boolean | no | When `true`, the term only matches in the exact case written. Defaults to `false`. Use it for names and acronyms such as `API` or `SDK`. |
| `id` | string | no | Stable identifier. Derived from `source` when omitted (`Version Control` becomes `version-control`, `C++` becomes `cplusplus`). Set it to key translations by id, to rename `source` without losing the term's identity, or to override a term from a parent `L10N.md`. |

Terms do not carry translations. A term with a `targets` field is rejected: translations belong in the language files.

## Translations in L10N/<locale>.md

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
  vcs-branch: rama
  pull request: pull request
---
```

Each key is a term's `id` or its `source`, and each value is the approved translation for that language.

- A key that matches no term in `L10N.md` declares a term for this language only.
- A term without a translation in a language falls back to the server glossary for that language.
- To keep a name untranslated, map it to itself, for example `Glossia: Glossia`.

## Nested files

Every file is translated with the glossary of its directory chain:

- A nested `L10N.md` adds terms to the ones it inherits. A term with the same `id`, or the same `source` when no `id` is set, replaces the inherited one for that subtree.
- A nested `L10N/<locale>.md` adds translations to the ones it inherits, and its translation wins for a term both declare.

## Validation

If a glossary is invalid, Glossia translates the affected files with the server glossary only, so a typo never blocks translations. Common causes:

- **Missing `source`.** Every term needs a non-empty one.
- **Duplicate `id`.** Every term must resolve to a unique identifier, whether set explicitly or derived from `source`.
- **Translations in L10N.md.** A term with `targets`. Move the translations to `L10N/<locale>.md`.
- **Empty translation.** A term mapped to an empty string. Leave it out instead.
- **Wrong shapes or types.** `glossary` must be a list in `L10N.md` and a map in `L10N/<locale>.md`. Translations, `id`, and `definition` must be strings; `case_sensitive` must be `true` or `false`.

## What Glossia records

Each translated file's lockfile records the glossary entries that shaped it:

```json
{
  "server_context": {
    "glossary": {
      "applied": ["repo:commit", "account:repository"],
      "shadowed": ["account:commit"]
    }
  }
}
```

- `applied` lists the entries that matched the file. Repository entries appear as `repo:<id>`, server entries as `account:<id>`.
- `shadowed` lists server entries that a repository entry replaced for this file.

Editing a term or a translation only re-translates files that use it.

## See also

- [Define a glossary](/docs/how-to/define-a-glossary): step-by-step guide.
- [Glossary](/docs/explanation/glossary): how the repository and server glossaries combine.
- [L10N.md reference](/docs/reference/l10n-md): the other frontmatter fields.

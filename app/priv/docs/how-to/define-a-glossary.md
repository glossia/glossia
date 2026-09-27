%{
  title: "Define a glossary",
  summary: "Declare terms in L10N.md and their approved translations in each language's override file.",
  category: "how-to",
  section: "translation",
  order: 6
}
---

Your team already has terms that must translate a specific way: product names that stay in English, technical terms with a preferred rendering, brand words that carry a specific tone. Declare them in your repository and Glossia applies them to every future translation.

A glossary lives in two kinds of files you already use:

- `L10N.md` declares the **terms**: what the word is and what it means. This is the same for every language.
- `L10N/<locale>.md` declares the **translations** for one language. Each language's reviewers own their own file.

If your account also has a glossary on the server, the two are merged at translation time. See [Glossary](/docs/explanation/glossary) for the rules and for [when to use which](/docs/explanation/glossary#when-to-use-which).

## 1. Declare the terms in L10N.md

Add a `glossary` list to the frontmatter of your root `L10N.md`:

```yaml
---
source_language: en
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
---

Write for software developers.
```

Each term needs a `source`, the word as it appears in your text. A `definition` helps the model decide whether a match really is the concept you mean. `case_sensitive: true` makes `API` match without matching "api" in prose.

## 2. Translate them in each language's file

Create or open `L10N/<locale>.md` next to your `L10N.md` and map each term to its approved translation:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
---
```

```yaml
# L10N/ja.md
---
locale: ja
glossary:
  commit: コミット
  API: API
---
```

Keys are the term's `source`. A language with no translation for a term falls back to the server glossary, or lets the model choose.

## 3. Add a term that only one language needs

A language file can translate a word that `L10N.md` does not declare. The rule then applies to that language only:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. Give a term a stable id

When the same word needs a precise meaning, or you want to rename a term's `source` later, give it an `id` and key its translations by that id:

```yaml
# L10N.md
glossary:
  - id: vcs-branch
    source: branch
    definition: A line of development in version control, not a company branch office.
```

```yaml
# L10N/es.md
glossary:
  vcs-branch: rama
```

## 5. Refine the glossary for part of the repository

A nested `L10N.md` or `L10N/<locale>.md` inherits from its parent directories and can add or override entries for its subtree:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Spanish files under `marketing/` translate "commit" as `compromiso`; the rest of the repository keeps `commit`.

## 6. Commit and push

Commit the change and push. On the next translation run, Glossia re-translates only the files that use the terms you added or changed, in the languages whose translations changed. Files that do not contain those terms keep their existing translations.

If a glossary has a mistake, Glossia ignores the repository glossary for the affected files and uses the server glossary only, so check the [validation rules](/docs/reference/glossary#validation) when a term does not seem to apply.

## See also

- [Glossary reference](/docs/reference/glossary): every field and validation rule.
- [Glossary](/docs/explanation/glossary): how the repository and server glossaries combine.
- [L10N.md reference](/docs/reference/l10n-md): the other frontmatter fields.

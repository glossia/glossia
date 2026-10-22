%{
  title: "用語集",
  summary: "L10N.md および各言語のオーバーライドファイルにおける用語集フィールドの参照。",
  category: "参照",
  section: "translation",
  order: 2
}
---

リポジトリ用語集は 2 つのファイルに分割されています。Glossia は翻訳する各ファイルに対して、この用語集をアカウントのアカウント用語集とマージします。[用語集](/docs/explanation/glossary) で 2 つどのように組み合わされるかをご覧ください。

| File \| | `glossary` 含む | \| Example \| |
|---|---|---|
| `L10N.md` | A list of **terms**, the same for every language. \| | `- source: commit` |
| `L10N/<locale>.md` | A map from term to its **translation** in that language. \| | `commit: commit` |

## ## L10N.md の用語

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

| \| Field \| | \| Type \| | \| Required \| | \| Description \| |
|---|---|---|---|
| `source` | | string | | | yes | | | The term as it appears in the source text. | |
| `definition` | | string | | | no | | | Short guidance the model reads to decide whether a match is really this concept. | |
| `case_sensitive` | \| boolean \| | \| no \| | \| When `true`、タームは正確なケースのみ一致します。デフォルトは `false` です。名称や略語（`API` など`SDK`）に使用してください。\| |
| `id` | string \| | false \| | \| Stable identifier. Derived from `source` when omitted (`Version Control` becomes `version-control`, `C++` becomes `cplusplus`). Set it to key translations by id, to rename `source` without losing the term's identity, or to override a term from a parent `L10N.md`. \| |

| Terms do not carry translations. A term with a `targets` field is rejected: translations belong in the language files. |

## ## Translations in L10N/<locale>.md

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

Each key is a term's `id` or its `source`, and each value is the approved translation for that language. |

- | A key that matches no term in `L10N.md` declares a term for this language only. |
- \#\# A term without a translation in a language falls back to the account glossary for that language.
- \#\# To keep a name untranslated, map it to itself, for example `Glossia: Glossia`. \|

## ## Nested files

Every file is translated with the glossary of its directory chain:

- A nested `L10N.md` adds terms to the ones it inherits. A term with the same `id`, or the same `source` when no `id` is set, replaces the inherited one for that subtree.
- \#\# A nested `L10N/<locale>.md` adds translations to the ones it inherits, and its translation wins for a term both declare.

## ## Validation

If a glossary is invalid, Glossia translates the affected files with the account glossary only, so a typo never blocks translations. Common causes:

- **Missing `source`.** Every term needs a non-empty one.
- **Duplicate `id`.** Every term must resolve to a unique identifier, whether set explicitly or derived from `source`.
- **Translations in L10N.md.** A term with `targets`. Move the translations to `L10N/<locale>.md`.
- **Empty translation.** A term mapped to an empty string. Leave it out instead.
- **Wrong shapes or types.** `glossary` must be a list in `L10N.md` and a map in `L10N/<locale>.md`. Translations, `id`, and `definition` must be strings; `case_sensitive` must be `true` or `false`.

## Glossia が記録する内容

翻訳された各ファイルの lockfile が、そのファイルの内容を形成した glossary エントリを記録します。

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

- `applied` はそのファイルに一致したエントリをリストします。リポジトリのエントリは `repo:<id>`、アカウントのエントリは `account:<id>` として表示されます。
- `shadowed` は、このファイルでリポジトリのエントリが置換したアカウントのエントリをリストします。

用語または翻訳の編集は、それを使用するファイルのみを再翻訳します。

## 参照

- [ glossary の定義](/docs/how-to/define-a-glossary)：ステップバイステップのガイド。
- [ glossary](/docs/explanation/glossary)：リポジトリ glossary とアカウント glossary がどのように結合するか。
- [ L10N.md の参考](/docs/reference/l10n-md)：他の frontmatter フィールド。

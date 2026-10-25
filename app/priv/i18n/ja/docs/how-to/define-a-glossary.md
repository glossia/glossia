%{
  title: "用語集を定義する",
  summary: "用語を L10N.md に宣言し、各言語のオーバーライドファイルで承認された翻訳を明記する。",
  category: "手引き",
  section: "translation",
  order: 6
}
---

チームには既に特定の方法で翻訳する必要がある用語があります：そのまま英語のまま使用する製品名、 preferred rendering が必要な技術用語、そして特定のトーンを持つブランド用語など。リポジトリに宣言すれば、Glossia がそれらを今後のすべての翻訳にあてはめます。

辞書は、すでに使用している 2 種類のファイルに存在します：

- `L10N.md` では、**用語** を宣言します：単語とは何であり、どのような意味を持っているか。これはどの言語でも同じです。
- `L10N/<locale>.md` では、特定の言語向けの **翻訳** を宣言します。各言語のレビューアーは自らのファイルを管理します。

アカウントが Glossia に用語集を持っている場合、両者は翻訳時にマージされます。規則については [用語集](/docs/explanation/glossary) を参照し、[どちらを使用するか](/docs/explanation/glossary#when-to-use-which) についても確認してください。

## ## 1. L10N.md で用語を宣言して登録

root `L10N.md` の frontmatter に `glossary` リストを追加します：

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

各用語には、文字列内で文字通り表示される `source` が必要です。`definition` は、一致が本当に意味する概念であるかをモデルに判定させるのを助けます。`case_sensitive: true` により、`API` は文章内の "api" と一致せず一致します。

## ## 2. 各言語のファイルで翻訳

`L10N/<locale>.md` を `L10N.md` の隣に作成または開いて、各用語を承認された翻訳にマップします：

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

キーは用語の `source` です。用語の翻訳がない言語は、アカウント辞書にフォールバックするか、モデルが選択できます。

## ## 3. 一度きりの言語に要件を追加する

言語ファイルは、`L10N.md` で宣言されていない単語を翻訳できます。そのルールは後で使用言語にのみ適用されます：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## ## 4. 用語に安定した ID を与える

同じ言葉に正確な意味が必要な場合、または後に用語の `source` をリネームしたい場合は、`id` を指定し、翻訳をその ID でキー登録します。

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

## ## 5. リポジトリの一部のための辞書を細分化する

ネストされた `L10N.md` または `L10N/<locale>.md` は親ディレクトリから継承し、サブツリーのエントリを追加または上書きできます。

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

`marketing/` 下のスペイン語ファイルした "commit" は `compromiso` に翻訳されます；残りのリポジトリは `commit` を保持します。

## ## 6. Commit and push

変更を commit と push してください。次の翻訳実行で、Glossia は追加または変更した用語を使用するファイルだけ、その言語の翻訳に変更があった言語だけで再翻訳します。それらの用語を含んでないファイルは既存の翻訳を保持します。

辞書に誤りがある場合、Glossia は該当ファイルにリポジトリ辞書を使用せず、アカウント辞書のみを使用します。用語が適用されてないように見える場合は [validation rules](/docs/reference/glossary#validation) に確認してください。

## ## 関連リンク

- [Glossary reference](/docs/reference/glossary)：すべてのフィールドとバリデーションルール。
- [Glossary](/docs/explanation/glossary)：リポジトリとアカウント辞書のマージ方法。
- [L10N.md reference](/docs/reference/l10n-md)：その他の frontmatter フィールド。

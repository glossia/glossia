%{
  title: "用語集を定義する",
  summary: "用語を L10N.md に宣言し、各言語のオーバーライドファイルにはそれぞれの承認翻訳を記載してください。",
  category: "チュートリアル",
  section: "translation",
  order: 6
}
---

あなたのチームにはすでに、特定の翻訳方法が必須となる用語が存在しています：英語のまま使用する製品名、推奨された表示形式を持つ技術用語、特定のトーンを含むブランド名。それらをリポジトリに宣言し、Glossia がすべての将来の翻訳に適用します。

用語集は、すでに利用している 2 つ種類のファイルに存在しています：

- `L10N.md` は **用語** を宣言します：言葉とは何で、どのような意味を持つのか。これはすべての言語で同じです。
- `L10N/<locale>.md` は **翻訳** を宣言します。それぞれの言語のレビュアーがファイルを所有します。

あなたのアカウントに Glossia 内にも用語集がある場合、翻訳時に両者はマージされます。[用語集](/docs/explanation/glossary) のルールおよび [どちらを使用すべきか](/docs/explanation/glossary#when-to-use-which) についてご参照ください。

## 1. L10N.md に用語を宣言します

`glossary` リストを root の ``L10N.md`` のフロントマッターに追加します：

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

各用語には '`source`' が必要で、これはテキストに表示される語です。「`definition`」はモデルが一致が本当に意図する概念か決定するのに役立ちます。「`case_sensitive: true`」の場合、'`API`' は一致します。

## 2. 各言語ファイルで翻訳します

あなたの `L10N.md` の隣に `L10N/<locale>.md` を作成または開いて、各用語を承認された翻訳にマッピングします：

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

キーは用語の '`source`' になります。

## 3. 特定の言語だけが翻訳が必要な用語を追加します

言語ファイルでは、'`L10N.md`' で宣言されていない言葉を翻訳できます。そのルールはそれらの言語だけに適用されます：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. 用語に安定した ID を与えます

同じ語に正確な意味が必要、または後で用語の '`source`' を名前変更したい場合、'`id`' を与え、翻訳をその ID で管理します：

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

## 5. リポジトリの一部の用語集を改良します

ネストされた '`L10N.md`' または '`L10N/<locale>.md`' は、親ディレクトリから継承され、子ツリー内のエントリを追加または上書き可能です：

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

`marketing/` の下にあるスペイン語ファイルは "commit" を '`compromiso`' に翻訳します；リポジトリの残りは '`commit`' を保ちます。

## 6. コミットしてプッシュします

変更をコミットしてプッシュします。次の翻訳実行時に、Glossia は追加または変更した用語を使用しているファイルを、その翻訳が変更された言語のみに限定して再翻訳します。それらの用語が含まれていないファイルは既存の翻訳を維持します。

用語集にミスの場合、Glossia は該当ファイルにはレポジトリの用語集を無視し、アカウントの用語集のみを使用します。そのため、用語が正当に適用されていない場合は、'[バリデーションルール](/docs/reference/glossary#validation)' を確認してください。

## その他

- [辞書参照](/docs/reference/glossary)：すべてのフィールドと検証ルール。
- [辞書](/docs/explanation/glossary)：リポジトリとアカウントの用語集がどのように結合されるか。
- [L10N.md 参照](/docs/reference/l10n-md)：他のフロントマターフィールド。

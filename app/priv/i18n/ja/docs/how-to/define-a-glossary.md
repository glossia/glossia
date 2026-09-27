%{
  title: "用語集を定義する",
  summary: "L10N.md に用語を宣言し、各言語のオーバーライドファイルに承認された翻訳を記載する。",
  category: "使用方法",
  section: "翻訳",
  order: 6
}
---
あなたのチームには既に、特定の訳の仕方を定めた用語があります : 英語のまま残すべき製品名、推奨される表記の技術用語、特定のトーンを持つブランド語です。レポジトリにこれらを定義して、Glossia はそれらをすべての将来の翻訳に適用します。

用語集は、あなたが既に使用している 2 種類のファイルにあります：

- `L10N.md` 定義する **用語**: その語の定義と意味。すべての言語で同じです。
- `L10N/<locale>.md` 定義する **翻訳** 一つの言語用の翻訳。各言語のレビューアは独自ファイルを持っています。

もしあなたのアカウントにもサーバー上の用語集があれば、翻訳時に 2 つはマージされます。参照 [用語集](/docs/explanation/glossary) のルールおよび [どちらをいつ使うべきかについて](/docs/explanation/glossary#when-to-use-which)。

## 1\. 用語を L10N.md で定義

追加 `glossary` リストをあなたのルート frontmatter に `L10N.md`:

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

各用語には、 `source`、テキストに現れる元の単語を指定してください。また `definition` 一致が実際に意図する概念であることをモデルが判断するのに役立ちます。 `case_sensitive: true` 作る `API` 文章内で "api" を含めずに一致させる。

## 2\. 各言語のファイルで翻訳する

作成または開く `L10N/<locale>.md` あなたの横に `L10N.md` また、各用語を承認済みの翻訳にマッピングします：

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

キーは用語の `source`。用語の翻訳がない言語は、サーバーの用語集にフォールバックするか、モデルに選択させます。

## 3\. 必要な言語のみの用語を追加する

言語ファイルは、単語を翻訳する `L10N.md` 宣言っていない場合、その規則は該当の言語のみに適用されます：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. 用語に安定した ID を割り当てる

同じ単語に正確な意味が必要な場合、または用語名を変更したい場合 `source` 後で、これに `id` その ID をキーとして翻訳を登録します：

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

## 5\. リポジトリの一部の用語集を微調整する

ネストされた `L10N.md` または `L10N/<locale>.md` 親ディレクトリから継承し、サブツリーのエントリを追加または上書きできる

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

以下のスペイン語ファイル `marketing/` 「commit」を翻訳して `compromiso`、他のリポジトリのファイルは維持されます `commit`。

## 6\. コミットしプッシュ

変更をコミットし、プッシュしてください。

用語集に誤りがある場合、Glossia は影響を受けたファイルのレポジトリ用語集を無視し、サーバー用語集のみを使用します。そのため、 [バリデーションルール](/docs/reference/glossary#validation) 用語が適切でない場合に。

## 「関連項目」

- [用語集参照](/docs/reference/glossary)：各フィールドおよび検証ルールについて。
- [用語集](/docs/explanation/glossary)：リポジトリとサーバーの用語集がどのように統合されるか。
- [L10N.md 参照](/docs/reference/l10n-md)：他のフロントマターフィールドについて。
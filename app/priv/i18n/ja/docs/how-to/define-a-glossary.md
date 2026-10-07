%{
  title: "用語集を定義する",
  summary: "用語を L10N.md に宣言し、各言語の上書きファイルに承認済みの翻訳を記載する。",
  category: "チュートリアル",
  section: "translation",
  order: 6
}
---
あなたのチームには、特定の翻訳方法が必要な用語が既に存在します：英語のまま残る製品名、推奨された表記を持つ技術用語、特定のトーンを持つブランド語などです。それらをリポジトリに宣言し、Glossia はそれらをすべての将来の翻訳に適用します。

用語集はすでにお使いの 2 種類のファイルに存在します：

- `L10N.md` 定義する **用語**: どの言葉で、何を意味するか。これはすべての言語で同じです。
- `L10N/<locale>.md` 定義する **翻訳** 一つの言語向けです。各言語のレビュー担当者は独自のファイルを管理します。

アカウントに Glossia の用語集があれば、翻訳時に 2 つは統合されます。ご参照 [用語集](/docs/explanation/glossary) ルールの適用と [どちらを使用すべきか](/docs/explanation/glossary#when-to-use-which)。

## 1\. 用語を L10N.md に明記してください

追加 `glossary` リストをルートの frontmatter に `L10N.md`:

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

各用語には、 `source`, 本文の単語です。また、 `definition` モデルがその一致が本当に意図する概念なのかを判断するのを助けます。 `case_sensitive: true` , 一致させます `API` 「api」などの単語が原文に含まれても一致させません。

## , 2. それぞれの言語のファイルで翻訳します

, 作成または開く `L10N/<locale>.md` あなたの隣に `L10N.md` 各用語を承認された訳文にマッピングします:

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

キーは用語の `source`. 用語の翻訳がない言語は、アカウント辞書にフォールバックするか、モデルが選択します。

## 3\. 1 つの言語だけが使用する用語を追加

言語ファイルは宣言されていない単語を翻訳できます `L10N.md` 宣言していない。その場合、このルールはその言語のみに適用されます:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. 用語に安定した ID を割り当て

同じ単語に正確な意味が必要な場合、または用語を変更したい場合 `source` 後で、それに ID を `id` 設定し、その ID で翻訳を紐付けます：

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

ネストされた `L10N.md` または `L10N/<locale>.md` 親ディレクトリから継承し、その下のエントリを追加または上書きできます：

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

以下のスペイン語ファイル `marketing/` 「commit」を「コミット」とする `compromiso`; リポジトリの残りのファイルは `commit`.

## 6\. コミットし、プッシュする

変更をコミットし、プッシュしてください。次の翻訳実行時に、Glossia は翻訳が変更された言語内の、あなたが追加または変更した用語を使用するファイルのみを再翻訳します。これらの用語が含まれていないファイルは、既存の翻訳を維持します。

用語集に誤りがある場合、Glossia は影響を受けるファイルにおけるリポジトリ用語集を無視し、アカウント用語集のみを使用するため、 [バリデーションルール](/docs/reference/glossary#validation) 用語が適切に見えない場合は、

## 関連

- [用語集 参照](/docs/reference/glossary)：すべてのフィールドとバリデーションルール。
- [用語集](/docs/explanation/glossary)：リポジトリとアカウントの用語集がどのように結合されるか。
- [L10N.md 参照](/docs/reference/l10n-md)：他のフロントマターのフィールド。
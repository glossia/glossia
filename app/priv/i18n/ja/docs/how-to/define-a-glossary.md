%{
  title: "用語集を定義する",
  summary: "用語を L10N.md に宣言し、各言語の上書きファイルに承認済みの翻訳を記載する。",
  category: "チュートリアル",
  section: "translation",
  order: 6
}
---
あなたのチームには、既に特定の翻訳方法が必要な用語があります。英語のまま残す製品名、推奨される技術用語、特定のトーンを持つブランド語などです。それらをリポジトリに宣言し、Glossia は今後のすべての翻訳に適用します。

用語集は、既に使っている 2 つの種類のファイルにあります：

- `L10N.md` 宣言する **用語**: その用語が何であり、何を意味するか。すべての言語で同じです。
- `L10N/<locale>.md` 宣言する **翻訳** 一つの言語用。各言語のレビュアーは各自のファイルを管理します。

あなたのアカウントに Glossia の用語集もある場合、翻訳時にこれら 2 つはマージされます。参照 [用語集](/docs/explanation/glossary) ルールについてはおよび [使用するべきものはどれか](/docs/explanation/glossary#when-to-use-which)。

## 1\. 用語を L10N.md に明記する

追加する `glossary` リストを root の frontmatter に `L10N.md`：

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

各用語には `source`, 元の文章の単語です。これ `definition` モデルが実際にあなたが意味する概念に合致しているか判断するのを助けます。 `case_sensitive: true` 作成 `API` 本文で "api" を一致させずに一致させる。

## 2\. 各言語のファイルでそれらを翻訳する。

作成または開く `L10N/<locale>.md` あなたのそばに `L10N.md` および各用語を承認された翻訳にマッピング：

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

キーは用語の `source`。用語に翻訳がない場合、アカウントの用語集にフォールバックするか、モデルに選択を任せます。

## 3\. 一部の言語にのみ必要な用語を追加

言語ファイルは単語を翻訳できますが、 `L10N.md` 宣言していない。そのルールは、その言語のみで適用されます：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. 用語に安定した ID を与える

同じ単語に正確な意味が必要になったり、用語の名前を変更したい場合は、 `source` 後で、専用の ID を割り当て、 `id` そしてその ID をキーとして翻訳を管理する:

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

## 5\. リポジトリの一部の用語集を精査する

ネストされた `L10N.md` または `L10N/<locale>.md` 親ディレクトリから継承し、そのサブツリーのエントリーを追加または上書きできます:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

スペイン語のファイル以下の `marketing/` 「commit」を `compromiso`、残りのリポジトリは `commit`。

## 6\. 変更をコミットしてプッシュ

変更をコミットしてプッシュします。次の翻訳実行時に、Glossia はあなたが追加または変更した用語を使用するファイルおよび翻訳が変更された言語についてのみ再翻訳を行います。これらの用語を含まないファイルは、既存の翻訳を保持します。

用語集に誤りがある場合、Glossia は影響を受けるファイルのリポジトリ用語集を無視し、「アカウントの用語集」のみを使用するため、以下の [バリデーションルール](/docs/reference/glossary#validation) 用語が適切に適用できない場合。

## 関連

- [辞書参照](/docs/reference/glossary): すべてのフィールドおよびバリデーションルール。
- [辞書](/docs/explanation/glossary): リポジトリ辞書とアカウント辞書の結合方法。
- [L10N.md 参照](/docs/reference/l10n-md): 他のフロントマターフィールド。
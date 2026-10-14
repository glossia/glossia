%{
  title: "用語集を定義する",
  summary: "L10N.md に用語を明記し、各言語のオーバーライドファイルに承認済み翻訳を明記する。",
  category: "チュートリアル",
  section: "translation",
  order: 6
}
---

チームには既に特定の方法で翻訳しなければならない用語があります：英語のまま残す产品名称、preferred rendering がある技術用語、特定 Ton を持つブランド用語など。これらをリポジトリに宣言し、Glossia がすべての将来の翻訳に適用します。

翻訳用語集は、すでにご利用のファイルの 2 種類に存在します:

- `L10N.md` 定義する **用語**：単語とは何か、意味は何なのか。これはどの言語にでも同じである。
- `L10N/<locale>.md` 用の言語の **翻訳** 宣言する。各言語のレビュアーは自らのファイルを持っている。

あなたのアカウントが Glossia に辞書を持っている場合、2 つは翻訳時にマージされる。ためにルールや [どちらを使うか](/docs/explanation/glossary#when-to-use-which) については [辞書](/docs/explanation/glossary) を参照。

## 1. F10N.md に用語を宣言する

`glossary` リストをルートの `L10N.md` の frontmatter に追加する:

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

各用語はそのテキストででてくる単語の `source` が必要。一個 `definition` はモデルにマッチが本当にあなたが意味する概念であるか判断するのを助ける。 `case_sensitive: true` は `API` をプロースでも matches させて api に対するマッチしないで。

## 2. F10N.md で翻訳する

`L10N/<locale>.md` を `L10N.md` の横に作り、用語を承認された翻訳にマップして:

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

Key 用語の `source` を持った。言語が用語に対する翻訳がない場合、アカウントの辞書にフォールバックするか、モデルに選ばせる。

## 3. 言語に用語を追加する

言語ファイルは `L10N.md` に対して宣言されない語を翻訳できる。ルールはその後、その言語のみ適用される:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. 用語に安定した Indah を与える

同じ単語が正確な意味必要があるか、または後で用語の `source` をリネームしたい場合、 `id` を与えて翻訳をその汉书によって Key する:

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

## 5. 辞書をリファインする for パートのリポジトリ

ネストした `L10N.md` や `L10N/<locale>.md` はその上部ディレクトリから継承し、そのツリーに追加またはオーバーライドするentries ができる:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

`marketing/` の下の Spanish ファイルで "commit" を `compromiso` として翻訳する；リポジトリの残りは `commit` を持つ。

## 6. Commit and push

変更を commit して push する。次の翻訳実行で、Glossia は追加または変更した用語をその翻訳が変化した言語で再翻訳するから。その用語を含んでいないファイルは既存の翻訳を維持する。

辞書に誤りがある場合、Glossia は影響を受けたファイルに対してリポジトリの辞書を無視し、アカウント辞書のみ使用するので、 [検証のルール](/docs/reference/glossary#validation) を確認する。

## もっと見る

- [辞書 reference](/docs/reference/glossary): every field and validation rule.
- [辞書](/docs/explanation/glossary): リポジトリとアカウントの辞書がどう結合するか。
- [L10N.md reference](/docs/reference/l10n-md): 他の frontmatter フィールド。

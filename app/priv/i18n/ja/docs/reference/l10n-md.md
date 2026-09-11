%{title: "L10N.md", summary: "リポジトリの翻訳設定とコンテキストの参考.", category: "reference", order: 1}
---
`L10N.md` Glossia に翻訳対象ファイル、翻訳ファイルの配置先、ターゲット言語、および結果を導くコンテキストを指定します。リポジトリにはルートファイルと、サブディレクトリにある追加のスコープファイルを含めることができます。

## 構造

各ファイルは 2 つの部分で構成されています：

1. [YAML はマークアップ言語ではありません](https://yaml.org/) frontmatter はマーカーの間に配置されます `---` マーカー。
2. frontmatter の直下にあるマークダウンには、プロダクト、オーディエンス、トーン、またはドメインのコンテキストを含めます。

<!-- end list -->

```yaml
---
source_language: en
model: translation-default
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
validation:
  - ./scripts/validate-docs.sh
  - --strict
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Write for software developers. Keep product names and code samples unchanged.
```

プロバイダーの認証情報はアカウント設定に保存し、決して `L10N.md`. オプションの `model` 値はアカウントモデルのハンドルです。

## Frontmatter フィールド

| フィールド | タイプ | 必須 | 説明 |
|---|---|---|---|
| `source_language` | 文字列 | なし | このスコープのソースロケールです。デフォルトは `en`。 |
| `model` | 文字列 | なし | アカウントモデルのハンドル。Glossia は省略時にアカウントのデフォルトを使用し、明示的なハンドルが存在しない場合はエラーを報告します。 |
| `sources` | マップまたはリスト | トップレベルのルールの場合 | ソース ファイル パターン。マップの値は出力テンプレートを定義できます。 |
| `targets` | マップまたはリスト | ソースが設定されている場合 | ターゲット ロケール コード。マップはロケールコードを言語名に関連付けることができます。 |
| `output` | 文字列 | ソースマッピングがない場合または `target_path` 出力先を指定 | 出力ファイルテンプレート。 |
| `target_path` | string | ソースマッピングがない場合または `output` 出力先を指定 | 翻訳されたファイルのベースディレクトリテンプレート。 |
| `translate` | list | no | 独自のソースとオプションのオーバーライドを持つ複数の翻訳ルール。 |
| `exclude` | list | no | スキップするファイルパターン。 |
| `preserve` | list | no | 不変のコンテンツの種別（プレースホルダー、URI など）。|
| `frontmatter` | string | no | `preserve` デフォルトでは、または `translate`。 |
| `prompt` | string | no | このスコープまたはルールに関する追加ガイダンス。|
| `validation` | list | 内蔵アダプターのないファイル拡張子用 | 引数を伴う検証コマンド。コマンドは候補を実ターゲットパスで受け取り、ファイルが無効の場合 0 以外のステータスを返す必要がある。 |
| `check_cmd` | string | no | 翻訳ワークフローに利用可能なチェックコマンド。 |
| `check_cmds` | map | no | 翻訳ワークフローに利用可能な名前付きチェックコマンド。 |
| `retries` | integer | no | チェック失敗後の再試行回数。デフォルトは `2`. |
| `locale` | string | no | ローケル固有のコンテキストファイルに付随するローケル。 |

Unknown frontmatter fields are ignored.

## File formats

Glossia has built-in handling for Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object, and plain text files. Other file extensions fail planning unless the applicable `L10N.md` declares a `validation` command. This avoids silently treating a proprietary structured format as unconstrained text.

検証コマンドは、候補が実際のターゲットパスに一時的に書き込まれた後に実行されます。リポジトリ固有のパーサー、コンパイラ、またはビルドコマンドを呼び出すことができます。各検証試行後、Glossia は以前のターゲットを復元し、受け入れられた候補のみをその後、書き込みます。

## ソースマッピング

最も明確な形式では、すべてのソースパターンを出力テンプレートにマッピングします：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースリストも有効ですが、それには `output` または `target_path` 出力先を定義する必要があります：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## ターゲット言語

リストは各ローカルコードを言語識別子として使用します:

```yaml
targets:
  - es
  - ja
```

マップは読みやすい言語名を追加できます:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 出力変数

| 変数 | 値 |
|---|---|
| `{locale}`または`{lang}` | ターゲットローカルコード. |
| `{relpath}` | 一致したパターンの相対パス. |
| `{basename}` | 拡張子付きソースファイル名. |
| `{ext}` | 先頭のドットを含む拡張子. |

## 複数のルール

異なるコンテンツグループが異なる目的地やチェックを必要とする場合は `translate`を使用します:

```yaml
---
source_language: en
targets:
  - es
translate:
  - sources:
      - "docs/**/*.md"
    output: "docs/i18n/{locale}/{relpath}"
  - source: "messages/*.json"
    output: "messages/{locale}/{basename}.{ext}"
---
```

ルール値は周囲のファイルから継承される値を書き換えます.

## 範囲付きコンテキスト

Glossia はリポジトリルートからソースファイルに向かって `L10N.md`ファイルを読みます:

- パレンタル設定はデフォルトを提供します.
- 深いファイルはディレクトリに対応するフィールドを上書きします.
- Markdown コンテキストは子から親へ蓄積されます.
- ローカル固有のガイダンスとローカル固有モデルハンドラは `L10N/<locale>.md`に置けます.

これにより、リポジトリはルートで一般的なボイスガイドを維持しつつ、影響を受けるコンテンツに近接して製品領域または言語固有のガイダンスを配置できます.
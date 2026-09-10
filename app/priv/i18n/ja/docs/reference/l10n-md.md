%{title: "L10N.md", summary: "リポジトリ翻訳設定およびコンテキストの参考。", category: "参考", order: 1}
---
`L10N.md` Glossia が翻訳対象ファイル、翻訳済みの配置先、ターゲット言語、および結果を導くコンテキストを指定します。リポジトリにはルートファイルと、サブディレクトリ内の追加のスコープファイルを含めることができます。

## 構造

各ファイルには 2 つの部分があります。

1. [YAML はマークアップ言語ではありません](https://yaml.org/) フロントマターは間 `---` マーカー。
2. フロントマターの後ろにある Markdown は、製品、視聴者、トーン、またはドメインのコンテキストを含みます。

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

プロバイダー認証情報はアカウント設定に入れ、決してこれには入れません。 `L10N.md`. The optional `model` value is an account model handle.

## Frontmatter fields

| フィールド | タイプ | 必須 | 説明 |
|---|---|
| `source_language` | 文字列 | なし | このスコープのソースロケール。デフォルトは `en`. |
| `model` | string | no | アカウントモデルのハンドル。Glossia は省略されている場合はアカウントのデフォルトを使用し、明示的なハンドルが存在しない場合はエラーを報告します。 |
| `sources` | map or list | トップレベルのルールの場合 | ソースファイルパターン。マップ値は出力テンプレートを定義できます。 |
| `targets` | map or list | ソースが設定されている場合 | ターゲットのローケルコード。マップはローケルコードを言語名と関連付けることができます。 |
| `output` | string | ソースマッピングがない場合や `target_path` 設定先を指定する | 出力ファイルのテンプレート。|
| `target_path` | string | ソースマッピングがない場合、または `output` 設定先を指定する | 翻訳ファイルのベースディレクトリテンプレート。|
| `translate` | list | no | 複数の翻訳ルール。各には独自のソースとオプションの上書きが含まれます。|
| `exclude` | list | no | 除外するファイルパターン。|
| `preserve` | リスト | いいえ | 変更しないことになっているコンテンツの種類（プレースホルダーや URI など）。|
| `frontmatter` | 文字列 | いいえ | `preserve` デフォルトの場合、または `translate`。 |
| `prompt` | 文字列 | いいえ | このスコープまたはルールに関する追加の説明。|
| `validation` | list | ビルトインアダプターを持たないファイル拡張子 | 引数を含む検証コマンドです。コマンドは候補をその実際のターゲットパスで受け取り、ファイルが無効な場合はゼロ以外のステータスを返す必要があります。|
| `check_cmd` | string | no | 翻訳ワークフローで使用可能なチェックコマンドです。|
| `check_cmds` | map | no | 翻訳ワークフローで使用可能な名前付きチェックコマンドです。|
| `retries` | integer | no | チェック失敗後のリトライ回数は。デフォルトは `2`. |
| `locale` | 文字列 | いいえ | ロケール固有のコンテキストファイルに紐付けられたロケール

Unknown frontmatter fields are ignored.

## File formats

Glossia は Markdown、JavaScript Object Notation、YAML Ain't Markup Language、portable object、および plain text ファイルに対応しています。他のファイル拡張子は、計画に失敗します。該当する場合を除き `L10N.md` 宣言する `validation` コマンド。これにより、専用構造化形式を無制約テキストとして沈黙で扱うことを回避します。

検証コマンドは、候补が一時的に実際のターゲットパスに書き込まれた後に実行されます。リポジトリ固有のパッサー、コンパイラ、またはビルドコマンドを呼び出すこともできます。Glossia は各検証試行後に以前のターゲットを復元し、承認された候补のみをその後に書き込みます。

## ソースマッピング

最も明確な形式は、各ソースパターンを出力テンプレートにマッピングします：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースリストも有効ですが、これには `output` または `target_path` 宛先を定義する：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 対象言語

リストは、各ロケールコードを言語識別子として使用します：

```yaml
targets:
  - es
  - ja
```

マップ（辞書型構造）は、読みやすい言語名を追加できます：

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 出力変数

| 変数 | 値 |
|---|---|
| `{locale}` または `{lang}` | 対象ロケールコード。 |
| `{relpath}` | 一致したパターンに対するソースパスの相対位置。 |
| `{basename}` | 拡張子を除くソースファイル名。 |
| `{ext}` | 先頭ドットを除くソースファイル拡張子。 |

## 複数のルール

異なる内容グループに対して異なる出力先または検証が必要時に、 `translate` を使用します：

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

ルールの値は、周囲のファイルから継承される値を上書きします。

## スコープ付きコンテキスト

Glossia はリポジトリのルートからソースファイルに向かって `L10N.md` ファイルを読み取ります：

- 親の設定はデフォルト値を提供します。
- より深いファイルは、そのディレクトリ用のフィールドを上書きします。
- マークダウンのコンテキストは親から子へ累加されます。
- ロケール別ガイダンスとロケール別モデルハンドラーは、`L10N/<locale>.md` に存在できます。

これにより、リポジトリはルートの一般的なトーンガイダンスを維持しつつ、影響を与えるコンテンツに近い場所に製品領域や言語別のガイダンスを配置できます。
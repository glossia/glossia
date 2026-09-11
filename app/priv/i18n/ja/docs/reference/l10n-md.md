%{title: "L10N.md", summary: "リポジトリ翻訳の設定とコンテキストに関する参考。", category: "参考", order: 1}
---
`L10N.md` は Glossia にどのファイルを翻訳すべきか、翻訳されたファイルがどこに属するか、対象言語、そして結果を導くべきコンテキストを示します。リポジトリにはルートファイルと、サブディレクトリ内の追加の scoped ファイルを持つことができます。

## Structure

各ファイルには 2 つの部分があります：

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter は `---` マーカーの間で構成されます。
2. frontmatter 以下の Markdown で、製品、対象読者、voice、またはドメインのコンテキストが含まれます。

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

プロバイダの認証情報はアカウント設定に帰属され、決して `L10N.md` には含まれません。オプションの `model` 値はアカウントモデルハンドルです。

## Frontmatter fields

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `source_language` | string | なし | このスコープのソースロケール。デフォルトは `en`。 |
| `model` | string | なし | アカウントモデルハンドル。省略された場合はアカウントのデフォルトを使用。明示的なハンドルが存在しない場合はエラーを報告します。 |
| `sources` | map or list | トップレベルのルール用 | ソースファイルパターン。マップ値は出力テンプレートと定義可能です。 |
| `targets` | map or list | ソースが構成されたとき | ターゲトロケールコード。マップはロケールコードと言語名とを関連付けることができます。 |
| `output` | string | ソースマッピングが指定されず、または `target_path` で目的地が指定されていないとき | 出力ファイルテンプレート。 |
| `target_path` | string | ソースマッピングが指定されず、または `output` で目的地が指定されていないとき | 翻訳されたファイルのベースディレクトリテンプレート。 |
| `translate` | list | なし | それぞれに独自のソースとオプションのオーバーライドを持つ複数の翻訳ルール。 |
| `exclude` | list | なし | スキップするファイルパターン。 |
| `preserve` | list | なし | 変更せずに保持すべきコンテンツ種別、例えばプレースホルダーや一様リソース locator など。 |
| `frontmatter` | string | なし | デフォルトでは `preserve`、または `translate`。 |
| `prompt` | string | なし | このスコープまたはルールに対する追加のガイダンス。 |
| `validation` | list | ビルドインアダプタがないファイル拡張子用 | ユーザーの入力として提供するコマンド。コマンドは実際のターゲットパスで候補を受け取り、ファイルが無効な場合に非ゼロのステータスを返す必要があります。 |
| `check_cmd` | string | なし | 翻訳ワークフローに利用可能なチェックコマンド。 |
| `check_cmds` | map | なし | 翻訳ワークフローに利用可能な名前付けされたチェックコマンド。 |
| `retries` | integer | なし | チェック失敗後のリトライ回数の数。デフォルトは `2`。 |
| `locale` | string | なし | 局域化固有のコンテキストファイルに結合されたロケール。 |

不明な frontmatter フィールドは無視されます。

## File formats

Glossia は Markdown、JavaScript Object Notation、YAML Ain't Markup Language、portable object、および Plain Text ファイルに対してネイティブ対応しています。他のファイル拡張子は、適用可能な `L10N.md` で `validation` コマンドが宣言される場合を除き、 планирование は失敗します。これは、独自構造形式を無制約テキストとして静黙に扱わないためです。

検証コマンドは、候補がリポジトリ内のネイティブパーサー、コンパイル、またはビルドコマンドを呼び出す前に一時的に実際のターゲットパスに書き込まれると、実行されます。Glossia は各検証試行後、以前のターゲットを復元し、候補が受け入れられ後の応答のみで書き込みます。

## Source mappings

最も明確な形式は、すべてのソースパターンを出力テンプレートにマッピングする形式です：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースリストも有効ですが、`output` または `target_path` が必要です。

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 対象言語

リストは各ロケールコードを言語識別子として使用します:

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
| `{locale}` or `{lang}` | 対象のロケールコード。 |
| `{relpath}` | ソースパスは、一致パターンに対する相対パスです。 |
| `{basename}` | ソースファイル名の拡張子を除いた部分。 |
| `{ext}` | ソースファイルの拡張子（前連続のドットを除く）。 |

## 複数のルール

異なるコンテンツグループが異なる宛先またはチェックを必要とする場合は、 `translate` を使用します:

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

ルールの値は、周囲のファイルから継承された値を上書きします。

## スコープ付きコンテキスト

Glossia はリポジトリのルートからソースファイルに向かって `L10N.md` ファイルを読み取ります:

- 親設定は初期値を提供します。
- より深いファイルは、ディレクトリの項目を上書きします。
- マークダウンのコンテキストは親から子へと蓄積されます。
- ロケール固有のガイダンスとロケール固有のモデルハンドルは `L10N/<locale>.md` に存在することができます。 

これにより、リポジトリはルートで広範な Voice ガイダンスを保持しつつ、影響するコンテンツに近い位置に製品領域または言語固有のガイダンスを配置できます。
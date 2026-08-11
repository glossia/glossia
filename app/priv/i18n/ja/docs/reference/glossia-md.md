%{
  title: "GLOSSIA.md",
  summary: "リポジトリの翻訳設定とコンテキストに関するリファレンス。",
  category: "reference",
  order: 1
}
---
`GLOSSIA.md` は、翻訳するファイル、翻訳済みファイルの配置先、対象言語、および結果に適用するコンテキストを Glossia に指示します。リポジトリには、ルートファイルと、サブディレクトリ内の追加のスコープ指定ファイルを配置できます。

## 構造

各ファイルは、次の 2 つの部分で構成されます。

1. `---` マーカーで囲まれた [YAML Ain't Markup Language](https://yaml.org/) フロントマター。
2. フロントマターの下にある、製品、対象読者、ボイス、またはドメインのコンテキストを記述した Markdown。

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

プロバイダーの認証情報は、`GLOSSIA.md` ではなく、必ずアカウント設定に保存します。任意の `model` 値は、アカウントのモデルハンドルです。

## フロントマターのフィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `source_language` | 文字列 | いいえ | このスコープのソースロケール。デフォルトは `en` です。 |
| `model` | 文字列 | いいえ | アカウントのモデルハンドル。省略した場合、Glossia はアカウントのデフォルトを使用します。明示的に指定したハンドルが存在しない場合は、エラーを報告します。 |
| `sources` | マップまたはリスト | トップレベルのルールでは必須 | ソースファイルのパターン。マップの値では出力テンプレートを定義できます。 |
| `targets` | マップまたはリスト | ソースが設定されている場合は必須 | 対象ロケールコード。マップでは、ロケールコードに言語名を関連付けられます。 |
| `output` | 文字列 | ソースマッピングまたは `target_path` で出力先が指定されていない場合は必須 | 出力ファイルのテンプレート。 |
| `target_path` | 文字列 | ソースマッピングまたは `output` で出力先が指定されていない場合は必須 | 翻訳済みファイルのベースディレクトリテンプレート。 |
| `translate` | リスト | いいえ | 複数の翻訳ルール。各ルールには、それぞれのソースと任意の上書き設定を指定できます。 |
| `exclude` | リスト | いいえ | スキップするファイルパターン。 |
| `preserve` | リスト | いいえ | プレースホルダーや Uniform Resource Locator など、変更せずに保持する必要があるコンテンツの種類。 |
| `frontmatter` | 文字列 | いいえ | デフォルトは `preserve`。または `translate`。 |
| `prompt` | 文字列 | いいえ | このスコープまたはルールに対する追加のガイダンス。 |
| `validation` | リスト | 組み込みアダプターがないファイル拡張子では必須 | 検証コマンドと、それに続く引数。コマンドは実際の出力先パスにある候補ファイルを受け取り、ファイルが無効な場合は 0 以外の終了ステータスを返す必要があります。 |
| `check_cmd` | 文字列 | いいえ | 翻訳ワークフローで使用できるチェックコマンド。 |
| `check_cmds` | マップ | いいえ | 翻訳ワークフローで使用できる、名前付きのチェックコマンド。 |
| `retries` | 整数 | いいえ | チェック失敗後の再試行回数。デフォルトは `2` です。 |
| `locale` | 文字列 | いいえ | ロケール固有のコンテキストファイルに関連付けるロケール。 |

不明なフロントマターのフィールドは無視されます。

## ファイル形式

Glossia は、Markdown、JavaScript Object Notation、YAML Ain't Markup Language、Portable Object、およびプレーンテキストファイルを組み込みで処理できます。その他のファイル拡張子は、該当する `GLOSSIA.md` で `validation` コマンドが宣言されていない限り、計画時に失敗します。これにより、独自の構造化形式が制約のないテキストとして暗黙的に扱われることを防ぎます。

検証コマンドは、候補ファイルが実際の出力先パスに一時的に書き込まれた後に実行されます。リポジトリ固有のパーサー、コンパイラー、またはビルドコマンドを呼び出すことができます。Glossia は検証を試行するたびに以前の出力先を復元し、承認された候補のみをその後に書き込みます。

## ソースマッピング

最も明確な形式では、各ソースパターンを出力テンプレートにマッピングします。

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースのリストも有効ですが、出力先を定義するには `output` または `target_path` が必要です。

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## ターゲット言語

リストでは、各ロケールコードを言語識別子として使用します。

```yaml
targets:
  - es
  - ja
```

マップでは、読みやすい言語名を追加できます。

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 出力変数

| 変数 | 値 |
|---|---|
| `{locale}` または `{lang}` | ターゲットロケールコード。 |
| `{relpath}` | 一致したパターンを基準とするソースパス。 |
| `{basename}` | 拡張子を除いたソースファイル名。 |
| `{ext}` | 先頭のドットを除いたソースファイルの拡張子。 |

## 複数のルール

コンテンツグループごとに異なる出力先やチェックが必要な場合は、`translate` を使用します。

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

ルールの値は、外側のファイルから継承された値を上書きします。

## スコープ付きコンテキスト

Glossia は、リポジトリのルートからソースファイルまでの階層にある `GLOSSIA.md` ファイルを読み込みます。

- 親の設定がデフォルト値を提供します。
- より深い階層のファイルが、そのディレクトリのフィールドを上書きします。
- Markdown コンテキストは親から子へ蓄積されます。
- ロケール固有のガイダンスとロケール固有のモデルハンドルは、`GLOSSIA/<locale>.md` に配置できます。

これにより、リポジトリのルートに全体的なボイスガイダンスを保持しながら、製品領域または言語に固有のガイダンスを、影響を受けるコンテンツの近くに配置できます。
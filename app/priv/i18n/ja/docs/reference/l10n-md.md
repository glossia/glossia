%{title: "L10N.md", summary: "リポジトリ翻訳の設定とコンテキストの参考", category: "参考", order: 1}
---
`L10N.md` Glossia に翻訳対象となるファイルの指定、翻訳済みファイルの配置先、対象言語、および結果を導くコンテキストを示します。リポジトリにはルートファイルと、サブディレクトリに配置されたスコープファイルを含めることができます。

## 構造

各ファイルには 2 つの部分组成されています：

1. [YAML はマークアップ言語ではない](https://yaml.org/) フロントマターは `---` マーカーの間にあります。
2. フロントマター以下の Markdown には、製品、対象者、トーン、またはドメインのコンテキストを含めることができます。

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

プロバイダの認証情報はアカウント設定に属し、決してファイルには含めないでください。 `L10N.md`. オプションの `model` 値はアカウントモデルハンドルです。

## フロントマターフィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `source_language` | 文字列 | なし | このスコープのソースロケール。デフォルトは `en`。 |
| `model` | text | no | アカウントモデルハンドル。Glossia では省略された場合、アカウントのデフォルトを使用し、明示的なハンドルが存在しない場合はエラーを報告します。|
| `sources` | マップまたはリスト | トップレベルルール用 | ソースファイルパターン。マップの値は出力テンプレートも定義できます。|
| `targets` | マップまたはリスト | ソースが設定されている場合 | ターゲットの領域コード。マップは、領域コードと言語名を関連付けることができます。|
| `output` | 文字列 | ソースマッピングがない場合、または `target_path` 出力先を指定します | 出力ファイルのテンプレート。 |
| `target_path` | 文字列 | ソースマッピングがない場合や `output` 出力先を指定します | 翻訳対象ファイルのベースディレクトリのテンプレート。 |
| `translate` | リスト | なし | 複数の翻訳ルール、それぞれ独自のソースとオプションの上書きを含む |
| `exclude` | リスト | なし | スキップするファイルパターン。 |
| `preserve` | リスト | なし | 変更不変のコンテンツ種類、例えばプレースホルダーや URI などのケースを含む。 |
| `frontmatter` | 文字列 | なし | `preserve` デフォルトでは、または `translate`。 |
| `prompt` | 文字列 | なし | このスコープまたはルールに対する追加ガイド。 |
| `validation` | list | 組み込みアダプターがないファイル拡張子向け | その引数を伴う検証コマンド。コマンドは実際のターゲットパスの候補を受け取り、ファイルが無効な場合は非ゼロのステータスを返す必要があります。 |
| `check_cmd` | string | no | 翻訳ワークフローで利用可能なチェックコマンド |
| `check_cmds` | map | no | 翻訳ワークフローで利用可能な名前付きチェックコマンド |
| `retries` | integer | no | 失敗したチェック後のリトライ試行回数。デフォルトは `2`. |
| `locale` | string | no | ロケール 特定コンテキストファイルに関連付け。|

不明なフロントマターフィールドは無視されます。

## ファイル形式

Glossia は Markdown、JavaScript Object Notation、YAML Ain't Markup Language、portable object および plain text ファイルのネイティブ処理を内蔵しています。他のファイル拡張子は、計画には失敗しますが、対応する `L10N.md` 宣言する `validation` コマンド。これにより、固有の構造化形式を非制限のテキストとして静かに扱うことを防ぎます。

バリデーションコマンドは、候補を一時的に実際のターゲットパスに書き込んだ後に実行します。リポジトリのネイティブパーサー、コンパイラ、またはビルドコマンドを呼び出すことができます。Glossia は各バリデーション試行後に以前のターゲットを復元し、その後、受け入れられた候補のみを書き込みます。

## ソースマッピング

最も明確な形式では、すべてのソースパターンを出力テンプレートにマッピングします：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースリストも有効ですが、これには `output` または `target_path` 宛先を定義するために：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## ターゲット言語

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
| `{locale}` または `{lang}` | ターゲットロケールコード。 |
| `{relpath}` | 一致パターンに対する相対ソースパス。 |
| `{basename}` | 拡張子を含まないソースファイル名。 |
| `{ext}` | 先頭ドットを除くソースファイル拡張子。 |

## 複数のルール

使用 `translate` 異なるコンテンツグループが異なる宛先またはチェックを必要とする場合：

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

ルール値は、周囲のファイルから継承された値を上書きします。

## スコープ付きコンテキスト

Glossia は読み取ります `L10N.md` リポジトリのルートからソースファイルに向かってのファイル：

- 親設定はデフォルト値を提供します。
- より深いファイルは、そのディレクトリのフィールドを上書きします。
- Markdown コンテキストは親から子へ継承されます。
- ロケール固有のガイダンスとモデル・ハンドルは以下に置けます `L10N/<locale>.md`.

これにより、リポジトリはルートに広範なトーンガイダンスを維持しつつ、製品領域または言語固有のガイダンスを影響するコンテンツの近くに配置できます。
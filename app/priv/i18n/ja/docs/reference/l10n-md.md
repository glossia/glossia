%{
  title: "L10N.md",
  summary: "リポジトリ翻訳設定およびコンテキストに関するリファレンス。",
  category: "リファレンス",
  section: "translation",
  order: 1
}
---
`L10N.md` Glossia にどのファイルを翻訳するか、翻訳済みのファイルの配置場所、対象言語、および結果を導くコンテキストを示します。リポジトリにはルートファイルと、サブディレクトリ内の追加のスコープファイルが含まれることができます。

## 構造

各ファイルには以下の 2 つの部分があります:

1. [YAML はマークアップ言語ではありません](https://yaml.org/) マーカーの間の `---` マーカー。
2. フロントマターの下の Markdown には、製品、ターゲット、ボイス、またはドメインのコンテキストが含まれます。

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

プロバイダーの認証情報はアカウント設定に格納され、決して `L10N.md`. オプションの `model` 値はアカウントモデルハンドルです。

## フロントマターフィールド

| フィールド | タイプ | 必須 | 説明 |
|---|---|---|---|
| `source_language` | 文字列 | 不要 | このスコープのソースロケール。デフォルトは `en`. |
| `model` | string | 非必須 | アカウントモデルハンドル。Glossia は省略されたときにアカウントのデフォルトを使用し、明示的なハンドルが存在しない場合はエラーを報告します。|
| `sources` | map or list | トップレベルのルールの場合 | ソースファイルのパターン。マップの値は出力テンプレートを定義できます。|
| `targets` | map or list | ソースが設定されている場合 | ターゲットローケルコード。マップはローケルコードを言語名に関連付けることができます。|
| `output` | string | ソースマッピングがない場合、または `target_path` 出力先を指定 | 出力ファイルのテンプレート。 |
| `target_path` | 文字列 | ソースマッピングがない場合、または `output` 出力先を指定 | 翻訳ファイルのベースディレクトリのテンプレート。 |
| `translate` | リスト | なし | 複数の翻訳ルール、それぞれに独自のソースとオプションの上書きを持つ。 |
| `exclude` | リスト | なし | スキップするファイルパターン。 |
| `preserve` | list | no | 変更すべきでないコンテンツの種類、例えばプレースホルダーまたは URI。 |
| `frontmatter` | string | no | `preserve` デフォルトでは、または `translate`。 |
| `prompt` | string | no | このスコープまたは規則に関する追加のガイダンス。 |
| `validation` | list | ビルドはなないファイル拡張子 | その引数付きの検証コマンドである。コマンドは、実際のターゲットパスにある検証候補を受け取り、ファイルが無効な場合は 0 以外のステータスを返す必要があります。 |
| `check_cmd` | string | no | 翻訳ワークフローで利用可能なチェックコマンドです。 |
| `check_cmds` | map | no | 翻訳ワークフローで利用可能な名付きチェックコマンドです。 |
| `retries` | integer | no | チェック失敗後の再試行回数を示します。デフォルトは `2`. |
| `locale` | string | no | ロケール固有のコンテキストファイルに紐付いたロケール。|
| `glossary` | list または map | no | 内 `L10N.md`, glossary の用語のリスト。内 `L10N/<locale>.md`, 各用語からその言語への翻訳へのマップ。ネストされたファイルを追加し、継承されたエントリを上書きする。ご [glossary 参照](/docs/reference/glossary). |

不明な frontmatter フィールドは無視されます。

## ファイル形式

Glossia は Markdown、JavaScript Object Notation、YAML Ain't Markup Language、 portable object および plain text ファイルのサポートを内蔵しています。他のファイル拡張子は、対応する `L10N.md` を宣言する `validation` コマンド。これにより、独自の構造化フォーマットが無制約なテキストとして静かに扱われることを回避します。

Markdown 内では、翻訳されるのは文章のみです：パラグラフ、見出し、リストアイテム、テーブルセル、 `title`, `details`再構成されたドキュメントが以前検証に失敗しました：Markdown テキスト文字列の復元は、同じ長さを持つ JSON 文字列配列を返す必要があります `alt`再構成ドキュメントが以前検証に失敗しました：マークダウンテキストリテラルの復元で無効な JSON が返されました。 `label`, `description`, `summary`, `placeholder`, `aria-label`,と、 `caption` コンポーネントや HTML の属性、HTML のテキスト `<summary>`。残りのすべてのバイト、コード、リンク先、コンポーネント、アラート、および明示的なヘッダーアンカーは、ソースと全く同じまま保持されます。参照 [翻訳の回復](/docs/explanation/translation-recovery) この仕組みについては。

検証コマンドは、候補が実際のターゲットパスに一時的に書き込まれた後に実行されます。リポジトリ固有のネイティブパーサー、コンパイラ、またはビルドコマンドを呼び出すことができます。Glossia は各検証試行後に以前のターゲットを復元し、その後、承認された候補のみを書き込みます。

## ソースマッピング

最も明確な形式は、各ソースパターンを出力テンプレートにマッピングします：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースリストも有効ですが、宛先を定義するには `output` または `target_path` が必要です：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## ターゲット言語

リストでは、各ローカライズコードを言語識別子として使用します：

```yaml
targets:
  - es
  - ja
```

マップでは、読みやすい言語名を追加できます：

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 出力変数

| 変数 | 値 |
|---|---|
| `{locale}` or `{lang}` | ターゲットローカライズコード。 |
| `{relpath}` | マッチしたパターンの相対パスからのソースパス。 |
| `{basename}` | 拡張子を除くソースファイル名。 |
| `{ext}` | 先頭ドットを除くファイル拡張子。 |

## 複数のルール

異なるコンテンツグループが異なる宛先または検証を必要とする場合、`translate` を使用します：

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

Glossia はリポジトリルートからソースファイルへ向かって `L10N.md` ファイルを読み取ります：

- 親設定がデフォルトを提供します。
- 深いファイルは、そのディレクトリのフィールドを上書きします。
- マークダウンコンテキストは親から子に順次蓄積されます。
- 言語固有のガイダンスと、言語固有のモデルハンドラは `L10N/<locale>.md` に存在できます。

これにより、リポジトリはルートに広範な声のガイダンスを維持しつつ、製品領域または言語固有のガイダンスを影響するコンテンツに配置できます。
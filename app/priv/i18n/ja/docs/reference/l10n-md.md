%{
  title: "L10N.md",
  summary: "リポジトリの翻訳設定とコンテキストの参照",
  category: "参照",
  section: "translation",
  order: 1
}
---
`L10N.md` Glossia に翻訳対象となるファイルを指定し、翻訳後のファイルの配置先、対象言語、および結果を導くべきコンテキストを伝えます。リポジトリにはルートファイルと、サブディレクトリにある追加のスコープファイルを含めることができます。

## 構造

各ファイルには以下の 2 つの部分があります：

1. [YAML はマークアップ言語ではありません](https://yaml.org/) マーカー間のフロントマター `---` マーカー。
2. フロントマター以降の Markdown は、製品、読者、トーン、またはドメインのコンテキストを含みます。

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

プロバイダー認証情報はアカウント設定に含まれ、決して `L10N.md`. オプション `model` 値はアカウントモデルのハンドルです。

## フロントマター フィールド

| フィールド | タイプ | 必須 | 説明 |
|---|---|---|---|
| `source_language` | string | no | このスコープのソースローカルの設定。デフォルトは `en`。 |
| `model` | 文字列 | なし | アカウントモデルハンドル。Glossia は省略された場合はアカウントのデフォルトを使用し、明示的なハンドルが存在しない場合はエラーを報告します。 |
| `sources` | マップまたはリスト | トップレベルのルールで | ソースファイルパターン。マップ値は出力テンプレートを定義できます。 |
| `targets` | map 一覧｜sources 構成時時点｜ターゲットローカルコード。map でローカルコードと言語名を紐付ける。 |
| `output` | string｜source 配信時 konsisten `target_path` 指定する出力先 | 出力ファイルのテンプレート。 |
| `target_path` | 文字列 | ソースマッピングがない場合、または `output` 指定する出力先 | 翻訳済みファイルのベースディレクトリテンプレート。 |
| `translate` | リスト | なし | 複数の翻訳ルール、それぞれ独自のソースとオプションの上書き設定。 |
| `exclude` | リスト | なし | スキップするファイルパターン。 |
| `preserve` | リスト | いいえ | 不変に保たれる必要があるコンテンツの種類、プレースホルダーや統一リソースロケータなど。 |
| `frontmatter` | ストリング | いいえ | `preserve` デフォルトでは、または `translate`。 |
| `prompt` | ストリング | いいえ | このスコープまたはルールに関する追加のガイダンス。 |
| `validation` | リスト | 組み込みアダプターを持たないファイル拡張子 | その後に引数が続く検証コマンド。コマンドは、実際のターゲットパスにある候補を受け取り、ファイルが無効な場合、ゼロ以外のステータスを返す必要があります。 |
| `check_cmd` | 文字列 | なし | 翻訳ワークフローで使用可能なチェックコマンド。 |
| `check_cmds` | マップ | なし | 翻訳ワークフローで使用可能な名前付きチェックコマンド。 |
| `retries` | 整数 | なし | チェック失敗後のリトライ試行回数。デフォルトは `2`. |
| `locale` | string | no | 特定ロケール向けコンテキストファイルに付与された。 |
| `glossary` | list or map | no | 〜内 `L10N.md`, glossary 用語リスト。〜内 `L10N/<locale>.md`, 各用語とその言語での翻訳へのマッピング。ネストされたファイルは継承エントリを追加し上書きします。詳細は [glossary リファレンス](/docs/reference/glossary). |

不明なフロントマターフィールドは無視されます。

## ファイル形式

Glossia には Markdown、JavaScript Object Notation、YAML Ain't Markup Language、portable object および 平文テキストファイルのネイティブ対応があります。他のファイル拡張子は、計画に失敗する、該当する `L10N.md` 宣言する `validation` コマンド。これにより、専用構造化フォーマットを制約のないテキストとして静かに処理するのを防ぎます。

検証コマンドは、候補が実際のターゲットパスに一時的に書き込まれた後に実行されます。リポジトリのネイティブパーサー、コンパイラ、またはビルドコマンドを呼び出すことができます。Glossia は各検証試行後に以前のターゲットを復元し、承認された候補のみその後書き込みます。

## ソースマッピング

最も明確な形式は、各ソースパターンを出力テンプレートにマッピングします：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースリストも有効ですが、宛先を定義するには `output` または `target_path` が必要です。

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## ターゲット言語

リストは各ローカールコードを言語識別子として使用します。

```yaml
targets:
  - es
  - ja
```

マップは読みやすい言語名を追加できます：

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 出力変数

| 変数 | 値 |
|---|---|
| `{locale}` または `{lang}` | ターゲットのローカールコード。 |
| `{relpath}` | 一致パターンの相対パス。 |
| `{basename}` | 拡張子なしのソースファイル名。 |
| `{ext}` | 先頭のドットなしのファイル拡張子。 |

## 複数の規則

異なるコンテンツグループが異なる宛先またはチェックを必要とする場合は `translate` を使用します：

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

ルール値は周囲のファイルから継承される値を上書きします。

## スコープ付きコンテキスト

Glossia はリポジトリのルートからソースファイルに向かって `L10N.md` ファイルを読み取ります：

- 親設定はデフォルト値を提供します。
- より深いファイルは、そのディレクトリのフィールドを上書きします。
- マークダウンのコンテキストは親から子へ累積されます。
- ロカル特定ガイダンスとロカル特定モデルハンドラは `L10N/<locale>.md` にあることができます。

これにより、リポジトリはルートに幅広いトーンガイダンスを維持しつつ、影響するコンテンツに近い位置に製品領域または言語固有のガイダンスを配置できます。
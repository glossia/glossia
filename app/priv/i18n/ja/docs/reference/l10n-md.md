%{
  title: "L10N.md",
  summary: "リポジトリの翻訳設定とコンテキストの参照",
  category: "参照",
  section: "translation",
  order: 1
}
---
`L10N.md` は Glossia に、翻訳すべきファイルがどこにあるか、翻訳されたファイルがどこに置かれるか、ターゲット言語は何か、そして結果を導くコンテキストは何かを示します。リポジトリにはルートファイルとサブディレクトリに含まれる追加のスコープ付きファイルを持つことができます。

## 構造

各ファイルは 2 つの部分で構成されています：

1. [YAML Ain't Markup Language](https://yaml.org/) の `---` マーカー間の frontmatter。
2. フロントマター以降の Markdown で、製品、ターゲット、ボイス、またはドメインのコンテキストが記載されています。

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

プロバイダーの認証情報はアカウント設定に含まれます。決して `L10N.md` には含めないでください。オプションの `model` 値はアカウントモデルハンドルです。

## フロントマターフィールド

| フィールド | タイプ | 必須 | 説明 |
|---|---|---|---|
| `source_language` | string | 不要 | このスコープのソースローカルです。デフォルトは `en` です。 |
| `model` | string | 不要 | アカウントモデルハンドルです。省略された場合はアカウントのデフォルトが使用され、明示的なハンドルが存在しない場合はエラーが報告されます。 |
| `sources` | map or list | トップレベルのルールのみ | ソースファイルパターンです。マップ値は出力テンプレートを定義できます。 |
| `targets` | map or list | ソースが設定されている場合 | ターゲットローカルコードです。マップはロケールコードと言語名を関連付けることができます。 |
| `output` | string | ソースマッピングがない場合または `target_path` が渡す先を提供しない場合 | 出力ファイルテンプレートです。 |
| `target_path` | string | ソースマッピングがない場合または `output` が渡す先を提供しない場合 | 翻訳されたファイルのベースディレクトリテンプレートです。 |
| `translate` | list | 不要 | 複数の翻訳ルールです。それぞれは独自のソースとオプションのオーバーライドを持ちます。 |
| `exclude` | list | 不要 | スキップするファイルパターンです。 |
| `preserve` | list | 不要 | 変更なしで維持すべきコンテンツの種類です。プレースホルダーや URL など。 |
| `frontmatter` | string | 不要 | デフォルトは `preserve`、または `translate` です。 |
| `prompt` | string | 不要 | このスコープまたはルールの追加ガイドです。 |
| `validation` | list | ビルトインアダプタがないファイル拡張子の場合 | 検証コマンドとその引数です。コマンドは候補を本来のターゲットパスで受け取り、ファイルが無効な場合はゼロ以外のステータスを返す必要があります。 |
| `check_cmd` | string | 不要 | 翻訳ワークフローで利用可能なチェックコマンドです。 |
| `check_cmds` | map | 不要 | 翻訳ワークフローで利用可能な命名チェックコマンドです。 |
| `retries` | integer | 不要 | チェック失敗後の再試行回数です。デフォルトは `2` です。 |
| `locale` | string | 不要 | ローカル専用コンテキストファイルに付けられるローカルです。 |
| `glossary` | list or map | 不要 | `L10N.md` では用語リスト。`L10N/<locale>.md` では、用語とその言語翻訳のマップ。ネストされたファイルは追加し継承されたエントリをオーバーライドします。[用語参照](/docs/reference/glossary) を参照してください。 |

不明なフロントマターフィールドは無視されます。

## ファイル形式

Glossia は Markdown、JavaScript Object Notation、YAML Ain't Markup Language、ポータブルオブジェクト、およびプレーンテキストファイルに対してビルトインの処理を実行します。適応する `L10N.md` が `validation` コマンドを宣言しない限り、他のファイル拡張子は計画段階で失敗します。これにより、プロプライエタリな構造化フォーマットが制限されていないテキストとして静かに扱われることが防ぎます。

検証コマンドは、候補が実際にターゲットパスに一時的に書き込まれた後に実行されます。これはリポジトリのネイティブパーサー、コンパイラ、またはビルドコマンドを呼び出すことができます。Glossia は各検証試行の後以前のターゲットを復元し、その後だけ承認された候補を書き込みます。

## ソースマッピング

最も明確な形式は、すべてのソースパターンを出力テンプレートにマッピングします：

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

## 対象言語

リストでは、各ロケールコードを言語識別子として使用します：

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
| `{locale}` または `{lang}` | 対象ロケールコード。 |
| `{relpath}` | 一致したパターンに対するソースパス（相対）。 |
| `{basename}` | 拡張子を含まないソースファイル名。 |
| `{ext}` | 点で始まるソースファイル拡張子。 |

## 複数のルール

異なるコンテンツグループが異なる宛先またはチェックを必要とする場合に `translate` を使用します：

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

Glossia は、レポジトリのルートからソースファイルに向かって `L10N.md` ファイルを読み進めます：

- 親設定がデフォルトを提供します。
- より深いファイルは、そのディレクトリのフィールドを上書きします。
- Markdown コンテキストは、親から子へ累積されます。
- ロケール固有のガイダンスとロケール固有のモデルハンドラは `L10N/<locale>.md` に配置できます。

これにより、レポジトリがルートに包括的なトーンガイダンスを残しつつ、影響を与えるコンテンツに近い位置に製品領域または言語固有のガイダンスを配置できるようになります。
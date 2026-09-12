%{title: "L10N.md", summary: "リポジトリ翻訳の設定とコンテキストに関する参考資料", category: "reference", order: 1}
---
`L10N.md` Glossia に翻訳対象のファイルを指定し、翻訳ファイルの配置先、対象言語、および結果を導くコンテキストを示します。リポジトリにはルートファイルと、サブディレクトリに追加のスコープ付きファイルを持つことができます。

## 構成

各ファイルには 2 つのパートがあります：

1. [YAML はマークアップ言語ではありません](https://yaml.org/) マーカーの間のフロントマター `---` マーカー。
2. フロントマターの直下に、製品、オーディエンス、トーン、またはドメインのコンテキストを含む Markdown を記述します。

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

プロバイダの認証情報はアカウント設定に格納され、決して `L10N.md`. オプションの `model` 値はアカウントモデルのハンドルです。

## フロントマター フィールド

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `source_language` | string | なし | このスコープのソース・ローカルです。デフォルトは `en`. |
| `model` | string | なし | アカウントモデルハンドル。Glossia は省略時にアカウントのデフォルトを使用し、明示的なハンドルが存在しない場合はエラーを報告します。 |
| `sources` | map or list | 上位ルール | ソースファイルパターン。マップ値は出力テンプレートに定義できます。 |
| `targets` | map or list | ソース設定時 | ターゲットロケールコード。マップはロケールコードを言語名に関連付けることができます。 |
| `output` | string | ソースマッピングがない場合、または `target_path` 宛先を指定 | 出力ファイル テンプレート。 |
| `target_path` | 文字列 | ソースマッピングがない場合 または `output` 宛先を指定 | 翻訳結果ファイルのベースディレクトリ テンプレート。 |
| `translate` | リスト | なし | それぞれ独自のソースとオプションのオーバーライドを持つ複数の翻訳ルール。 |
| `exclude` | リスト | なし | スキップするファイルパターン。 |
| `preserve` | list | no | 変更しない必要があるコンテンツの種類（プレースホルダーまたは URI などの）。|
| `frontmatter` | string | no | `preserve` デフォルト、または、 `translate`. |
| `prompt` | string | no | このスコープまたはルールに関する追加ガイダンス。|
| `validation` | リスト | ビルトインアダプタがないファイル拡張子向け | 引数付き検証コマンドです。このコマンドは候補を実際のターゲットパスで受け取り、ファイルが無効な場合は非ゼロステータスを返す必要があります。 |
| `check_cmd` | 文字列 | いいえ | 翻訳ワークフローで利用可能なチェックコマンドです。 |
| `check_cmds` | マップ | いいえ | 翻訳ワークフローで利用可能な名前付きチェックコマンドです。 |
| `retries` | 整数 | いいえ | 失敗したチェック後の再試行回数。デフォルト値は `2`. |
| `locale` | 文字列 | なし | 特定のコンテキストファイルに付随するロケール。 |

不明な frontmatter フィールドは無視されます。

## ファイル形式

Glossia には、Markdown、JavaScript Object Notation、YAML Ain't Markup Language、ポータブルオブジェクト、およびプレーンテキストファイルの組み込み対応があります。その他のファイル拡張子は、計画が失敗します。適用される `L10N.md` 宣言する。 `validation` コマンド。これにより、専用形式が無制約テキストとして扱われることを避けます。

検証コマンドは、候補を一時的に実際のターゲットパスに書き込んだ後に実行されます。リポジトリのネイティブのパース、コンパイラ、またはビルドコマンドを呼び出すこともできます。各検証試行後、Glossia は以前のターゲットを復元し、受け入れられた候補だけをその後書き込みます。

## ソースマッピング

最も明確な形式では、すべてのソースパターンを出力テンプレートにマッピングします：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースリストも有効ですが、これを定義するには `output` または `target_path` 宛先を定義するには：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 対象言語

リストは各ロケールコードを言語識別子として使用します：

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
| `{locale}` or `{lang}` | 対象のロケールコード。 |
| `{relpath}` | 一致パターンに対するソースパス（相対）。 |
| `{basename}` | 拡張子なしのソースファイル名。 |
| `{ext}` | 先頭のドットを含まない拡張子。 |

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

ルール値は周囲のファイルから継承された値を上書きします。

## スコープ付きのコンテキスト

Glossia はリポジトリのルートからソースファイルに向けて `L10N.md` ファイルを読み取ります：

- 親設定はデフォルト値を提供します。
- より深いファイルは、そのディレクトリのフィールドを上書きします。
- Markdown コンテキストは親から子に蓄積されます。
- ロケール固有のガイダンスおよびロケール固有のモデルハンドラーは `L10N/<locale>.md` に存在できます。

これにより、リポジトリはルートに広範なボイスガイダンスを保持しつつ、影響するコンテンツに近づけて製品エリアまたはロケール固有のガイダンスを配置できます。
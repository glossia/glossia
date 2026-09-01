%{title: "GLOSSIA.md", summary: "リポジトリ翻訳設定とコンテキストの参考資料。", category: "参考", order: 1}
---
`GLOSSIA.md` 翻訳する対象ファイル、翻訳ファイルへの配置場所、ターゲット言語、および結果をガイドするコンテキストを指定します。リポジトリにはルートファイルとサブディレクトリ内の追加の scoped ファイルを含めることができます。

## 構造

各ファイルには 2 つの部分があります、

1. [YAML はマークアップ言語ではありません](https://yaml.org/) マーカー間の frontmatter `---` マーカー。
2. frontmatter 以下の製品、オーディエンス、ボイス、またはドメインのコンテキストを含む Markdown

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

プロバイダーの認証情報はアカウント設定に保存し、決して `GLOSSIA.md`. `model` The optional の値はアカウントモデルハンドルです。

## Frontmatter の項目

| 項目 | 型 | 必須 | 説明 |
|---|---|---|---|
| `source_language` | 文字列 | 非必須 | このスコープのソースローカル。デフォルトは `en`。 |
| `model` | 文字列 | 非必須 | アカウントモデルハンドル。Glossia は省略時にデフォルトを使用し、明示的なハンドルが存在しない場合はエラーを報告します。 |
| `sources` | マップまたはリスト | トップレベルルールで | ソースファイルパターン。マップ値は出力テンプレートに定義できます。 |
| `targets` | マップまたはリスト | ソースが設定されている場合 | ターゲットローカルコード。マップはローカルコードを言語名に関連付けることができます。 |
| `output` | 文字列 | ソースマッピングがない場合または `target_path` 出力先を指定する | 出力ファイルのテンプレート。|
| `target_path` | string | ソースマッピングがない場合、または `output` 出力先を指定する | 翻訳されたファイルのベースディレクトリのテンプレート。|
| `translate` | list | no | 複数の翻訳規則、それぞれに独自のソースとオプションのオーバーライド付き。|
| `exclude` | list | no | スキップするファイルパターン。|
| `preserve` | list | no | 変更せずに残すべきコンテンツの種類、例えばプレースホルダーまたは統一リソース識別子。|
| `frontmatter` string | no | `preserve` デフォルトの場合、または `translate`. |
| `prompt` | string | no | このスコープまたはルールに関する追加ガイダンス。|
| `validation` | list | ビルトインアダプターのないファイル拡張子 | 検証コマンドとその引数。コマンドは実際のターゲットパスで候補を受け取り、ファイルが無効な場合は非ゼロステータスを返す。|
| `check_cmd` | string | no | 翻訳ワークフローで使用可能なチェックコマンド。|
| `check_cmds` | map | no | 翻訳ワークフローで使用可能な命名されたチェックコマンド。|
| `retries` | integer | no | チェック失敗後のリトライ試行数。デフォルトは `2`. |
| `locale` | string | no | ロケール固有のコンテキストファイルに関連する。|

不明な frontmatter フィールドは無視されます。

## ファイル形式

Glossia は Markdown、JavaScript Object Notation、YAML Ain't Markup Language、ポータブルオブジェクト、および平文テキストファイルのハンドリング機能を標準で備えています。他のファイル拡張子は、適用可能な `GLOSSIA.md` 宣言する、 `validation` コマンドです。これにより、専用の構造化形式が制約のないテキストとして静々地扱いされることを避けることができます。

検証コマンドは、候補が一時的に実際のターゲットパスに書き込まれた後に実行されます。それはリポジトリのネイティブパーサー、コンパイラ、またはビルドコマンドを呼び出すことができます。Glossia は各検証試行後に以前のターゲットを回復し、その後の書き込みではのみ受け入れられた候補を書きます。

## ソースマッピング

最も明確な形式は、すべてのソースパターンを出力テンプレートにマップします：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースリストも有効ですが、それを `output` または `target_path` 目的地を定義するには：

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

マップでは読みやすい言語名を追加できます：

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 出力変数

| 変数 | 値 |
|---|---|
 | `{locale}` or `{lang}` | ターゲットローカルコード。 |
| `{relpath}` | 一致したパターンに対するソースパス。 |
| `{basename}` | 拡張子を含まないソースファイル名。 |
| `{ext}` | リーディングドットを外したソースファイル拡張子。 |

## 複数のルール

異なるコンテンツグループが異なる先送り地点またはチェックを必要とする場合は `translate` を使用してください：

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

 ルール値は周辺ファイルから継承された値を凌駕します。

##  範囲付きコンテキスト 

Glossia は`GLOSSIA.md` レポジトリルートからソースファイルに向かってファイルを読み取ります：

- 親設定はデフォルト値を提供します。
- より深いファイルはそのディレクトリのフィールドを上書きします。
- Markdown コンテキストは親から子に蓄積されます。
- ロケール固有のガイダンスとロケール固有のモデルハンドラーは `GLOSSIA/<locale>.md` に存在できます。

これにより、レポジトリはルートで広範なトーンガイダンスを維持しながら、影響するコンテンツに近い位置に製品領域やロケール固有のガイダンスを配置できます。
%{title: "L10N.md", summary: "リポジトリ翻訳の設定と文脈に関する参照", category: "参照", order: 1}
---
`L10N.md` Glossia に翻訳するファイルを指定し、翻訳ファイルの保存場所、対象言語、結果を導くコンテキストを定義します。リポジトリにはルートファイルと、サブディレクトリ内の追加のスコープファイルを含むことができます。

## 構造

各ファイルには 2 つの部分があります：

1. [YAML はマークアップ言語ではありません](https://yaml.org/) frontmatter は `---` マーカーの間に配置されます。
2. フロントマターの後に配置する Markdown で、製品、対象読者、トーン、またはドメインのコンテキストを含みます。

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

プロバイダー認証情報はアカウント設定にあるべきで、決してファイル内に含まれてはいけません。 `L10N.md`。オプションの `model` 値はアカウントモデルのハンドルです。

## フロントマターフィールド

| フィールド | タイプ | 必須 | 説明 |
|---|---|---|---|
| `source_language` | 文字列 | 不要 | このスコープのソースロケール。デフォルトは `en`。 |
| `model` | 文字列 | なし | アカウントモデルハンドル。Glossia は省略された場合はデフォルトのアカウントを使用し、明示的なハンドルが存在しない場合はエラーを報告します。|
| `sources` | マップまたはリスト | トップレベルのルール | ソースファイルパターン。マップ値は出力テンプレートを定義できます。|
| `targets` | マップまたはリスト | ソースが構成されている場合 | ターゲットロケールコード。マップはロケールコードを言語名に関連付けることができます。|
| `output` | 文字列 | ソースマッピングがない場合または `target_path` 出力先を指定する | 出力ファイルテンプレート。 |
| `target_path` | string | ソースマッピングがない場合、または `output` 出力先を指定する | 翻訳済みファイル用の基本ディレクトリテンプレート。 |
| `translate` | list | no | 複数の翻訳ルールは、それぞれ独自のソースとオプションのオーバーライドを持つ。 |
| `exclude` | list | no | スキップするファイルパターン。 |
| `preserve` | list | no | 変更できないコンテンツの種別、プレースホルダーや URI など。|
| `frontmatter` | string | no | `preserve` 既定で、または `translate`。|
| `prompt` | string | no | このスコープまたはルールへの追加ガイダンス。|
| `validation` | リスト | ビルドインアダプタがないファイル拡張子用 | その引数と共に実行される検証コマンド。コマンドは実際のターゲットパスにある候補を受け取り、ファイルが無効な場合はゼロ以外のステータスを返す必要があります。 |
| `check_cmd` | 文字列 | なし | 翻訳ワークフローで使用可能なチェックコマンド。 |
| `check_cmds` | マップ | なし | 翻訳ワークフローで使用可能な名前付きチェックコマンド。 |
| `retries` | 整数 | なし | チェック失敗後の再試行回数。デフォルトは `2`. |
| `locale` | string | no | ローケール固有のコンテキストファイルに付随する |

未知のフロントマターフィールドは無視されます。

## ファイル形式

Glossia は Markdown、JavaScript Object Notation、YAML Ain't Markup Language、portable object、および plain text ファイルの組み込み処理に対応しています。他のファイル拡張子は、処理計画に失敗し、該当する `L10N.md` 宣言する `validation` コマンド。これにより、固有の構造化形式を、無言で制約のないテキストとして扱うことを避けます。

検証コマンドは、候補が本物のターゲットパスに一時的に書き込まれた後に実行されます。リポジトリのネイティブパーサー、コンパイラ、またはビルドコマンドを呼び出すことが可能です。Glossia は各検証試行の後、前のターゲットを復元し、受け入れられた候補のみその後書き込まれます。

## Source mappings

最も明確な形式は、各ソースパターンを出力テンプレートにマッピングします:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

ソースリストも有効ですが、それには `output` または `target_path` に定義する必要があります:

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
| `{relpath}` | 一致パターンの相対ソースパス。 |
| `{basename}` | 拡張子を含まないソースファイル名。 |
| `{ext}` | 先頭ドットを含まないファイル拡張子。 |

## 複数のルール

使用 `translate` 異なるコンテンツグループが異なる宛先またはチェックを必要とする場合:

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

## スコープ付きのコンテキスト

Glossia は `L10N.md` ファイルは リポジトリのルートからソースファイルの方へ

- 親設定はデフォルト値を提供します。
- より深いファイルは、そのディレクトリのフィールドを上書きします。
- Markdown のコンテキストは親から子へ蓄積されます。
- ロケール固有のガイダンスとロケール固有のモデルハンドラはこれに格納できます `L10N/<locale>.md`.

これにより、リポジトリが根本に広範な声のガイダンスを保持しつつ、影響するコンテンツに近い位置に製品領域や言語固有のガイダンスを配置することを可能にします。
%{
  title: "用語集",
  summary: "L10N.md および各言語の上書きファイル内の用語集フィールドに関する参照。",
  category: "参照",
  section: "翻訳",
  order: 2
}
---
リポジトリの用語集は 2 つのファイルに分割されています。Glossia は、翻訳する各ファイルに対してアカウントのサーバー用語集とこれを統合します。統合方法については、 [用語集](/docs/explanation/glossary) この 2 つがどのように統合されるかをご覧ください。

| ファイル | `glossary` 含む | 例 |
|---|---|---|
| `L10N.md` | 用語集の一覧 **用語**, 全ての言語で同様です。| `- source: commit` |
| `L10N/<locale>.md` | 用語の **翻訳** への対応です。| `commit: commit` |

## L10N.md の用語定義

```yaml
---
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
  - id: vcs-branch
    source: branch
    definition: A line of development in version control.
---
```

| フィールド | タイプ | 必須 | 説明 |
|---|---|---|
| `source` | string | はい | ソーステキストに表示される用語です。 |
| `definition` | string | いいえ | モデルが読み取り、一致が本当にこの概念かどうかを判断するための短いガイドです。 |
| `case_sensitive` | boolean | no | 場合、 `true`, 用語は正確なケースの場合のみ一致します。デフォルトは `false`。 これは名称や略語などの `API` または `SDK`。|
| `id` | string | no | 安定識別子。 由来 `source` 省略時(`Version Control` なります `version-control`, `C++` なります `cplusplus`. ID による翻訳を設定し、改名するには `source` 用語のアイデンティティを失わずに、または親から用語を上書きする `L10N.md`. |

用語は翻訳を持ちません。用語に `targets` フィールドが含まれる場合、却下されます：翻訳は言語ファイルに含まれます。

## L10N/ 内の翻訳<locale>.md

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
  vcs-branch: rama
  pull request: pull request
---
```

各キーは用語の `id` またはその `source`, またそれぞれの値は、その言語の承認翻訳となります。

- この言語内の用語に一致しないキーは `L10N.md` この言語にのみ用語を宣言します。
- その言語内にある翻訳がない用語は、その言語のサーバー用語集にフォールバックします。
- 名前を翻訳せずに保つには、その自身にマッピングします。例えば `Glossia: Glossia`.

## ネストされたファイル

各ファイルは、そのディレクトリチェーンの用語書を使って翻訳されます:

- ネストされた `L10N.md` 用語を継承したものに加え、同じ `id`、または、同じ `source` 指定がない場合 `id` 設定済みの場合、その子ツリー内の継承されたものから置換されます。
- ネストされた `L10N/<locale>.md` 継承翻訳に追加され、両者が宣言する項では自方の翻訳が優先されます。

## 検証

用語集が無効な場合、Glossia は影響されたファイルをサーバー用語集のみで翻訳するため、タイプミスは翻訳をブロックしません。主な原因：

- **欠落 `source`.** 各用語には空でないものが必要です。
- **重複 `id`.** すべての用語は、明示的に設定されたか、導出されたかに関わらず、一意の識別子に解決する必要がある `source`.
- **L10N.md の翻訳。** 用語の `targets`. 翻訳を以下に `L10N/<locale>.md`.
- **空の翻訳。** 空文字列にマッピングされた用語です。代わりに除外してください。
- **形状またはタイプが正しくありません。** `glossary` にリストである必要があります `L10N.md` のマップである必要があります `L10N/<locale>.md`. 翻訳、 `id`, かつ `definition` 文字列である必要があります; `case_sensitive` でなければならない `true` または `false`.

## Glossia が記録します

各変換済みファイルのロックファイルは、それを構成した用語集のエントリを記録します:

```json
{
  "server_context": {
    "glossary": {
      "applied": ["repo:commit", "account:repository"],
      "shadowed": ["account:commit"]
    }
  }
}
```

- `applied` マッチしたエントリをリストします。リポジトリのエントリは以下のように表示されます `repo:<id>`, サーバーのエントリは `account:<id>`.
- `shadowed` このファイルでリポジトリエントリによって置換されたサーバーエントリをリストします。

用語または翻訳を編集すると、それを使用するファイルだけが再翻訳されます。

## 関連項目

- [用語集を定義する](/docs/how-to/define-a-glossary): ステップバイステップガイド。
- [用語集](/docs/explanation/glossary): リポジトリとサーバー用語集が統合される方法。
- [L10N.md 参照](/docs/reference/l10n-md): その他の frontmatter 項目。
%{
  title: "用語集",
  summary: "L10N.md および各言語の上書きファイル内の用語集フィールドの参照",
  category: "参照",
  section: "translation",
  order: 2
}
---
リポジトリ用語集は 2 つのファイルに分割されています。Glossia は翻訳する各ファイルについて、それをアカウント用語集とマージします。これについては、 [用語集](/docs/explanation/glossary) 2 つがどのように結合されるかについて。

| ファイル | `glossary` | 内容 | 例 |
|---|---|---|
| `L10N.md` | 用語集のリスト **用語**, 各言語で同じです。| `- source: commit` |
| `L10N/<locale>.md` | 用語とその翻訳を **翻訳** その言語での | `commit: commit` |

## L10N.md の用語

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

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `source` | string | yes | ソーステキストで表示される用語そのもの。
| `definition` | string | no | 一致が本当にこの概念であるか判断するためにモデルが読み取る短いガイダンス。
| `case_sensitive` | boolean | no | 場合 `true`, 用語は記述された正確な書式に一致するだけです。デフォルトは `false`. 名前や略語などの `API` または `SDK`. |
| `id` | string | no | 安定した識別子。参照元の `source` 省略時(`Version Control` となります `version-control`、 `C++` となります `cplusplus`). id キーの翻訳を設定し、名前を変更する `source` 用語のアイデンティティを失うことなく、または親用語から用語をオーバーライドするために `L10N.md`. |

用語は翻訳を持ちません。用語に `targets` フィールドがある場合は拒否されます：翻訳は言語ファイルに格納されます。

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

各キーは用語の `id` またはその `source`、また各値は該言語の承認された訳です。

- 用語に一致しないキーは `L10N.md` この言語専用の用語を宣言します。
- 言語に訳がない用語は、その言語のアカウント用語集にフォールバックします。
- 名前を翻訳せずにおくには、それを自身にマッピングします 例えば `Glossia: Glossia`。

## ネストされたファイル

すべてのファイルは、そのディレクトリチェーンの用語集を使用して翻訳されます：

- ネストされた `L10N.md` 継承する用語に加えられます。同じ `id`、または同じ `source` なしのとき `id` 設定されている場合、そのサブツリーでは継承されたものを上書きします。
- ネストされた `L10N/<locale>.md` 継承した訳を追加し、両者が宣言する用語については自らの訳が優先する。

## バリデーション

用語集が無効な場合、Glossia は影響を受けたファイルをアカウントの用語集のみを使用して翻訳するため、誤植が翻訳をブロックすることはありません。一般的な原因:

- **欠落 `source`。** 各用語には空でないものが必要です。
- **重複 `id`.** 各用語は、明示的に設定されたか、派生されたものであっても、一意の識別子に解決する必要があります `source`.
- **L10N.md 内の翻訳。** 用語が `targets`. 翻訳を に移動してください `L10N/<locale>.md`.
- **空の翻訳。** 空文字列にマッピングされている用語です。代わりに除外してください。
- **形状または型が正しくありません。** `glossary` 中にリストである必要があります `L10N.md` 、中にマップである必要があります `L10N/<locale>.md`。翻訳、 `id`、および `definition` 文字列である必要があります； `case_sensitive` ～である必要があります `true` または `false`.

## Glossia が記録するのは

各翻訳ファイルのロックファイルは、それを形作った用語集のエントリを記録します:

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

- `applied` ファイルに一致したエントリをリストします。リポジトリエントリは `repo:<id>`、アカウントエントリは `account:<id>`.
- `shadowed` このファイルにおいて、リポジトリのエントリによって置換されたアカウントのエントリをリストします。

用語または翻訳を編集すると、それを使用するファイルのみが再翻訳されます。

## 参照

- [用語集を定義](/docs/how-to/define-a-glossary)：ステップバイステップ ガイド。
- [用語集](/docs/explanation/glossary)：リポジトリとアカウントの用語集の統合方法。
- [L10N.md 参照](/docs/reference/l10n-md): その他の frontmatter フィールド。
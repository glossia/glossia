%{
  title: "用語集",
  summary: "L10N.md および各言語のオーバーライドファイル内の用語集フィールドの参照。",
  category: "参照",
  section: "translation",
  order: 2
}
---

リポジトリ用語集は 2 つのファイルに分割されています。Glossia は翻訳する各ファイルについて、アカウントの用語集とマージします。どのように 2 つが組み合わせるのは [用語集](/docs/explanation/glossary) をご参照ください。

| ファイル | `glossary` 保持する | 例 |
|---|---|---|
| `L10N.md` | **用語**、のリスト。すべての言語で同じもの。 | `- source: commit` |
| `L10N/<locale>.md` | 用語からその言語の **翻訳** へのマッピング。 | `commit: commit` |

## L10N.md 内の用語

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
| `source` | string | はい | ソーステキストに現れる用語。 |
| `definition` | string | いいえ | モデルが読み取り、一致が実際にこの概念かどうかを判断するための簡潔な指針。 |
| `case_sensitive` | boolean | いいえ | `true` の場合、用語は指定された正確な大文字小文字のみで一致します。デフォルトは `false` です。名前や略語、例えば `API` や `SDK` 等に使用してください。 |
| `id` | string | いいえ | 永続的な識別子。省略時は `source` から派生します（`Version Control` は `version-control` へ、`C++` は `cplusplus` へ変換されます）。用語のアイデンティティを失わずに `source` をリネームすることも、親 `L10N.md` から用語をオーバーライドすることもできます。 |

用語は翻訳を持ちません。`targets` フィールドを持つ用語は却下されます：翻訳は言語ファイルに配置されます。

## 翻訳を L10N/<locale>.md に。

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

各キーは用語の `id` またはその `source` で、各値是该語の承認された翻訳です。

- `L10N.md` に一致する用語がないキーは、この言語独自の用語を宣言します。
- 言語に翻訳のない用語は、その言語のアカウント用語集にフォールバックします。
- 翻訳されていない名前は保持するため、自身自身にマップします。例えば `Glossia: Glossia`。

## ネストされたファイル

各ファイルは、そのディレクトリチェーンの用語集を使用して翻訳されます：

- ネストされた `L10N.md` は、継承する用語に用語を追加します。同じ `id` を持つ用語または `id` が設定されていない場合の `source` が同じ用語は、そのサブツリーで継承されたものを置換します。
- ネストされた `L10N/<locale>.md` は、継承する翻訳に翻訳を追加し、両方が定義する用語については、その翻訳が優先されます。

## バリデーション

用語集が無効な場合は、Glossia は誤植が翻訳をブロックしないように、アカウント用語集のみを使用して影響を受けたファイルを翻訳します。一般的な原因：

- **不明な`source`。** 各用語には空でないものが必須です。
- **重複した`id`。** 各用語は、明示的に設定するか `source` から導出されるかにかかわらず、一意の識別子に解決する必要があります。
- **L10N.md 内の翻訳。** `targets` を持つ用語は、翻訳を `L10N/<locale>.md` に移動してください。
- **空の翻訳。** 空の文字列にマップされた用語は、代わりに除外してください。
- **型や形状の誤り。** `glossary` は `L10N.md` 内のリスト、`L10N/<locale>.md` 内のマップである必要があります。翻訳、`id`、および `definition` は文字列、`case_sensitive` は `true` または `false` である必要があります。

## Glossia が記録する内容

各翻訳されたファイルのロックファイルは、そのファイルに影響を与えた用語集エントリを記録します：

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

- `applied` はファイルに一致したエントリを列挙します。リポジトリエントリは `repo:<id>` として、アカウントエントリは `account:<id>` として表示されます。
- `shadowed` は、このファイルのためにリポジトリエントリで置換されたアカウントエントリを列挙します。

用語または翻訳の編集は、それを使用するファイルのみを再翻訳します。

## 関連情報

- [用語集を定義する](/docs/how-to/define-a-glossary): ステップバイステップの手順書。
- [用語集](/docs/explanation/glossary): リポジトリとアカウントの用語集がどのように統合されるか。
- [L10N.md 参考](/docs/reference/l10n-md): 他のフロントマターフィールド。

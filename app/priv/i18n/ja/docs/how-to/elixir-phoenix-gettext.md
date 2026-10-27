%{
  title: "Elixir と Phoenix（Gettext）",
  summary: "Gettext 翻訳を設定し、カタログメタデータを保持し、マージ競合を減らします。",
  category: "チュートリアル",
  section: "ecosystems",
  order: 1
}
---

このガイドを使用して、既存の Elixir または Phoenix アプリケーションを [Gettext](https://hexdocs.pm/gettext/) を使用して Glossia に接続し、そのカタログをマージしやすい状態に保ってください。`mix.exs` を含むディレクトリから Mix コマンドを実行します。

## 1. 決定論的な抽出の設定

既存の `project/0` 設定に、`mix.exs` に以下の項目を追加してください。

```elixir
def project do
  [
    # Keep the application's other project options here.
    gettext: [
      write_reference_line_numbers: false,
      sort_by_msgid: :case_sensitive
    ]
  ]
end
```

すでに使用している他の Gettext オプションはそのまま維持してください。Glossia で使用されている Gettext バージョンは `sort_by_msgid: :case_sensitive` をサポートしています。他のプロジェクトへ適用する際は、依存関係の [抽出オプション](https://hexdocs.pm/gettext/Mix.Tasks.Gettext.Extract.html) を確認ください。

テンプレートとロケールファイルを再作成：

```sh
mix gettext.extract --merge
```

語彙の変更とは別に、この一度限りの正規化をレビューしてコミットしてください。メッセージの順序は変更され、既存の翻訳は変更されません。この正規化は、オープンなプルリクエストと連携させ、カタログを同じ順序に更新できるようにしてください。

並べ替えは、追加をファイルの最後に追記するのではなく、独立した新しいメッセージを正規の位置に配置します。参照行番号の省略は、コードが移動しても無関係な差分を防ぎます。ソースファイルの参照は残ります。これらのオプションはコンフリクトを減らしますが、同一メッセージのコンフリクトを排除したり、すべての追加ペアが自動的にマージされることを保証することはできません。

## 2. テンプレートを翻訳し、アプリケーションソースを翻訳しない

`L10N.md` を `mix.exs` に併設して作成するか、既存の設定に以下のマッピングを追加してください：

```yaml
---
source_language: en
sources:
  "priv/gettext/default.pot": "priv/gettext/{locale}/LC_MESSAGES"
  "priv/gettext/errors.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
---

Translate user-facing messages naturally and preserve all Gettext metadata.
Keep interpolation placeholders unchanged, including their names and syntax.
```

アプリケーションに存在するドメインのみを含めてください。追加のドメインごとにマッピングを追加します。例えば `dashboard_projects.pot` などです。宛先はディレクトリです。portenable-object ハンドラーは `default.po`、`errors.po`、およびその他の一致するドメインファイル名をそこに書き込みます。

`.pot` テンプレートをソースとして、`.po` ファイルを出力として使用してください。一つの翻訳済みロケールを他のロケールのソースとして使用しないでください。ネスト型設定については [L10N.md 参照](/docs/reference/l10n-md) を、またリポジトリを Glossia に接続するには [入門チュートリアル](/docs/tutorials/getting-started) を参照してください。

## 3. ソース変更を公開する前に抽出を行う

プルリクエストが `gettext`、`dgettext`、または `ngettext` コールを変更する場合：

1. アプリケーションコードを更新します。
2. `mix gettext.extract --merge` を実行します。
3. テンプレートとロケールの差分をコード変更と合わせてレビューしてください。
4. 生成された変更をマージする前にコミットしてください。

ソース変更のマージ後、Glossia は更新されたテンプレートを翻訳し、変更されたロケールを翻訳プルリクエストとして公開します。通常の repository プロセスを経由して、その翻訳をレビューしてください。

`msgid` および `msgctxt` をソース識別子として維持してください。`msgstr` 値、つまり必須の複数形式を含む翻訳を行ってください。インタポーレーションプレースホルダー、複数形式ヘッダー、ソース参照、翻訳者コメント、フラグを維持してください。`fuzzy` エントリはレビューが必要です：チェックをパスさせるためにフラグを削除しないでください。また、変更されたメッセージ以前には正しい翻訳だとは言わないでください。

## 4. CI でカタログ変更を検証

実行：

```sh
mix gettext.extract --merge --check-up-to-date
mix compile --warnings-as-errors
```

抽出チェックは、アプリケーションソースに一致しなくなったテンプレートやロケールファイルを検出します。コンパイルチェックは、Gettext がカタログをコンパイルできることを確認します。これらのコマンドは言語的品質を検証することも、すべてのメッセージがレビューされた翻訳であることを証明することもありません。

抽出で陳腐なファイルが報告された場合は、ローカルで再作成し、差分をレビューしてコミットしてください。チェックをバイパスしたり、ソースの不一致を隠すために翻訳ワーカーでテンプレートを繰り返し再起書きしたりしないでください。

## 5. メッセージ ID によってカタログのコンフリクトを解決

デフォルトブランチからブランチを更新する際：

1. まず、意図された UI テキストを維持してアプリケーションソースのコンフリクトを解決してください。
2. 両方のブランチのカタログエントリを、文脈とソースメッセージ ID（存在する場合は複数識別子を含む）を使用して調整してください。既存の翻訳、コメント、フラグ、複数形式を維持します。パーサーを実行する前に、コンフリクトマーカーと重複エントリを削除します。
3. 解決されたソースに対して `mix gettext.extract --merge` を実行します。
4. 上記の CI チェックを実行し、生成されたカタログ差分をレビューしてください。

カタログのコンフリクトを盲目的に一方側を全受け入れ、text-union マージドライバーを有効にし、カタログを連結して解決しないでください。これらのアプローチは有効な翻訳、重複 ID、または無効なファイルを失う可能性があります。再発するコンフリクトの場合は、異なる新しいメッセージを持つ 2 つのブランチでカタログを生成し、Git がテンプレートと翻訳カタログの項目を失うことなくマージすることを検証する回帰テストを追加してください。

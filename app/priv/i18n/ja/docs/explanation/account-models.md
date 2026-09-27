%{
  title: "アカウントモデル",
  summary: "モデルプロバイダーがアカウントごとに 1 回設定され、ハンドルで参照される理由",
  category: "説明",
  section: "プラットフォーム",
  order: 2
}
---
Glossia はリポジトリの指示とモデルプロバイダーの認証情報を分離しています。リポジトリは翻訳対象を説明し、アカウントはどの [大規模言語モデル](https://en.wikipedia.org/wiki/Large_language_model) 作業を行います。

## モデルがアカウントに属する理由

チームは同じプロバイダー関係を複数のリポジトリで翻訳することがあります。アカウントスコープのモデルは管理者がすべてのリポジトリを編集せずにプロバイダーキーをローテーションまたはベースモデルを切り替えることができるようにします

この境界は認証情報をソースコード管理から外します。リポジトリには読み取り可能なハンドル `translation-default`プロバイダーキーではなく

## ハンドルは意図を安定させます

「 `model` フィールド内の `L10N.md` アカウントモデルのハンドルを指します:

```yaml
model: translation-default
```

ハンドルはリポジトリの意図を表します。リポジトリ設定が安定している間、管理者はそのハンドルの選択するプロバイダモデルを後で更新できます。

## 複数モデルの使用方法

Glossia は各ドキュメント翻訳に構成されたモデル 1 つを使用します。複数のモデルを追加してもアンサンブル、フォールバックチェーン、または自動的な品質ティアは作成されません。リポジトリの作成者は、以下のような安定したハンドルを通じて目的を選択します。 `translation-default`前回の組み立てドキュメントでは検証に失敗しました：マークダウンテキストリテラルの回復が無効な JSON を返しました `long-form`再編成されたドキュメントは以前検証に失敗しました：Markdown 文字リテラルの復元が無効な JSON を返しました `japanese-specialist`.

選択は、ドキュメントと対象のロケールの文脈階層に従います:

1. 最も近い `L10N/<locale>.md` 宣言するファイルは `model` そのロケールで優先されます。
2. さもなくば、最も近い `L10N.md` 宣言するファイルは `model` そのディレクトリで優先されます。
3. 親 `L10N.md` より近いファイルがモデルを宣言していない場合、設定は継承されます。
4. 適用可能なコンテキストファイルがハンドルを宣言していない場合、Glossia はアカウントのデフォルトを使用します。

明示的に設定されたハンドルが存在する必要があります。Glossia は、アカウントのデフォルトに無言で切り替えるのではなく、不明なハンドルに対してエラーを報告します。

## デフォルト選択

リポジトリが独自のモデルを持つ前にプロジェクトのセットアップではモデルが必要です。 `L10N.md`。したがって、Glossia はアカウントのデフォルトを選択します。最初にアカウントに追加されたモデルがデフォルトとなり、管理者は設定ページから別のモデルをデフォルトに設定できます。

一旦リポジトリが `L10N.md`, using an explicit handle makes its choice clear to reviewers. Omitting `model` keeps the repository on the account default.

## The human review boundary

Model output is proposed work, not an automatic merge. Setup and translation activity stays visible in Glossia, while repository changes are published through a pull request for the team to review. This preserves the same quality and ownership boundary teams already use for code.
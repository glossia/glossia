%{
  title: "認証",
  summary: "権限スコープ、組織ロール、およびリソースレベルのアクセスチェック。",
  category: "参照",
  subcategory: "API",
  order: 2
}
---

認証は身元を確立し、権限付与は、その身元が実行できるアクションを決定します。サインインおよびトークンフローについては [認証](/docs/reference/apis/authentication) をご参照ください。

## スコープ

スコープはトークンが実行できる動作を制御します。それらは `object:action` パターンに従います。

| スコープ | 説明 |
|-------|-------------|
| `admin:read` | プラットフォーム管理データの読み取り（プラットフォーム管理者のみ） |
| `admin:write` | プラットフォーム管理データの更新（プラットフォーム管理者のみ） |
| `ops:read` | プラットフォーム運用データの読み取り（プラットフォーム管理者のみ） |
| `user:read` | ユーザープロファイル情報の読み取り |
| `user:write` | ユーザープロファイルの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧 |
| `organization:read` | 組織詳細の読み取り（および所属組織の一覧） |
| `organization:write` | 組織の作成または更新 |
| `organization:claim` | 組織の取得 |
| `organization:delete` | 組織の削除 |
| `organization:admin` | 組織の管理アクション |
| `members:read` | 組織メンバーと招待の読み取り |
| `members:write` | 組織メンバーと招待の管理 |
| `project:read` | プロジェクトの読み取り |
| `project:write` | プロジェクトの作成または更新 |
| `project:admin` | プロジェクトの管理アクション |
| `project:delete` | プロジェクトの削除 |
| `voice:read` | 音声設定の読み取り |
| `voice:write` | 音声設定の作成または更新 |
| `voice:admin` | 音声の管理アクション |
| `glossary:read` | 用語集エントリの読み取り |
| `glossary:write` | 用語集エントリの作成または更新 |
| `glossary:admin` | 用語集設定の管理 |
| `discussion:read` | ディスカッションの読み取り |
| `discussion:write` | ディスカッションの作成または更新 |
| `discussion:admin` | ディスカッションの管理アクション |
| `ticket:read` | チケットの読み取り |
| `ticket:write` | チケットの作成または更新 |
| `ticket:admin` | チケットの管理アクション |
| `llm_model:read` | アカウント言語モデルの読み取り |
| `llm_model:write` | アカウント言語モデルの管理 |
| `translation:write` | 翻訳データの書き込み |
| `api_credentials:read` | アクセス認証情報の読み取り |
| `api_credentials:write` | アクセス認証情報の管理 |

認証サーバーの [発見メタデータ](/docs/reference/apis/authentication#discovery-endpoints) は、クライアントに利用可能なスコープを公開します。スコープが利用可能であるだけでは、アクセス権限は付与されません。

## 権限付与モデル

Glossia は **2 つのレイヤー** を [表現状態転送](https://developer.mozilla.org/en-US/docs/Glossary/REST) アプリケーションプログラミングインターフェース および [モデルコンテキストプロトコル](https://modelcontextprotocol.io) サーバーに適用します。

1. **スコープチェック**: アクセストークンは必要な `object:action` スコープを含める必要があります。
2. **リソースレベルポリシー**: 現在のユーザーは、明示的なメンバー権限またはロールベースのポリシーを通じて、特定のリソースに対して権限付与されている必要があります。

スコープはトークンの*最大*能力を表します。リソースレベルチェックは、特定の*実際の*リソースに対する権限を強制します。

### Roles

| Role | Description |
|------|-------------|
| `self` | 自分のリソースにアクセスするユーザー |
| `organization_member` | リソースを所有する組織のメンバー |
| `organization_admin` | リソースを所有する組織の管理者 |
| `public_account` | リソースはパブリックアカウントに属する |

### メンバー権限

管理者以外の組織メンバーシップは明示的な権限スコープを保持できます。新しいメンバーは、アカウント、組織、プロジェクト、音声設定、用語集、ディスカッション、およびチケットへの読み取りアクセスから開始します。組織管理者は[メンバー→権限](/docs/how-to/member-permissions)を通じてそれらのスコープを置き換えることができます。トークンを使用する場合、要求されたアクションは、メンバーが許可されているスコープおよびトークンのスコープの両方に含まれている必要があります。

組織管理者はその管理者ロールを保持します。明示的なスコープを持たない既存のメンバーシップは、権限が保存されるまで、以下のロールベースのポリシーを使用し続けます。

### ロール権限

以下に示す表は、明示的なスコープを持たないメンバーシップに適用される一般的なロールベースのルールを示しています。これは完全なポリシーではありません：コレクションリクエスト、一時的なアクセス、プラットフォーム管理者には追加のルールがあります。

| スコープ | 自分自身 | 組織メンバー | 組織管理者 | パブリックアカウント |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | はい | はい | | |
| `user:write` | はい | | | |
| `account:read` | | はい | はい | はい |
| `organization:read` | | はい | はい | |
| `organization:write` | | | はい | |
| `organization:delete` | | | はい | |
| `organization:admin` | | | はい | |
| `members:read` | | はい | はい | |
| `members:write` | | | はい | |
| `project:read` | | はい | はい | はい |
| `project:write` | | | はい | |
| `project:admin` | | | はい | |
| `project:delete` | | | はい | |
| `voice:read` | | はい | はい | はい |
| `voice:write` | | | はい | |
| `voice:admin` | | | はい | |
| `glossary:read` | | はい | はい | |
| `glossary:write` | | | はい | |
| `glossary:admin` | | | はい | |

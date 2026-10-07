%{
  title: "認証",
  summary: "権限スコープ、組織ロール、およびリソースレベルのアクセスチェック。",
  category: "参照",
  subcategory: "API",
  order: 2
}
---
認証はアイデンティティを確立し、権限は、そのアイデンティティが実行できるアクションを決定します。詳細は [認証](/docs/reference/apis/authentication) ログインおよびトークンフローについて。

## スコープ

スコープはトークンが実行できるアクションを制御します。これらは `object:action` パターン。

| スコープ | 説明 |
|-------|-------------|
| `admin:read` | プラットフォーム管理データを参照（プラットフォーム管理者のみ） |
| `admin:write` | プラットフォーム管理データを更新（プラットフォーム管理者のみ） |
| `ops:read` | プラットフォーム運用データを参照（プラットフォーム管理者のみ） |
| `user:read` | ユーザープロフィール情報を参照 |
| `user:write` | ユーザープロフィールの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧 |
| `organization:read` | 組織詳細の閲覧（所属組織一覧） |
| `organization:write` | 組織の作成または更新 |
| `organization:claim` | 組織を申請 |
| `organization:delete` | 組織を削除 |
| `organization:admin` | 組織管理操作 |
| `members:read` | 組織メンバーと招待の表示 |
| `members:write` | 組織メンバーと招待の管理 |
| `project:read` | プロジェクトの閲覧 |
| `project:write` | プロジェクトの作成または更新 |
| `project:admin` | プロジェクトの管理操作 |
| `project:delete` | プロジェクト削除 |
| `voice:read` | 音声設定の閲覧 |
| `voice:write` | 音声設定の作成・更新 |
| `voice:admin` | 音声管理操作 |
| `glossary:read` | 用語集項目の閲覧 |
| `glossary:write` | 用語集項目の作成・更新 |
| `glossary:admin` | 用語集設定の管理 |
| `discussion:read` | 議論の閲覧 |
| `discussion:write` | 議論の作成または更新 |
| `discussion:admin` | 管理ディスカッション操作 |
| `ticket:read` | チケットの閲覧 |
| `ticket:write` | チケットの作成または更新 |
| `ticket:admin` | 管理チケットの操作 |
| `llm_model:read` | アカウント言語モデルの読み取り |
| `llm_model:write` | アカウント言語モデルの管理 |
| `translation:write` | 翻訳データの書き込み |
| `api_credentials:read` | アクセス認証情報の読み取り |
| `api_credentials:write` | アクセス認証情報の管理 |

認証サーバーの [発見メタデータ](/docs/reference/apis/authentication#discovery-endpoints) クライアントに利用可能なスコープを公開します。スコープが利用可能であること自体が、アクセス権限を付与するものではありません。

## 認可モデル

Glossia は強制する **2 つのレイヤー** の [REST](https://developer.mozilla.org/en-US/docs/Glossary/REST) API および [モデル コンテキスト プロトコル](https://modelcontextprotocol.io) サーバー:

1. **スコープ チェック**: アクセストークンには必須の `object:action` スコープ。
2. **リソースレベルポリシー**: 特定のリソースに対しては、明示的なメンバー権限またはロールベースのポリシーによる権限付与が必要です。

スコープは *最大* トークンの機能です。リソースレベルチェックは強制する *実際の* 特定のリソースに対する権限。

### ロール

| ロール | 説明 |
|------|-------------|
| `self` | 自身のリソースにアクセスするユーザー |
| `organization_member` | リソースを所有する組織のメンバー |
| `organization_admin` | このリソースを所有する組織の管理者 |
| `public_account` | このリソースは公開アカウントに所属しています |

### メンバー権限

非管理者の組織メンバーシップには明示的な権限スコープを持ち得ます。新しいメンバーは、アカウント、組織、プロジェクト、ボイス、用語集、ディスカッション、およびチケットに対して初めに読み取りアクセスを有します。組織管理者はそれらのスコープを変更するには [メンバー → 権限](/docs/how-to/member-permissions)。 トークンを使用する際、要求されたアクションはメンバーの許可されたスコープおよびトークンのスコープの両方に含まれている必要があります。

組織管理者は管理者の役割を維持します。明示的なスコープを持たない既存のメンバーシップは、権限が保存されるまで、以下の役割ベースのポリシーを適用され続けます。

### ロール権限

以下のテーブルは、明示的なスコープを持たないメンバーシップの一般的な役割ベースのルールを示しています。これは完全なポリシーではありません：コレクションリクエスト、一時的なアクセス、プラットフォーム管理者には追加のルールがあります。

| スコープ | 自身 | 組織メンバー | 組織管理者 | 公開アカウント |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | はい | はい | | |
| `user:write` | はい |
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
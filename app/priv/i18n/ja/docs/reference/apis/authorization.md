%{
  title: "権限",
  summary: "権限スコープ、組織ロール、およびリソースレベルのアクセスチェック。",
  category: "参照",
  subcategory: "API",
  order: 2
}
---

認証は身元を確立し、権限はそれによって実行できるアクションを決定する。サインインとトークンのフローについては [認証](/docs/reference/apis/authentication) を参照。

## スコープ

スコープはトークンが実行できるアクションを制御する。それらは `object:action` パターンに従う。

| スコープ | 説明 |
|-------|-------------|
| `admin:read` | プラットフォーム管理データの取得（プラットフォーム管理者のみ） |
| `admin:write` | プラットフォーム管理データの更新（プラットフォーム管理者のみ） |
| `ops:read` | プラットフォーム運営データの取得（プラットフォーム管理者のみ） |
| `user:read` | ユーザープロフィール情報の取得 |
| `user:write` | ユーザープロフィールの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧 |
| `organization:read` | 組織詳細の取得（および組織の一覧） |
| `organization:write` | 組織の作成または更新 |
| `organization:claim` | 組織の所有権取得 |
| `organization:delete` | 組織の削除 |
| `organization:admin` | 組織の管理者アクション |
| `members:read` | 組織メンバーおよび招待状の取得 |
| `members:write` | 組織メンバーおよび招待状の管理 |
| `project:read` | プロジェクトの取得 |
| `project:write` | プロジェクトの作成または更新 |
| `project:admin` | プロジェクトの管理者アクション |
| `project:delete` | プロジェクトの削除 |
| `voice:read` | 音声設定の取得 |
| `voice:write` | 音声設定の作成または更新 |
| `voice:admin` | 音声の管理者アクション |
| `glossary:read` | 用語集エントリの取得 |
| `glossary:write` | 用語集エントリの作成または更新 |
| `glossary:admin` | 用語集設定の管理 |
| `discussion:read` | ディスカッションの取得 |
| `discussion:write` | ディスカッションの作成または更新 |
| `discussion:admin` | ディスカッションの管理者アクション |
| `ticket:read` | チケットの取得 |
| `ticket:write` | チケットの作成または更新 |
| `ticket:admin` | チケットの管理者アクション |
| `llm_model:read` | アカウント言語モデルの取得 |
| `llm_model:write` | アカウント言語モデルの管理 |
| `translation:read` | プロジェクト翻訳活動の取得 |
| `translation:write` | 翻訳データの書き込み |
| `analytics:read` | プロジェクトウェブサイト分析の取得 |
| `toki:read` | 自身のプライベートプロジェクト会話を取得 |
| `toki:write` | プライベート会話の作成とコンパニオン応答のキュー |
| `api_credentials:read` | アクセス資格情報の取得 |
| `api_credentials:write` | アクセス資格情報の管理 |

認証サーバーの [発見メタデータ](/docs/reference/apis/authentication#discovery-endpoints) はクライアントに利用可能なスコープを公開します。利用可能なスコープはそれ自身でアクセス権を付与しません。

## 権限モデル

Glossia は **2 つのレイヤー** を [表現状態転送](https://developer.mozilla.org/en-US/docs/Glossary/REST) 適用プログラミングインターフェース および [モデルコンテキストプロトコル](https://modelcontextprotocol.io) サーバーに実装します：

1. **スコープチェック**: アクセストークンは必要な `object:action` スコープを含む必要があります。
2. **リソースレベルポリシー**: 現在のユーザーは、特定のリソースに対して明示的なメンバー権限またはロールベースポリシーを通じて許可されている必要があります。

スコープはトークンの *最大*機能を表します。リソースレベルチェックは特定のリソースに対する *実際の*権限を実装します。

### 役割

| 役割 | 説明 |
|------|-------------|
| `self` | 自身のリソースにアクセスするユーザー |
| `organization_member` | リソースを所有する組織のメンバー |
| `organization_admin` | リソースを所有する組織の管理者 |
| `public_account` | リソースは公開アカウントに属します |

### メンバー権限

管理者の組織メンバーシップは明示的な権限スコープを含めることができます。新メンバーは、アカウント、組織、プロジェクト、音声、用語集、ディスカッション、チケット、翻訳活動、分析への取得権限および自身のプライベートトキ会話へのアクセスを持ち始めます。組織管理者は [Members → Permissions](/docs/how-to/member-permissions) 経由でそれらのスコープを置換えます。トークンを使用する場合、要求されたアクションはメンバーの許可されたスコープおよびトークンのスコープに含まれなければなりません。

プライベート トキの所有権は、組織メンバースコープのオーバーライドの前にチェックされます。メンバーシップ付与も管理者ロールも別のユーザーの会話へのアクセスを許可しません。プロジェクトの可視性は独立してチェックされます。エンドポイントスコープおよび制限については [モバイルおよびコンパニオン API](/docs/reference/apis/mobile) を参照してください。

組織管理者は管理者ロールを保持します。明示的なスコープを持たない既存メンバーシップは、権限が保存されるまで下のロールベースポリシーを使用し続けます。

### 役割権限

以下のテーブルは、明示的なスコープのないメンバーシップで一般的なロールベースルールを示します。これは完全なポリシーではありません：収集リクエスト、一時的アクセス、およびプラットフォーム管理者には追加ルールがあります。

| スコープ | 本人 | 組織メンバー | 組織管理者 | 公開アカウント |
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

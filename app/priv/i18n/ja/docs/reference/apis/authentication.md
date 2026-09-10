%{
  title: "認証と認可",
  summary: "Glossia によるユーザー認証と API アクセスの認可方法",
  category: "リファレンス",
  subcategory: "API",
  order: 1
}
---
## 認証方法

Glossia は状況に応じて 2 つの認証方法をサポートしています。

### ブラウザセッション

Web インターフェースからサインインする際、Glossia はセッションベース認証を使用します。サードパーティプロバイダ（GitHub または GitLab）を通じて認証を行います。使用する。 [Assent](https://github.com/pow-auth/assent) ライブラリです。正常なサインイン後、セッション Cookie が設定され、以降のリクエストに使用されます。

### Bearer トークン（OAuth 2.1）

API アクセス（CLI やその他のツールからのものを含む）には、Glossia は OAuth 2.1 を実装しています（Authorization Code フローと PKCE を使用）。クライアントは Bearer トークンを取得し、それを含めます。 `Authorization` ヘッダー:

    Authorization: Bearer <access_token>

## OAuth 2.1 フロー

### 1\. ダイナミック クライアント レジストレーション

クライアントは自分自身を登録するため、 `POST /oauth/register` メタデータと共に呼び出されます。これは [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

サーバーは返却します `client_id` ・ `client_secret`。

### 2\. 認証リクエスト

クライアントはユーザーを `/oauth/authorize` PKCE パラメータで：

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**すべてのクライアントでは PKCE は必須です。** のみ `S256` challenge メソッドがサポートされています。

### 3\. トークンの交換

ユーザーが承認した後、クライアントは認証コードをトークンに交換します `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

レスポンスにはアクセストークンが含まれ、オプションでリフレッシュトークンが含まれます。

### 4\. トークンのリフレッシュ

アクセストークンの有効期限が切れた場合、リフレッシュトークンを使用します:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## スコープ

スコープはトークンが実行できる動作を制御します。それらは次の `object:action` パターン。

| スコープ | 説明 |
|-------|-------------|
| `user:read` | ユーザープロファイル情報の読み取り |
| `user:write` | ユーザープロファイルの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧を表示 |
| `organization:read` | 組織詳細の閲覧（所属組織の一覧を表示） |
| `organization:write` | 組織の作成または更新 |
| `organization:delete` | 組織の削除 |
| `organization:admin` | 組織管理アクション |
| `members:read` | 組織メンバーと招待の閲覧 |
| `members:write` | 組織メンバーと招待の管理 |
| `project:read` | プロジェクトの閲覧 |
| `project:write` | プロジェクト作成・更新 |
| `project:admin` | プロジェクト管理操作 |
| `project:delete` | プロジェクトを削除 |
| `voice:read` | 音声設定を確認 |
| `voice:write` | 音声設定の作成または更新 |
| `voice:admin` | 音声管理アクション |
| `glossary:read` | 用語集の表示 |
| `glossary:write` | 用語集の作成または更新 |
| `glossary:admin` | 用語設定の管理 |

## 認証モデル

Glossia は強制しています **2 つのレイヤー** REST API および MCP サーバーに:

1. **スコープチェック**: アクセス トークンには必要な `object:action` スコープ。”\\\]
2. **リソースレベルのポリシー**：現在のユーザーは、特定のリソースに対して を介して認証する必要があります `Glossia.Policy`。

スコープは *最大* のトークンの能力。ポリシーシステムは *実際* の権限を適用します。

### ロール

| ロール | 説明 |
|------|-------------|
| `self` | 自身のリソースにアクセスできるユーザー |
| `organization_member` | リソースを所有する組織のメンバー |
| `organization_admin` | リソースを所有する組織の管理者 |
| `public_account` | アカウントは公開（読み取り専用）です |

### ロール権限

| スコープ | self | organization\_member | organization\_admin | public\_account |
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
| `glossary:admin` | | |  はい | |

## 発見エンドポイント

Glossia は、クライアントがエンドポイントを自動的に発見できるように、標準的な既知の URL にメタデータを公開します。

### OAuth 認証サーバー メタデータ (RFC 8414)

    GET /.well-known/oauth-authorization-server

発行者、エンドポイント、サポートされるスコープ、取得タイプ、およびコード チャレンジ方法を返します。

### 保護されたリソース メタデータ (RFC 9728)

    GET /.well-known/oauth-protected-resource

リソース識別子、認証サーバー、サポートされるスコープ、およびブーラー認証方法を返します。

## レート制限

OAuth エンドポイントは IP アドレスごとにレート制限が適用されます：

| エンドポイント | 制限 |
|----------|-------|
| `POST /oauth/register` | 分あたり 5 リクエスト |
| `POST /oauth/token` | 分あたり 30 リクエスト |
| `POST /oauth/revoke` | 1 分間に 30 リクエスト |
| `POST /oauth/introspect` | 1 分間に 30 リクエスト |

レート制限された場合、サーバーは HTTP 429（リクエストが多すぎます）を返します。
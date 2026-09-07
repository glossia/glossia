%{
  title: "認証と認可",
  summary: "Glossia がユーザーを認証し、API アクセスを認可する方法です。",
  category: "参照",
  subcategory: "API",
  order: 1
}
---
## 認証方法

Glossia には、文脈に応じて 2 つの認証方法がサポートされています。

### ブラウザセッション

Web インターフェース経由でサインインすると、Glossia はセッションベースの認証を使用します。第 3 者プロバイダー（GitHub または GitLab）を使用して認証を行います。 [Assent](https://github.com/pow-auth/assent) ライブラリです。サインインに成功すると、セッション Cookie が設定され、後続のリクエストに使用されます。

### Bearer トークン (OAuth 2.1)

API へのアクセス（CLI や他のツールなど）には、Glossia は PKCE および認証コードフローを使用した OAuth 2.1 を実装しています。クライアントは Bearer トークンを取得して `Authorization` ヘッダー:

    Authorization: Bearer <access_token>

## OAuth 2.1 フロー

### 1\. 動的クライアント登録

クライアントは呼び出しによって自ら登録します `POST /oauth/register` それらのメタデータと共に。これは [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

サーバーは返却します `client_id` と `client_secret`.

### 2\. 認証リクエスト

クライアントはユーザーを `/oauth/authorize` PKCE パラメータを伴って:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**PKCE は すべてのクライアントで必須です。** Only the `S256` challenge method だけがサポートされています。

### 3\. トークンの交換

ユーザーが承認した後、クライアントはトークンを取得するための認証コードを `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

レスポンスにはアクセストークンが含まれ、オプションでリフレッシュトークンが含まれます。

### 4\. トークンの更新

アクセストークンの有効期限が切れた場合、リフレッシュトークンを使用します。

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## スコープ

スコープはトークンが実行可能なアクションを制御します。それらは次の `object:action` パターン。

| 範囲 | 説明 |
|-------|-------------|
| `user:read` | ユーザープロフィールの読み取り |
| `user:write` | ユーザープロフィールの更新 |
| `account:read` | アクセスできる組織アカウントを一覧表示 |
| `organization:read` | 組織の詳細および組織の一覧を表示 |
| `organization:write` | 組織を作成または更新 |
| `organization:delete` | 組織を削除 |
| `organization:admin` | 組織管理操作 |
| `members:read` | 組織メンバーと招待の読み取り |
| `members:write` | 組織メンバーと招待の管理 |
| `project:read` | プロジェクトの読み取り |
| `project:write` | プロジェクトの作成または更新 |
| `project:admin` | プロジェクトの管理操作 |
| `project:delete` | プロジェクトの削除 |
| `voice:read` | 音声設定の読み取り |
| `voice:write` | ボイス設定の作成・更新 |
| `voice:admin` | ボイス管理アクション |
| `glossary:read` | 用語エントリの読み取り |
| `glossary:write` | 用語エントリの作成・更新 |
| `glossary:admin` | 用語設定を管理する |

## 権限モデル

Glossia は適用する **2 つの層** の REST API および MCP サーバーに対して:

1. **スコープ確認**: アクセストークンには必要な `object:action` スコープ.
2. **リソースレベルのポリシー**: 現在のユーザーは特定のリソースに対して、適切な方法によって権限が付与されている必要があります `Glossia.Policy`。

スコープは *最大の* トークンの能力です。ポリシーシステムは実行する *実際の* 特定リソースに対する権限。

### ロール

| ロール | 説明 |
|------|-------------|
| `self` | 自分のリソースにアクセスするユーザー |
| `organization_member` | リソースを所有する組織のメンバー |
| `organization_admin` | リソースを所有する組織の管理者 |
| `public_account` | アカウントは公開（読み取り専用） |

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
| `glossary:admin` | | | あり | |

## 発見用エンドポイント

Glossia は標準的な URL でメタデータを公開し、クライアントが自動的にエンドポイントを見出すことができます。

### OAuth 認証サーバーメタデータ (RFC 8414)

    GET /.well-known/oauth-authorization-server

発行元、エンドポイント、サポートスコープ、許可タイプ、およびコード チャレンジ方法を返します。

### 保護されたリソースメタデータ (RFC 9728)

    GET /.well-known/oauth-protected-resource

リソース識別子、認証サーバー、サポートスコープ、および Bearer メソッドを返します。

## レート制限

OAuth エンドポイントは IP アドレスごとにレート制限されています：

| エンドポイント | 制限 |
|----------|-------|
| `POST /oauth/register` | 5 リクエスト/分 |
| `POST /oauth/token` | 30 リクエスト/分 |
| `POST /oauth/revoke` | 1 分あたり 30 リクエスト |
| `POST /oauth/introspect` | 1 分あたり 30 リクエスト |

レート制限がかかると、サーバーは HTTP 429 (Too Many Requests) を返します。
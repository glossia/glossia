%{
  title: "認証と認可",
  summary: "Glossia がユーザーを認証し、API アクセス権限を付与する仕組み。",
  category: "リファレンス",
  subcategory: "API",
  order: 1
}
---
## 認証方式

Glossia はコンテキストに応じて 2 つの認証方式に対応しています。

### ブラウザセッション

Web インターフェース経由でサインインすると、Glossia はセッションベースの認証を使用します。サードパーティプロバイダ（GitHub または GitLab）を介して認証し、 [Assent](https://github.com/pow-auth/assent) ライブラリ。サインインが完了すると、セッション cookie は設定され、以降のリクエストで使用されます。

### Bearer トークン（OAuth 2.1）

API アクセス（CLI やその他のツールなど）の場合、Glossia は PKCE および認可コードフローを使用した OAuth 2.1 を実装しています。クライアントは Bearer トークンを取得し、～に含める `Authorization` header:

    Authorization: Bearer <access_token>

## OAuth 2.1 フロー

### 1\. ダイナミック クライアント登録

クライアンツは、自身を登録するために呼び出す `POST /oauth/register` 自身のメタデータで。これに従います [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

サーバーは返します `client_id` および `client_secret`。

### 2\. 認可リクエスト

クライアントはユーザーはリダイレクトします `/oauth/authorize` PKCE パラメータを添えて:

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**すべてのクライアントで PKCE が必須です。** サポート対象は `S256` PKCE のチャレンジメソッドのみです。

### 3\. トークンの交換

ユーザーが承認した後、クライアントは トークンを発行するための認可コードを `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

レスポンスにはアクセストークンが含まれ、オプションでリフレッシュトークンが含まれます。

### 4\. トークンの更新

アクセストークンが有効期限になると、リフレッシュトークンを使用します:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## スコープ

スコープはトークンが実行できる動作を制御します。それらは次の `object:action` パターン。

| 範囲 | 説明 |
|-------|-------------|
| `user:read` | ユーザープロフィール情報の読み取り |
| `user:write` | ユーザープロフィールの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧を表示 |
| `organization:read` | 組織詳細の表示（組織一覧の表示を含む） |
| `organization:write` | 組織の作成、更新 |
| `organization:delete` | 組織の削除 |
| `organization:admin` | 組織管理操作 |
| `members:read` | 組織メンバーおよび招待の閲覧 |
| `members:write` | 組織メンバーおよび招待の管理 |
| `project:read` | プロジェクトの閲覧 |
| `project:write` | プロジェクトの作成または更新 |
| `project:admin` | プロジェクト管理アクション |
| `project:delete` | プロジェクトの削除 |
| `voice:read` | 音声設定の読み取り |
| `voice:write` | 音声設定の作成または更新 |
| `voice:admin` | 音声管理アクション |
| `glossary:read` | 用語エントリの読み取り |
| `glossary:write` | 用語エントリの作成または更新 |
| `glossary:admin` | 用語集設定の管理 |

## 認証モデル

Glossia は適用します **2 つの層** REST API および MCP サーバーに対して:

1. **スコープチェック**: アクセストークンには必要な `object:action` スコープ。
2. **リソースレベルのポリシー**:現在のユーザーは特定のリソースに対して、経由で権限化されています `Glossia.Policy`。

スコープは表します *最大* トークンの能力です。ポリシーシステムは強制する *実際の* 特定のリソースに対する権限を適用します

### 役割

| 役割 | 説明 |
|------|-------------|
| `self` | 自身のリソースにアクセスするユーザー |
| `organization_member` | リソースを所有する組織のメンバー |
| `organization_admin` | リソースを所有する組織の管理者 |
| `public_account` | アカウントは公開 (読み取り専用) |

### ロールの権限

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
| `glossary:admin` | | | はい | |

## 発見エンドポイント

Glossia は標準の固有 URL にメタデータを公開し、クライアントが自動的にエンドポイントを発見できるようにします。

### OAuth 認証サーバーメタデータ (RFC 8414)

    GET /.well-known/oauth-authorization-server

発行者、エンドポイント、サポートスコープ、グラント タイプ、およびコード チャレンジ方式を返します。

### 保護されたリソースメタデータ (RFC 9728)

    GET /.well-known/oauth-protected-resource

リソース識別子、認証サーバー、サポートスコープ、およびベアラー方式を返します。

## レート制限

OAuth エンドポイントは IP アドレスごとにレート制限されています：

| エンドポイント | 制限 |
|----------|-------|
| `POST /oauth/register` | 1 分あたり 5 リクエスト |
| `POST /oauth/token` | 1 分あたり 30 リクエスト |
| `POST /oauth/revoke` | 30 回/分 |
| `POST /oauth/introspect` | 30 回/分 |

レートリミット時は、サーバーが HTTP 429（リクエストが多すぎます）を返します。
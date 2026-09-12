%{
  title: "認証と認可",
  summary: "Glossia がユーザーを認証し、API アクセスを認可する方法。",
  category: "リファレンス",
  subcategory: "API",
  order: 1
}
---
## 認証方法

Glossia はコンテキストに応じて 2 つの認証方法をサポートしています。

### ブラウザセッション

Web インターフェースでのサインイン時に、Glossia はセッションベースの認証を使用します。サードパーティプロバイダー（GitHub または GitLab）を介して認証を行う際、使用する [Assent](https://github.com/pow-auth/assent) ライブラリです。サインインが成功した後、セッション Cookie が設定され、以降のリクエストに使用されます。

### Bearer トークン (OAuth 2.1)

API アクセス（CLI など他のツールから）の場合は、Glossia は認証コードフローおよび PKCE を採用した OAuth 2.1 を実装します。クライアントは Bearer トークンを取得し、これを `Authorization` ヘッダー：

    Authorization: Bearer <access_token>

## OAuth 2.1 フロー

### 1\. ダイナミッククライアント登録

クライアント自身が、呼び出しで登録します `POST /oauth/register` そのメタデータを用いて。これには～に従います [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

サーバーは結果を返します。 `client_id` と `client_secret`.

### 2\. 認証リクエスト

クライアントはユーザーをリダイレクトします。 `/oauth/authorize` PKCE パラメータを伴います。

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**すべてのクライアントで PKCE が必要です。** 唯一の `S256` コード チャレンジ方法はサポートされています。

### 3\. トークン交換

ユーザーが承認した後、クライアントは次の場所で認証コードをトークンに交換します `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

レスポンスにはアクセストークンが含まれ、オプションでリフレッシュトークンが含まれます。

### 4\. トークンリフレッシュ

アクセストークンが期限切れの場合、リフレッシュトークンを使用してください：

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## スコープ

スコープはトークンが実行できるアクションを制御します。それらは以下に従います。 `object:action` パターン。

| スコープ | 説明 |
|-------|-------------|
| `user:read` | ユーザープロフィール情報の読み取り |
| `user:write` | ユーザープロフィールの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧表示 |
| `organization:read` | 組織詳細の閲覧（組織の一覧表示） |
| `organization:write` | 組織の作成・更新 |
| `organization:delete` | 組織の削除 |
| `organization:admin` | 組織管理のアクション |
| `members:read` | 組織メンバーと招待の読み取り |
| `members:write` | 組織メンバーと招待の管理 |
| `project:read` | プロジェクトの読み取り |
| `project:write` | プロジェクトの作成または更新 |
| `project:admin` | プロジェクト管理操作 |
| `project:delete` | プロジェクトの削除 |
| `voice:read` | 音声設定の読み取り |
| `voice:write` | 音声設定の作成・更新 |
| `voice:admin` | 音声管理 |
| `glossary:read` | 用語エントリの表示 |
| `glossary:write` | 用語エントリの作成・更新 |
| `glossary:admin` | 用語集設定の管理 |

## 認証モデル

Glossia は強制します **2 つの層** REST API および MCP サーバーに対しては：

1. **スコープチェック**: アクセストークンには必要な `object:action` スコープを含める必要があります。”
2. **リソースレベルポリシー**: 特定のリソースに対して現在のユーザーは認証済みであり、 `Glossia.Policy`.

スコープは *最大* トークンの機能。ポリシーシステムは適用する *実際の* 特定のリソースに対する権限。

### ロール

| ロール | 説明 |
|------|-------------|
| `self` | 自分のリソースにアクセスするユーザー |
| `organization_member` | リソースを所有する組織のメンバー |
| `organization_admin` | リソースを所有する組織の管理者 |
| `public_account` | アカウントは公開（読み取り専用） |

### ロールの権限

| スコープ | 自分 | 組織メンバー | 組織管理者 | 公開アカウント |
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

Glossia は、標準的な規定の URL でメタデータを公開し、クライアントが自動的にエンドポイントを検出できるようにします。

### OAuth 認証サーバーメタデータ (RFC 8414)

    GET /.well-known/oauth-authorization-server

発行元、エンドポイント、サポートされるスコープ、グラントタイプ、コードチャレンジ方法を返します。

### 保護されたリソースメタデータ (RFC 9728)

    GET /.well-known/oauth-protected-resource

リソース識別子、認証サーバー、サポートされるスコープ、ベアラー方法を返します。

## レート制限

OAuth エンドポイントは IP アドレスごとにレート制限がかかります：

| エンドポイント | 制限 |
|----------|-------|
| `POST /oauth/register` | 1 分あたり 5 リクエスト |
| `POST /oauth/token` | 1 分あたり 30 リクエスト |
| `POST /oauth/revoke` | 30 リクエスト/分 |
| `POST /oauth/introspect` | 30 リクエスト/分 |

レート制限された場合、サーバーは HTTP 429（要求过多）を返します。
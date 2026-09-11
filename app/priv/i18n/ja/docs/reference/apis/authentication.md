%{
  title: "認証と認可",
  summary: "Glossia がユーザーを認証し、API アクセスを認可する方法。",
  category: "リファレンス",
  subcategory: "API",
  order: 1
}
---
## 認証方法

Glossia は状況に応じて 2 つの認証方法をサポートしています。

### ブラウザセッション

Web インターフェースを通じてサインインすると、Glossia はセッション認証を使用します。サードパーティプロバイダ（GitHub または GitLab）を使用して認証を行います。使用する [Assent](https://github.com/pow-auth/assent) ライブラリです。サインイン成功後、セッションクッキーが設定され、以降のリクエストで利用されます。

### Bearer トークン（OAuth 2.1）

API アクセス（CLI やその他のツールなど）の場合、Glossia は Authorization Code フローおよび PKCE を使用した OAuth 2.1 を実装しています。クライアントは Bearer トークンを取得し、含めます `Authorization` ヘッダー：

    Authorization: Bearer <access_token>

## OAuth 2.1 フロー

### 1\. ダイナミック クライアント登録

クライアントは自身を登録するために `POST /oauth/register` 自身のメタデータと共に呼び出し、これは [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

サーバーは返却します `client_id` および `client_secret`.

### 2\. 認証リクエスト

クライアントはユーザーを `/oauth/authorize` PKCE パラメータ：

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**すべてのクライアントで PKCE が必須です。** ～のみ `S256` チャレンジ・メソッドがサポートされています。

### 3\. トークン交換

ユーザーが承認した後、クライアントは認証コードを以下でトークンに交換します。 `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

レスポンスにはアクセストークンが含まれ、オプションでリフレッシュ トークンも含まれます。

### 4\. トークンのリフレッシュ

アクセストークンが期限切れになった場合は、リフレッシュ トークンを使用してください:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## スコープ

スコープはトークンが実行できるアクションを制御します。これらは以下の `object:action` パターン。

| スコープ | 説明 |
|-------|-------------|
| `user:read` | ユーザープロフィール情報の読み取り |
| `user:write` | ユーザープロフィールの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧を表示 |
| `organization:read` | 組織詳細の表示（および組織一覧の表示） |
| `organization:write` | 組織の作成または更新 |
| `organization:delete` | 組織の削除 |
| `organization:admin` | 組織管理アクション |
| `members:read` | 組織メンバーと招待の読み取り |
| `members:write` | 組織メンバーと招待の管理 |
| `project:read` | プロジェクトの読み取り |
| `project:write` | プロジェクト作成・更新 |
| `project:admin` | プロジェクトの管理操作 |
| `project:delete` | プロジェクト削除 |
| `voice:read` | 音声設定を表示 |
| `voice:write` | ボイス設定の作成または更新 |
| `voice:admin` | ボイス管理アクション |
| `glossary:read` | 用語エントリの読み取り |
| `glossary:write` | 用語エントリの作成または更新 |
| `glossary:admin` | 用語管理設定 |

## 認証モデル

Glossia は強制します **2 つのレイヤー** REST API と MCP サーバー：

1. **スコープ チェック**: アクセストークンには必須の `object:action` スコープ。
2. **リソースレベルポリシー**: 現在のユーザーは、特定のリソースに対して以下を通じて認証されている必要があります `Glossia.Policy`.

スコープは *最大* トークンの権限を表します。ポリシーシステムは強制する *実際の* 権限を特定のリソースに対して適用します。

### ロール

| ロール | 説明 |
|------|-------------|
| `self` | 自身のリソースにアクセスするユーザー |
| `organization_member` | リソースを所有する組織のメンバー |
| `organization_admin` | リソースを所有する組織の管理者 |
| `public_account` | アカウントは公開（読み取り専用） |

### ロール権限

| 範囲 | 自身 | 組織メンバー | 組織管理者 | 公開アカウント |
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

Glossia は標準的な well-known URL でメタデータを公開し、クライアントが自動的にエンドポイントを発見できるようにします。

### OAuth 認証サーバーメタデータ (RFC 8414)

    GET /.well-known/oauth-authorization-server

発行元、エンドポイント、サポートスコープ、グラントタイプ、およびコード チャレンジ方法を返します。

### 保護されたリソースメタデータ (RFC 9728)

    GET /.well-known/oauth-protected-resource

リソース識別子、認証サーバー、サポートスコープ、およびベアラ方法を返します。

## レート制限

OAuth エンドポイントは IP アドレスごとのレート制限があります：

| エンドポイント | 制限 |
|----------|-------|
| `POST /oauth/register` | 5 リクエスト/分 |
| `POST /oauth/token` | 30 リクエスト/分 |
| `POST /oauth/revoke` | 1 分あたり 30 リクエスト |
| `POST /oauth/introspect` | 1 分あたり 30 リクエスト |

レート制限がかかった場合、サーバーは HTTP 429（リクエストが多すぎます）を返します。
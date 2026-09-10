%{
  title: "認証と認可",
  summary: "Glossia がユーザーを認証し、API アクセスを認可する方法について",
  category: "参考",
  subcategory: "API",
  order: 1
}
---
## 認証方法

文脈に応じて、Glossia は 2 つの認証方法をサポートしています。

### ブラウザセッション

Web インターフェースでサインインする場合、Glossia はセッションベースの認証を使用します。第 3 者プロバイダー（GitHub または GitLab）を通じて認証を行う際に使用する [Assent](https://github.com/pow-auth/assent) ライブラリ。サインインが成功すると、セッション Cookie が設定され、その後のリクエストで使用されます。

### Bearer トークン（OAuth 2.1）

API アクセス（CLI やその他のツールなど）には、Glossia は 認可コードフローおよび PKCE を用いた OAuth 2.1 を実装しています。クライアントは Bearer トークンを取得し、～に含めるために `Authorization` header:

    Authorization: Bearer <access_token>

## OAuth 2.1 フロー

### 1\. ダイナミック クライアント登録

クライアントは自身を登録するために呼び出します `POST /oauth/register` メタデータと共に。以下の通りです [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

サーバーは返します `client_id` と `client_secret`.

### 2\. 認可リクエスト

クライアントはユーザーにリダイレクトします `/oauth/authorize` PKCE パラメータ付きで：

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**すべてのクライアントで PKCE は必須です。** のみ `S256` チャレンジメソッドはサポートされています。

### 3\. トークン交換

ユーザーが承認した後、クライアントは認証コードをトークンに変換します `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

レスポンスにはアクセストークンが含まれ、オプションでリフレッシュトークンが含まれます。

### 4\. トークンリフレッシュ

アクセストークンが有効期限切れになった場合は、リフレッシュトークンを使用してください：

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## スコープ

スコープは、トークンが実行できるアクションを制御します。それらは `object:action` パターン。

| スコープ | 説明 |
|-------|-------------|
| `user:read` | ユーザープロフィールの読み取り |
| `user:write` | ユーザープロフィールの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧表示 |
| `organization:read` | 組織詳細の閲覧（および組織一覧の表示） |
| `organization:write` | 組織の作成または更新 |
| `organization:delete` | 組織の削除 |
| `organization:admin` | 組織管理アクション |
| `members:read` | 組織メンバーと招待の読み取り |
| `members:write` | 組織メンバーと招待の管理 |
| `project:read` | プロジェクトの読み取り |
| `project:write` | プロジェクトの作成または更新 |
| `project:admin` | プロジェクトの管理操作 |
| `project:delete` | プロジェクトを削除 |
| `voice:read` | 音声設定を確認 |
| `voice:write` | 音声設定の作成または更新 |
| `voice:admin` | 音声管理アクション |
| `glossary:read` | 用語エントリの閲覧 |
| `glossary:write` | 用語エントリの作成または更新 |
| `glossary:admin` | 用語集設定の管理 |

## 認証モデル

Glossia は規定します **2 つのレイヤー** REST API および MCP サーバーに対して:

1. **スコープチェック**: アクセス トークンには必要な `object:action` スコープを含める必要があります。
2. **リソース レベルポリシー**: 現在のユーザーは特定のリソースに対して以下によりアクセス権限を保持している必要があります `Glossia.Policy`.

スコープは *最大* トークンの権限です。ポリシーシステムは適用する *実際の* 特定のリソースに対する権限を適用します。

### 役割

| 役割 | 説明 |
|------|-------------|
| `self` | 自分のリソースにアクセスするユーザー |
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
| `glossary:admin` | | | はい | |

## 発見用エンドポイント

Glossia は標準的なよく知られた URL にメタデータを公開しており、クライアントは自動的にエンドポイントを発見できます。

### OAuth 認証サーバーメタデータ (RFC 8414)

    GET /.well-known/oauth-authorization-server

発行元、エンドポイント、サポートスコープ、グラントタイプ、およびコードチャレンジ手法を返します。

### 保護されたリソースメタデータ (RFC 9728)

    GET /.well-known/oauth-protected-resource

リソース識別子、認証サーバー、サポートスコープ、およびベアラ方式を返します。

## レート制限

OAuth エンドポイントは IP アドレスごとにレート制限されています：

| エンドポイント | 制限 |
|----------|-------|
| `POST /oauth/register` | 1 分ごとに 5 リクエスト |
| `POST /oauth/token` | 1 分ごとに 30 リクエスト |
| `POST /oauth/revoke` | 1 分あたり 30 リクエスト |
| `POST /oauth/introspect` | 1 分あたり 30 リクエスト |

レート制限の場合、サーバーは HTTP 429（リクエスト過多）を返します。
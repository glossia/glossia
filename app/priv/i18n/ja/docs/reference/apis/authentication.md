%{
  title: "認証と認可",
  summary: "Glossia がユーザーを認証し、API アクセスを認可する仕組み。",
  category: "reference",
  subcategory: "apis",
  order: 1
}
---
## 認証方式

Glossia は、利用状況に応じて 2 種類の認証方式をサポートしています。

### ブラウザーセッション

Web インターフェースからサインインすると、Glossia はセッションベースの認証を使用します。[Assent](https://github.com/pow-auth/assent) ライブラリを使用し、サードパーティープロバイダー（GitHub または GitLab）経由で認証します。サインインに成功するとセッション Cookie が設定され、以降のリクエストで使用されます。

### ベアラートークン（OAuth 2.1）

API アクセス（CLI やその他のツールからのアクセスなど）では、Glossia は認可コードフローと PKCE を使用する OAuth 2.1 を実装しています。クライアントはベアラートークンを取得し、`Authorization` ヘッダーに含めます。

```
Authorization: Bearer <access_token>
```

## OAuth 2.1 フロー

### 1. 動的クライアント登録

クライアントは、自身のメタデータを指定して `POST /oauth/register` を呼び出し、登録します。これは [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) に準拠しています。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

サーバーは `client_id` と `client_secret` を返します。

### 2. 認可リクエスト

クライアントは、PKCE パラメーターを指定してユーザーを `/oauth/authorize` にリダイレクトします。

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**すべてのクライアントで PKCE が必須です。** サポートされるチャレンジ方式は `S256` のみです。

### 3. トークン交換

ユーザーが承認すると、クライアントは `POST /oauth/token` で認可コードをトークンと交換します。

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>
```

レスポンスにはアクセストークンが含まれ、必要に応じてリフレッシュトークンも含まれます。

### 4. トークンの更新

アクセストークンの有効期限が切れた場合は、リフレッシュトークンを使用します。

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

## スコープ

スコープは、トークンが実行できる操作を制御します。スコープは `object:action` パターンに従います。

| スコープ | 説明 |
|-------|-------------|
| `user:read` | ユーザープロフィール情報の読み取り |
| `user:write` | ユーザープロフィールの更新 |
| `account:read` | アクセス可能な組織アカウントの一覧表示 |
| `organization:read` | 組織の詳細の読み取り（所属する組織の一覧表示を含む） |
| `organization:write` | 組織の作成または更新 |
| `organization:delete` | 組織の削除 |
| `organization:admin` | 組織の管理操作 |
| `members:read` | 組織のメンバーと招待の読み取り |
| `members:write` | 組織のメンバーと招待の管理 |
| `project:read` | プロジェクトの読み取り |
| `project:write` | プロジェクトの作成または更新 |
| `project:admin` | プロジェクトの管理操作 |
| `project:delete` | プロジェクトの削除 |
| `voice:read` | ボイス設定の読み取り |
| `voice:write` | ボイス設定の作成または更新 |
| `voice:admin` | ボイスの管理操作 |
| `glossary:read` | 用語エントリーの読み取り |
| `glossary:write` | 用語エントリーの作成または更新 |
| `glossary:admin` | 用語設定の管理 |

## 認可モデル

Glossia は、REST API と MCP サーバーに対して**二重の制御**を適用します。

1. **スコープチェック**: アクセストークンには、必要な `object:action` スコープが含まれている必要があります。
2. **リソースレベルのポリシー**: 現在のユーザーは、`Glossia.Policy` を介して対象リソースへのアクセスを認可されている必要があります。

スコープは、トークンが持つ*最大限*の権限を表します。ポリシーシステムは、特定のリソースに対する*実際*の権限を適用します。

### ロール

| ロール | 説明 |
|------|-------------|
| `self` | 自身のリソースにアクセスするユーザー |
| `organization_member` | リソースを所有する組織のメンバー |
| `organization_admin` | リソースを所有する組織の管理者 |
| `public_account` | 公開アカウント（読み取り専用） |

### ロールの権限

| スコープ | self | organization_member | organization_admin | public_account |
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

## 検出エンドポイント

Glossia は標準の well-known URL でメタデータを公開し、クライアントがエンドポイントを自動的に検出できるようにします。

### OAuth 認可サーバーメタデータ（RFC 8414）

```
GET /.well-known/oauth-authorization-server
```

発行者、エンドポイント、対応するスコープ、認可タイプ、およびコードチャレンジ方式を返します。

### 保護対象リソースのメタデータ（RFC 9728）

```
GET /.well-known/oauth-protected-resource
```

リソース識別子、認可サーバー、対応するスコープ、およびベアラー方式を返します。

## レート制限

OAuth エンドポイントには、IP アドレスごとにレート制限が適用されます。

| エンドポイント | 上限 |
|----------|-------|
| `POST /oauth/register` | 1分あたり5リクエスト |
| `POST /oauth/token` | 1分あたり30リクエスト |
| `POST /oauth/revoke` | 1分あたり30リクエスト |
| `POST /oauth/introspect` | 1分あたり30リクエスト |

レート制限に達した場合、サーバーは HTTP 429（Too Many Requests）を返します。
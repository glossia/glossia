%{
  title: "認証",
  summary: "ブラウザのサインイン、アクセストークン、および認証エンドポイント。",
  category: "リファレンス",
  subcategory: "API",
  order: 1
}
---

このページでは [オープン認証](https://oauth.net/2.1/) (OAuth)、[コード交換用キー証明](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE) および [アプリケーションプログラミングインターフェース](https://developer.mozilla.org/en-US/docs/Glossary/API) (API) を説明しています。以下のリンクから接続可能なプロトコルの仕様は、Requests for Comments (RFCs) として公開されています。

## 認証方法

Glossia はブラウザセッションとベアラートークンに対応しています。ベアラートークンは以下の承認フローを通じて発行され、[アカウントトークン](/docs/reference/apis/account-tokens) として作成されることもできます。

### ブラウザセッション

ウェブインターフェースでサインインすると、Glossia はセッションベースの認証を使用します。あなたは [Assent](https://github.com/pow-auth/assent) ライブラリを使用して、GitHub、GitLab、Google、または設定済みの組織アイデンティティプロバイダーを介して認証します。サインインが成功すると、セッションクッキーが設定され、以降のリクエストで使用されます。

組織は Google Workspace または Okta を構成し、自動登録を許可する前に職務メールアドレスのドメインを検証できます。設定要件およびアカウントリンク要件については、[組織のサインインを設定](/docs/how-to/organization-sign-in) を参照してください。

### ベアラートークン (OAuth 2.1)

API アクセス（CLI やその他のツールなど）において、Glossia は PKCE を含む OAuth 2.1 の権限コードフローを実装します。クライアントは Bearer トークンを取得し、`Authorization` ヘッダーに含めます：

```
Authorization: Bearer <access_token>
```

## OAuth 2.1 フロー

### 1. ダイナミッククライアント登録

クライアントはメタデータと共に `POST /oauth/register` を呼び出して登録を行います。これは [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) に準拠しています。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia は `client_id` および `client_secret` を返します。この例の `localhost` リダイレクトは開発中のあなたのアプリケーションに属しています。本.production アプリケーションは独自の安全なコールバックアドレスを登録する必要があります。

### 2. 権限リクエスト

クライアントは PKCE パラメータと共にユーザーを `/oauth/authorize` にリダイレクトします：

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**すべてのクライアントで PKCE の使用が必須です。** 対応しているチャレンジ方式は `S256` のみです。

### 3. トークン交換

ユーザーが承認すると、クライアントは `POST /oauth/token` において、権限コードをトークンに交換します：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

レスポンスにはアクセストークンと、オプションでリフレッシュトークンが含まれます。

### 4. トークンの更新

アクセストークンが期限切れになった際には、リフレッシュトークンを使用します：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

権限スコープ、メンバーアクセス、およびリソースレベルのチェックについては、[権限](/docs/reference/apis/authorization) を参照してください。

## 発見エンドポイント

Glossia は標準的なよく知られた URL にメタデータを公開し、クライアントが自動的にエンドポイントを発見できるようにしています。

### OAuth 認証サーバーメタデータ (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

発行者、エンドポイント、サポートされるスコープ、rent タイプ、およびコードチャレンジ方式を返します。

### 保護されたリソースメタデータ (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

リソース識別子、認証サーバー、サポートスコープ、およびベアラートークンを返します。

## レート制限

登録はクライアントアドレスによって制限されます。トークン、取り消し、および詳細確認リクエストは、クライアントアドレスおよびクライアント識別子の両方で制限されます：

| エンドポイント | 制限 |
|----------|-------|
| `POST /oauth/register` | 1 分あたりの 5 リクエスト |
| `POST /oauth/token` | 1 分あたりの 30 リクエスト |
| `POST /oauth/revoke` | 1 分あたりの 30 リクエスト |
| `POST /oauth/introspect` | 1 分あたりの 30 リクエスト |

レート制限された場合、サーバーは HTTP 429（リクエスト過多）を返します。

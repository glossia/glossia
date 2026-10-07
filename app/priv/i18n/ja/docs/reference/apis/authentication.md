%{
  title: "認証",
  summary: "ブラウザのサインイン、アクセストークン、および認証エンドポイント。",
  category: "リファレンス",
  subcategory: "API",
  order: 1
}
---
このページでは [公開認証](https://oauth.net/2.1/) (OAuth)、 [コード交換用証明キー](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE)、そして [アプリケーション・プログラミング・インタフェース](https://developer.mozilla.org/en-US/docs/Glossary/API) (API)。以下のリンクされたプロトコル仕様が、リクエストフォーコメンツ（RFC）として公開されています。

## 認証方法

Glossia はブラウザセッションと Bearer トークンをサポートしています。以下の認証フローを通じて発行するか、作成される [アカウント トークン](/docs/reference/apis/account-tokens)。

### ブラウザセッション

ウェブインターフェースでサインインすると、Glossia はセッションベースの認証を使用します。GitHub、GitLab、Google、または設定済みの組織 ID プロバイダを使用 [Assent](https://github.com/pow-auth/assent) ライブラリ。すべての認証が成功すると、セッションクッキーが設定され、以降のリクエストで利用されます。

組織は Google Workspace または Okta を設定し、自動登録を許可する前に勤務先メールドメインを検証できます。参照 [組織サインインの設定](/docs/how-to/organization-sign-in) 設定およびアカウント連携の要件のため。

### Bearer トークン (OAuth 2.1)

API アクセス（CLI やその他のツールなど）については、Glossia は認証コードフローおよび PKCE を使用した OAuth 2.1 を実装しています。クライアントは Bearer トークンを取得し、これを含めるために `Authorization` ヘッダー:

    Authorization: Bearer <access_token>

## OAuth 2.1 フロー

### 1\. ダイナミック クライアント レジストレーション

クライアントは自身を登録するために呼び出す `POST /oauth/register` それらのメタデータと共に。これに従います [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591).

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia が返します `client_id` および `client_secret`。その `localhost` この例でのリダイレクトは開発中のアプリケーションに設定されています。本番環境では、独自の安全なコールバックアドレスを登録する必要があります。

### 2\. 認可リクエスト

クライアントはユーザーをリダイレクトします `/oauth/authorize` PKCE パラメータを伴って：

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**すべてのクライアントに対して PKCE が必須です。** ～のみ `S256` チャレンジメソッドがサポートされています。

### 3\. トークン交換

ユーザーが承認した後、クライアントはトークンのために認可コードを交換し、以下の URL に `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>

レスポンスにはアクセストークンが含まれ、オプションでリフレッシュトークンが含まれます。

### 4\. トークンのリフレッシュ

アクセストークンが期限切れになった場合は、リフレッシュトークンを使用します:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

参照 [Authorization](/docs/reference/apis/authorization) 。権限スコープ、メンバーアクセス、およびリソースレベルの確認については

## ディスカバリーエンドポイント

Glossia は、クライアントが自動的にエンドポイントを発見できるように、標準的なよく知られた URL にメタデータを公開します。

### OAuth 認証サーバーメタデータ (RFC 8414)

    GET /.well-known/oauth-authorization-server

発行元、エンドポイント、サポートされたスコープ、認可タイプ、およびコードチャレンジ手法を返します。

### 保護されたリソースメタデータ (RFC 9728)

    GET /.well-known/oauth-protected-resource

リソース識別子、認証サーバー、サポートされたスコープ、および Bearer 方式を返します。

## レート制限

登録はクライアントアドレスによって制限されます。トークン、撤回、およびイントスペクションリクエストは、クライアントアドレスとクライアント識別子の両方によって制限されます。

| エンドポイント | 制限 |
|----------|-------|
| `POST /oauth/register` | 5 リクエスト/分 |
| `POST /oauth/token` | 30 リクエスト/分 |
| `POST /oauth/revoke` | 30 リクエスト/分 |
| `POST /oauth/introspect` | 30 リクエスト/分 |

レート制限された場合、サーバーは HTTP 429（リクエストが多すぎます）を返します。
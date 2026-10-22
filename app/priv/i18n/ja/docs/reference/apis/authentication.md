%{
  title: "認証",
  summary: "ブラウザのサインイン、アクセストークン、認証エンドポイント。",
  category: "リファレンス",
  subcategory: "API",
  order: 1
}
---

このページは、[オープン・オーソライゼーション](https://oauth.net/2.1/)（OAuth）、[コード交換用証明キー](https://datatracker.ietf.org/doc/html/rfc7636)（PKCE）、および [アプリケーションプログラミングインタフェース](https://developer.mozilla.org/en-US/docs/Glossary/API)（API）について説明します。以下にリンクされているプロトコル仕様は、意見公募として（RFCs）公開されています。

## 認証方法

Glossia はブラウザセッションとベアータークンをサポートしています。ベアータークンは以下の認証フローを通じて発行するか、[アカウントトークン](/docs/reference/apis/account-tokens)として作成することもできます。

### ブラウザセッション

ウェブインターフェースからサインインすると、Glossia はセッションベースの認証を使用します。GitHub、GitLab、Google、または構成された組織のアイデンティティプロバイダを使用して[Assent](https://github.com/pow-auth/assent) ライブラリを通じて認証します。サインインが成功すると、セッションクッキーが設定され、次のリクエストで使用されます。

組織は Google Workspace または Okta を構成し、自動登録を許可する前に勤務先メールドメインを検証できます。設定およびアカウントリンク要件については[組織サインインの設定](/docs/how-to/organization-sign-in)を参照してください。

### ベアータークン（OAuth 2.1）

API アクセス（CLI や他のツールなど）から、Glossia は PKCE を含む OAuth 2.1 の認可コードフローを実装しています。クライアントはベアータークンを取得し、それを`Authorization`ヘッダーに含めます：

```
Authorization: Bearer <access_token>
```

## OAuth 2.1フロー

### 1. ダイナミッククライアント登録

クライアントはメタデータ付きで`POST /oauth/register`を呼び出して自ら登録します。これは[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)に従います。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia は`client_id`と`client_secret`を返します。この例の`localhost`リダイレクトは、開発中のアプリケーションに属しています。

### 2. 認可要求

クライアントは PKCE パラメータを付けてユーザーを`/oauth/authorize`にリダイレクトします：

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE はすべてのクライアントについて必要です。** `S256` チャレンジ方式のみがサポートされています。

### 3. トークン交換

ユーザーが承認した後、クライアントは`POST /oauth/token`で認証コードをトークンに交換します：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

レスポンスにはアクセストークンと、オプションでリフレッシュトークンが含まれます。

### 4. トークンリフレッシュ

アクセストークンが期限切れになった際、リフレッシュトークンを使用します：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

権限スコープ、メンバーアクセス、およびリソースレベルチェックについては[認可](/docs/reference/apis/authorization)を参照してください。

## ディスカバリエンドポイント

Glossia はクライアントが自動的にエンドポイントを発見できるように、標準的なウェルノウン URL でメタデータを公開しています。

### OAuth 認証サーバーメタデータ（RFC 8414）

```
GET /.well-known/oauth-authorization-server
```

発行元、エンドポイント、サポートスコープ、グラントタイプ、およびコードチャレンジメソッドを返します。

### 保護されたリソースメタデータ（RFC 9728）

```
GET /.well-known/oauth-protected-resource
```

リソース ID、認証サーバー、サポートスコープ、およびベアーマメソッドを返します。

## レート制限

登録はクライアントアドレスに制限されます。トークン、破棄、および内部リクエストはクライアントアドレスとクライアント識別子の両方に制限されます：

| エンドポイント | 制限 |
|----------|-------|
| `POST /oauth/register` | 分あたり 5 回 |
| `POST /oauth/token` | 分あたり 30 回 |
| `POST /oauth/revoke` | 分あたり 30 回 |
| `POST /oauth/introspect` | 分あたり 30 回 |

レート制限が適用された場合、サーバーは HTTP 429（リクエストが多すぎます）を返します。

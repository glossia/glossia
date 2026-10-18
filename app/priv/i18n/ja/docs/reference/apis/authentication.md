%{
  title: "認証",
  summary: "ブラウザのサインイン、アクセストークン、認証エンドポイント。",
  category: "リファレンス",
  subcategory: "API",
  order: 1
}
---

このページは[Open Authorization](https://oauth.net/2.1/)（OAuth）、[Proof Key for Code Exchange](https://datatracker.ietf.org/doc/html/rfc7636)（PKCE）、および[application programming interface](https://developer.mozilla.org/en-US/docs/Glossary/API)（API）について説明します。以下にリンクされたプロトコル仕様は、Requests for Comments（RFC）として発行されています。

## ## 認証方法

Glossia はブラウザセッションとベアラートークンをサポートします。ベアラートークンは下の認証フローを通じて発行されるか、[account tokens](/docs/reference/apis/account-tokens) として作成することもできます。

### ### ブラウザセッション

Web インターフェースでサインインするときは、Glossia はセッションベースの認証を使用します。GitHub、GitLab、Google、または構成済みの組織認証プロバイダーを使って[Assent](https://github.com/pow-auth/assent) ライブラリで認証します。サインインが成功すると、セッションクッキーが設定され、以降のリクエストで使われます。

組織は Google Workspace や Okta を設定し、自動登録を許可する前に勤務用電子メールドメインを確認できます。[Configure organization sign-in](/docs/how-to/organization-sign-in) でセットアップとアカウントのリンク要件を確認してください。

### ### Bearer トークン（OAuth 2.1）

API アクセス（CLI や他のツールなどから）の場合は、Glossia は Authorization Code Flow と PKCE を使った OAuth 2.1 を実装しています。クライアントはベアラートークンを取得し、`Authorization`ヘダーに含めます：

```
Authorization: Bearer <access_token>
```

## ### OAuth 2.1 フロー

### 1. ダイナミッククライアント登録

クライアントはメタデータと共に`POST /oauth/register`を呼び出して自分自身を登録します。これは[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)に従っています。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia は`client_id`と`client_secret`を返します。この例の`localhost`リダイレクトは開発中のあなたのアプリケーションのものになります。本番アプリケーションは独自の安全なコールバックアドレスを登録してください。

### 2. 承認リクエスト

クライアントは PKCE パラメータを使用して、ユーザーを `/oauth/authorize` にリダイレクトします:

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**すべてのクライアントで PKCE は必須です。** サポートされているのは `S256` のチャレンジ手法のみです。

### 3. トークンの交換

ユーザーが承認した後、クライアントは`POST /oauth/token`での認証クリptomをトークンに交換します：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

レスポンスにはアクセス トークンが含まれ、オプションでリフレッシュ トークンも含まれます。

### 4. トークンの更新

アクセス トークンが期限切れになると、リフレッシュ トークンを使用します：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

権限スコープ、メンバーアクセス、およびリソースレベルのチェックについては[Authorization](/docs/reference/apis/authorization)を参照してください。

## ### ディスカバリーエンドポイント

Glossia は標準的な well-known URL にメタ数据进行公开し、クライアントが自動的にエンドポイントを発見できるようにします。

### ### OAuth 認証サーバーメタデータ（RFC 8414）

```
GET /.well-known/oauth-authorization-server
```

発行元、エンドポイント、サポートされたスコープ、grant types、およびコードチャレンジ方法を返します。

### ### 保護リソースメタデータ（RFC 9728）

```
GET /.well-known/oauth-protected-resource
```

リソース識別子、認証サーバー、サポートされたスコープ、およびベアラートークン方法を返します。

## ### レート制限

登録はクライアントアドレスで制限されます。トークン、撤回、およびイントスペクションリクエストはクライアントアドレスとイデントフィケータの両方で制限されます：

| ## エンドポイント | ## 制限 |
|----------|-------|
| `POST /oauth/register` | ### 分 5 件 |
| `POST /oauth/token` | ### 分 30 件 |
| `POST /oauth/revoke` | ### 分 30 件 |
| `POST /oauth/introspect` | ### 分 30 件 |

レート制限が行われると、サーバーは HTTP 429（リクエストが多すぎます）を返します。

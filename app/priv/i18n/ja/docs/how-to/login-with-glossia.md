%{
  title: "Glossiaでログイン",
  summary: "OAuth 2.1を使用して、ユーザーがGlossiaアカウントでアプリにサインインできるようにします。",
  category: "how-to",
  order: 2
}
---
このガイドでは、アプリケーションに「Glossiaでログイン」を追加する方法を説明します。完了すると、ユーザーはGlossiaアカウントでサインインできるようになり、アプリケーションはユーザーに代わってGlossia APIを呼び出すためのアクセストークンを取得できます。

Glossiaは**PKCE付きOAuth 2.1**（Proof Key for Code Exchange）を使用します。PKCEは、サーバーサイドアプリケーションを含むすべてのクライアントで必須です。

## 1. OAuthアプリケーションを登録する

アプリケーションの登録方法は2つあります。

### オプションA：ダッシュボードから登録する（推奨）

1. Glossiaにサインインし、アカウントダッシュボードに移動します。
2. サイドバーから**API**セクションを開き、**OAuthアプリ**をクリックします。
3. **新規アプリケーション**をクリックします。
4. アプリケーションの**名前**と**コールバックURL**（リダイレクトURIとも呼ばれます）を入力します。
5. **アプリケーションを作成**をクリックします。

作成後、**クライアントID**と**クライアントシークレット**を控えてください。シークレットは一度しか表示されないため、安全に保管してください。

### オプションB：動的クライアント登録

`POST`リクエストを`/oauth/register`に送信します。

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

レスポンスには`client_id`と`client_secret`が含まれます。

## 2. PKCEコードチャレンジを生成する

ユーザーをリダイレクトする前に、PKCEコードベリファイアとコードチャレンジを生成します。

```javascript
function generateCodeVerifier() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return btoa(String.fromCharCode(...array))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function generateCodeChallenge(verifier) {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return btoa(String.fromCharCode(...new Uint8Array(digest)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

const codeVerifier = generateCodeVerifier();
const codeChallenge = await generateCodeChallenge(codeVerifier);
// Store codeVerifier in your session -- you will need it in step 4
```

## 3. ユーザーをGlossiaにリダイレクトする

認可URLを作成し、ユーザーのブラウザーをリダイレクトします。

```
https://glossia.ai/oauth/authorize?
  response_type=code
  &client_id=YOUR_CLIENT_ID
  &redirect_uri=https://myapp.com/auth/callback
  &code_challenge=YOUR_CODE_CHALLENGE
  &code_challenge_method=S256
  &scope=user:read+project:read
  &state=RANDOM_STATE_VALUE
```

**パラメーター：**

| パラメーター | 必須 | 説明 |
|-----------|----------|-------------|
| `response_type` | はい | 常に`code` |
| `client_id` | はい | アプリケーションのクライアントID |
| `redirect_uri` | はい | 登録済みのコールバックURLと一致する必要があります |
| `code_challenge` | はい | PKCEコードチャレンジ（S256） |
| `code_challenge_method` | はい | 常に`S256` |
| `scope` | いいえ | スペース区切りの[スコープ](/docs/reference/apis/authentication)一覧。省略した場合は最小限のアクセス権が使用されます |
| `state` | 推奨 | CSRF攻撃を防ぐためのランダムな文字列。ユーザーが戻った際に、送信した値と一致することを確認してください |

ユーザーには、アプリケーション名と要求されたスコープを示す同意画面が表示されます。ユーザーが承認すると、Glossiaは認可コードを付与してコールバックURLへリダイレクトします。

## 4. コードをトークンと交換する

ユーザーがコールバックURLにリダイレクトされると、URLには`code`パラメーターが含まれます。

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

まず、`state`が手順3で送信した値と一致することを確認します。次に、コードをトークンと交換します。

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=https://myapp.com/auth/callback" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code_verifier=YOUR_CODE_VERIFIER"
```

レスポンス：

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

両方のトークンを安全に保管してください。アクセストークンはAPIリクエストに使用します。リフレッシュトークンは、現在のアクセストークンの有効期限が切れた際に、新しいアクセストークンを取得するために使用します。

## 5. ユーザーに代わってAPIを呼び出す

アクセストークンを使用して、認証済みのAPIリクエストを実行します。

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

アクセスできるエンドポイントは、トークンのスコープによって制限されます。リソース単位の認可も引き続き適用されます。たとえば、`project:read`を持つトークンで読み取れるのは、ユーザーがアクセス権を持つプロジェクトのみです。

## 6. トークンを更新する

アクセストークンの有効期限が切れたら、リフレッシュトークンを使用して、ユーザーに同意フローを再度実行させることなく新しいアクセストークンを取得します。

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. トークンを取り消す

ユーザーがアプリケーションとの連携を解除した場合、またはアクセスが不要になった場合は、トークンを取り消します。

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープを選択する

アプリケーションに必要なスコープのみを要求してください。一般的な組み合わせを以下に示します。

| ユースケース | スコープ |
|----------|--------|
| ユーザープロフィールの読み取り | `user:read` |
| プロジェクトとコンテンツの読み取り | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 組織への完全なアクセス | `user:read organization:read organization:write members:read members:write project:read project:write` |

利用可能なすべてのスコープについては、[スコープの完全なリファレンス](/docs/reference/apis/authentication)を参照してください。

## ディスカバリーエンドポイント

アプリケーションは、サーバーメタデータを取得することでGlossiaのOAuthエンドポイントを自動的に検出できます。

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

このリクエストは、`authorization_endpoint`、`token_endpoint`、`revocation_endpoint`などの詳細を含むJSONドキュメントを返します。ディスカバリーを使用すると、エンドポイントが変更されても連携を維持できます。

## エラー処理

### 認可エラー

ユーザーが同意を拒否した場合、または認可中に問題が発生した場合、Glossiaは`error`パラメーターを付けてコールバックURLにリダイレクトします。

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

一般的なエラーコードは次のとおりです。

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーが認可リクエストを拒否しました |
| `invalid_request` | リクエストに必須パラメーターがありません |
| `invalid_scope` | リクエストされたスコープのうち、1つ以上が無効です |

### トークンエラー

トークンエンドポイントは、JSON形式のエラー本文とともにHTTP 400を返します。

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート制限

OAuthエンドポイントにはIPごとのレート制限があります。制限に達すると、HTTP 429が返されます。詳細については、[レート制限のリファレンス](/docs/reference/apis/authentication)を参照してください。

## セキュリティチェックリスト

本番環境に移行する前に、実装が以下のプラクティスに従っていることを確認してください。

- 本番環境のコールバックURLには常にHTTPSを使用する
- CSRFを防止するため、コールバックの`state`パラメーターを検証する
- 保存時のトークンを暗号化する
- クライアント側のJavaScriptやブラウザーのURLでトークンを公開しない
- 必要最小限のスコープのみを使用する
- リフレッシュトークンを使用して、トークンの有効期限切れを適切に処理する
- ユーザーが連携を解除した場合、またはアカウントを削除した場合は、トークンを取り消す
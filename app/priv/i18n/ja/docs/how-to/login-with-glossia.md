%{
  title: "Glossia でログイン",
  summary: "ユーザーは OAuth 2.1 を使用して、Glossia アカウントでアプリにサインインできます。",
  category: "使い方",
  order: 2
}
---
このガイドでは、アプリに「Glossia ログイン」を追加する方法を案内します。完了時には、ユーザーは自分の Glossia アカウントでサインインでき、アプリはユーザーの代わりに Glossia API を呼び出すためのアクセストークンを取得できるようになります。

Glossia は **PKCE を含む OAuth 2.1** （Proof Key for Code Exchange）。サーバーサイドアプリケーションを含むすべてのクライアントで PKCE は必須です。

## 1\. OAuth アプリケーションを登録する

アプリの登録には 2 つの方法があります:

### オプション A: ダッシュボード経由（推奨）

1. Glossia にサインインし、アカウントダッシュボードへ移動します。
2. サイドバーの **API** セクションをクリックしてください **OAuth アプリケーション**。
3. クリック **新規アプリケーション**。
4. アプリを **名前** と **コールバック URL** （リダイレクト URI も同じです）。
5. クリック **アプリを作成**。

作成後、以下を記録し **クライアント ID** と **クライアントシークレット**。シークレットは一度だけ表示されるため、安全に保管してください。

### オプション B: 動的クライアント登録

送信 `POST` リクエスト宛先 `/oauth/register`：

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

レスポンスには `client_id` および `client_secret`。

## 2\. PKCE コード チャレンジを生成

ユーザーをリダイレクトする前に、PKCE コード検証者とコードチャレンジを生成します：

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

## 3\. ユーザーを Glossia にリダイレクト

認証 URL を作成し、ユーザーのブラウザをリダイレクト：

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**パラメータ:**

| パラメータ | 必須 | 説明 |
|-----------|----------|-------------|
| `response_type` | はい | 常に `code` |
| `client_id` | はい | アプリケーションのクライアント ID |
| `redirect_uri` | はい | 登録されたコールバック URL と一致する必要があります |
| `code_challenge` | はい | PKCE コード チャレンジ (S256) |
| `code_challenge_method` | はい | 常に `S256` |
| `scope` | No | スペース区切りで指定 | [スコープ](/docs/reference/apis/authentication). 省略時は最小限の権限にデフォルト設定されます |
| `state` | 推奨 | CSRF 攻撃を防ぐランダムな文字列です。ユーザーが戻った際に一致していることを確認してください |

ユーザーはあなたのアプリケーション名とリクエストされた スコープ を示す同意画面を確認します。承認後、Glossia は認証コードを付与してコールバック URL にリダイレクトします。

## 4\. コードをトークンに交換

ユーザーがコールバック URL にリダイレクトされると、その URL にはパラメータが含まれます `code` パラメータ:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

まず、～をご確認してください `state` がステップ 3 で送ったものと同じか。次に、コードをトークンに交換してください：

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

レスポンス:

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

両方のトークンを安全に保管してください。アクセストークンは API リクエストに使用されます。リフレッシュトークンは、現在のトークンが期限切れになった際に、新しいアクセストークンを取得するために使用されます。

## 5\. ユーザーの代わりに API を呼び出す

アクセストークンを使用して認証された API リクエストを送信します:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセスできるエンドポイントを制限します。リソースレベルの権限は引き続き適用されます - たとえば、 `project:read` ユーザーがアクセスできるプロジェクトの読み取りのみが可能です。

## 6\. トークンをリフレッシュ

アクセストークンが期限切れなら、リフレッシュトークンを使用して新しいトークンを取得し、ユーザーを同意フローに再度通すことなく：

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. トークンの無効化

ユーザーがアプリとの接続を解除した場合、またはもはやアクセスが不要な場合は、トークンを無効化してください：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープの選択

アプリケーションに必要なスコープのみをリクエストしてください。一般的な組み合わせをいくつか示します：

| ユースケース | スコープ |
|----------|--------|
| ユーザープロフィールの読み取り | `user:read` |
| プロジェクトとコンテンツの閲覧 | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 組織全体の完全アクセス | `user:read organization:read organization:write members:read members:write project:read project:write` |

以下の [全スコープ参照](/docs/reference/apis/authentication) 利用可能なすべてのスコープに対して。

## 検出エンドポイント

アプリケーションはサーバーのメタデータを取得することで、Glossia の OAuth エンドポイントを自動的に検出できます:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これは、以下を含む JSON ドキュメントを返します `authorization_endpoint`、 `token_endpoint`再構成されたドキュメントは以前検証に失敗しました：Markdown テキストリテラルの回復は、一致する長さの JSON 文字列配列を返す必要があります `revocation_endpoint`、およびその他の詳細。発見機能を使用することで、統合はエンドポイントの変更に対して強固になります。

## エラー処理

### 認証エラー

ユーザーが同意を拒否した場合や、認証中に問題が発生した場合、Glossia はあなたのコールバック URL にエラー `error` パラメータ:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

一般的なエラー コード:

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは認証リクエストを拒否しました |
| `invalid_request` | 必要なパラメータが不足しています |
| `invalid_scope` | 要求されたスコープの 1 つ以上が無効です |

### トークンエラー

トークンエンドポイントは JSON エラーボディで HTTP 400 を返します:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート制限

OAuth エンドポイントは IP ごとにレート制限されています。制限に達すると HTTP 429 が返されます。詳細はこちら [レート制限の参照](/docs/reference/apis/authentication) 詳細については。

## セキュリティチェックリスト

本番環境へ移行する前に、実装がこれらのプラクティスに従っていることを確認してください。

- 本番環境では、コールバック URL には常に HTTPS を使用してください。
- バリデーションを、 `state` コールバックパラメータを確認して CSRFを防ぐ。
- トークンを暗号化して保存する。
- クライアントサイドの JavaScript またはブラウザの URL にトークンを決して公開しないでください。
- 必要な最小限のスコープを使用してください。
- リフレッシュトークンを使用してトークンの有効期限切れを円滑に処理してください。
- ユーザーが接続を切断またはアカウントを削除した場合、トークンを無効化してください。
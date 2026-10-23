%{
  title: "Glossia でログイン",
  summary: "OAuth 2.1 を使用して、ユーザーが自身の Glossia アカウントでお使いのアプリにサインインできるようにします。",
  category: "チュートリアル",
  section: "platform",
  order: 2
}
---

このガイドでは、"Glossia でログイン"機能をアプリケーションに追加する方法を案内します。終わる頃には、ユーザーが自身のGlossiaアカウントでサインインできるようになり、あなたのアプリはGlossia APIを代わりに呼び出すためのアクセステークンを取得できます。

Glossiaは**OAuth 2.1 with PKCE**（コード交換用のプロックキー）を使用しています。PKCEはすべてのクライアント、包括的にサーバーサイドアプリケーションが必要のものとなります。

## 1. OAuth アプリケーションを登録する

アプリケーションを登録するには2つの選択肢があります:

### オプションA: ダッシュボードを経由（推奨）

1. Glossiaにサインインし、アカウントダッシュボードに進みます。
2. サイドバーから**API**セクションを開き、**OAuth apps**をクリックします。
3. **New application**をクリックします。
4. アプリケーション**name**と**callback URL**（リダイレクトURIとも呼ばれます）を入力します。
5. **Create application**をクリックします。

作成後、**Client ID**と**Client secret**をメモします。シークレットは1回のみ表示されるため、安全に保存してください。

### オプションB: ダイナミッククライアント登録

`POST` リクエストを `/oauth/register` へ送信します：

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

レスポンスは`client_id`と`client_secret`を含みます。

## 2. PKCEコードチャレンジを生成する

ユーザーをリダイレクトする前に、PKCEコードバリデーターと挑战を生成します:

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

認証URLを構築し、ユーザーのブラウザをリダイレクトします:

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

**Parameters:**

| パラメータ | 必須 | 説明 |
|-----------|----------|-------------|
| `response_type` | Yes | Always `code` |
| `client_id` | Yes | あなたのアプリケーションのクライアントID |
| `redirect_uri` | Yes | 登録されたリダイレストURLと一致する必要があります |
| `code_challenge` | Yes | PKCEコードチャレンジ（S256） |
| `code_challenge_method` | Yes | Always `S256` |
| `scope` | No | スペース区切りリストの[scopes](/docs/reference/apis/authorization)。省略された場合、アクションスコープは授与されません |
| `state` | 推奨 | CSRF攻撃を防ぐためのランダム文字列。ユーザーが戻った際に一致するか確認してください |

ユーザーはあなたのアプリケーション名と登録されたスコープを表示する同意画面を見 synchronizedされます。その後、Glossiaは同意でのあなたのカックバックURLに認証コードと共にリダイレクトします。

## 4. コードからトークンを交換する

ユーザーがあなたのコールバックURLへリダイレクトされると、URLは`code`パラメータを含んでいるようになります:

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

まず、`state`がステップ3で送信したものと一致するか確認してください。次に、コードをトークンを交換します:

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

両方のトークンを安全に保存してください。アクセストークンは API リクエストに使用されます。現在のトークンが期限切れになった際、新しいアクセストークンを取得するにはリフレッシュ トークンを使用します。

## 5. ユーザーの代わりに API を呼び出す

認証された API リクエストを作成するには、アクセストークンを使用します:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセスできるエンドポイントを制限します。リソースレベルの認証は依然として適用されます。例えば、`project:read` を持つトークンは、ユーザーがアクセスできるプロジェクトのみを読み取ることができます。

## 6. トークンを更新する

アクセストークンが期限切れになったとき、ユーザーを同意フローに再度送らずに、リフレッシュ トークンを使用して新しいトークンを取得します:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. トークンを取り消す

ユーザーがアプリの接続を解除する場合、またはこれ以上アクセス権を必要としない場合は、トークンを取り消します:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープの選択

アプリケーションに必要なスコープのみをリクエストしてください。一般的な組み合わせは以下の通りです:

| 使用事例 | スコープ |
|----------|--------|
| ユーザー プロフィールの読み取り | `user:read` |
| プロジェクトとコンテンツの読み取り | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 組織リソースの管理 | `user:read organization:read organization:write members:read members:write project:read project:write` |

利用可能なすべてのスコープについては[scopes reference](/docs/reference/apis/authorization) を参照してください。

## 発見エンドポイント

サーバーメタデータをフェッチすることで、アプリケーションは Glossia の OAuth エンドポイントを自動的に発見できます:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これには`authorization_endpoint`, `token_endpoint`, `revocation_endpoint`, およびその他の詳細を含む JSON ドキュメントが返されます。発見機能を使用することで、統合はエンドポイントの変更に対して強固になります。

## エラー処理

### 認証エラー

ユーザーが同意を拒否するか、認証中に問題が発生した場合は、Glossia は`error` パラメータを含むコールバック URL にリダイレクトします:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

一般的なエラーコード:

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは認証リクエストを拒否しました |
| `invalid_request` | リクエストに必要なパラメータが一つ以上欠落しています |
| `invalid_scope` | リクエストされたスコープの一つ以上が無効です |

### トークンエラー

トークン エンドポイントは JSON エラーボディと共に HTTP 400 を返します:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート制限

OAuth エンドポイント は IP ごとにレート制限されます。制限に到達した場合は HTTP 429 を受信します。詳細については[rate limiting reference](/docs/reference/apis/authentication) を参照してください。

## セキュリティ チェックリスト

本番環境展開前に、実装がこれらのプラクティスに従っていることを確認してください:

- 本番環境のコールバック URL には常に HTTPS を使用してください
- CSRF を防止するためにコールバックの`state` パラメータを検証してください
- トークンを暗号化状態のままで保存してください
- クライアント側 JavaScript またはブラウザの URL にトークンを公開しないでください
- 必要な最小限のスコープのみを使用してください
- リフレッシュトークンを使用してトークンの期限切れを適切に処理してください
- ユーザーがアプリから切断またはアカウントを削除した場合は、トークンを取り消してください

%{
  title: "Glossia でログイン",
  summary: "ユーザーは OAuth 2.1 を使用して、Glossia アカウントでアプリにサインインできます。",
  category: "チュートリアル",
  section: "platform",
  order: 2
}
---

本ガイドでは「Glossia ログイン」をアプリに追加する手順を案内します。完了後には、ユーザーは Glossia アカウントでサインインでき、アプリはユーザーの代わりの API 呼び出しに必要なアクセストークンを取得できます。

Glossia は **OAuth 2.1 および PKCE** (コード交換のための証明キー) を使用します。PKCE はすべてのクライアント、サーバーサイドアプリケーションにも必須です。

## 1. OAuth アプリケーションを登録する

アプリケーションの登録には 2 つの方法があります：

### 選択肢 A：ダッシュボード経由（推奨）

1. Glossia にサインインし、アカウントダッシュボードへ移動します。
2. サイドバーの **API** セクションを開き、**OAuth アプリ** をクリックします。
3. **新しいアプリケーション** をクリックします。
4. アプリケーションの **名前** および **コールバック URL**（リダイレクト URI も参照）を入力します。
5. **アプリケーションを作成** をクリックします。

作成後、**クライアント ID** および **クライアント Secret** を記録します。Secret は一度のみ表示されるため、安全に保管してください。

### 選択肢 B：ダイナミッククライアント登録

`POST` リクエストを `/oauth/register` に送信します：

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

レスポンスには `client_id` および `client_secret` が含まれます。

## 2. PKCE コードチャレンジを生成する

ユーザーをリダイレクトする前に、PKCE コード検証者とチャallenge を生成します：

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

## 3. ユーザーを Glossia にリダイレクト

認証 URL を作成して、ユーザーのブラウザへリダイレクトします：

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

**パラメーター:**

| パラメーター | 必須 | 説明 |
|-----------|----------|-------------|
| `response_type` | 必須 | 常に `code` |
| `client_id` | 必須 | あなたのアプリケーションのクライアント ID |
| `redirect_uri` | 必須 | 登録されたコールバック URL と一致する必要があります |
| `code_challenge` | 必須 | PKCE コードチャレンジ (S256) |
| `code_challenge_method` | 必須 | 常に `S256` |
| `scope` | 必須 | スペース区切りの [スコープ](/docs/reference/apis/authorization) リスト。省略された場合はアクションスコープは付与されません |
| `state` | 推奨 | CSRF 攻撃を防ぐためのランダム文字列。ユーザーが戻ってきた際には対応を確認してください |

ユーザーはあなたのアプリケーション名と要求されたスコープが表示された同意画面を確認し、承認すると、Glossia は承認コードと共にコールバック URL にリダイレクトします。

## 4. コードをトークンとの交換

ユーザーがコールバック URL にリダイレクトされると、URL には `code` パラメータが含まれます：

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

まず `state` がステップ 3 で送信されたものと一致することを確認します。その後、コードをトークンと交換します：

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

両方のトークンを安全に保管してください。アクセストークンは API リクエストに使用されます。リフレッシュトークンは有効期限が切れた場合、新しいアクセストークンを取得するために使用されます。

## 5. ユーザーの代わりに API を呼び出す

アクセストークンを使用して認証された API リクエストを発行：

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセス可能なエンドポイントを制限します。リソースレベルの認証も引き続き適用されます。例えば、`project:read` を持つトークンはユーザーがアクセスできるプロジェクトのみを読み込むことができます。

## 6. トークンのリフレッシュ

アクセストークンの有効期限が切れた場合、再度同意フローを通じてユーザーを送信することなく、リフレッシュトークンを使用して新しいトークンを取得：

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. トークンの無効化

ユーザーがアプリを解除する場合、またはアクセスが不要になった場合、トークンを無効化：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープの選択

アプリケーションに必要なスコープのみをリクエストしてください。一般的な組み合わせは以下の通りです：

| 使用例 | スコープ |
|----------|--------|
| ユーザープロフィールの読み取り | `user:read` |
| プロジェクトとコンテンツの読み取り | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 組織リソースの管理 | `user:read organization:read organization:write members:read members:write project:read project:write` |

利用可能なすべてのスコープについては [スコープの参照](/docs/reference/apis/authorization) をご覧ください。

## ディスカバリーエンドポイント

アプリケーションはサーバーメタデータを取得することで、Glossia の OAuth エンドポイントを自動的に特定できます：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これは `authorization_endpoint`, `token_endpoint`, `revocation_endpoint`, およびその他の詳細を含む JSON ドキュメントを返します。ディスカバリーを使用することで、統合はエンドポイントの変更に対して堅牢になります。

## エラー処理

### 認証エラー

ユーザーが同意を拒否する場合、または認証中に何らかの問題が発生した場合、Glossia は `error` パラメータが付いたコールバック URL にリダイレクト：

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

一般的なエラーコード：

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは認証リクエストを拒否しました |
| `invalid_request` | リクエストに必須パラメータが不足しています |
| `invalid_scope` | リクエストされたスコープの 1 つ以上が無効です |

### トークンエラー

トークンエンドポイントは JSON エラーボディを含む HTTP 400 を返します：

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート制限

OAuth エンドポイントは IP ごとにレート制限されています。制限に達すると HTTP 429 が返されます。詳細については [レート制限の参照](/docs/reference/apis/authentication) をご覧ください。

## セキュリティチェックリスト

本番環境に移行する前に、実装がこのプラクティスに従っていることを確認してください：

- 本番環境のコールバック URL には常に HTTPS を使用してください
- `state` パラメータをコールバックで検証して CSRF を防止
- トクierungs エンダーでトークンを暗号化して保存
- クライアントサイドの JavaScript やブラウザ URL にトークンを表示してはいけません
- 必要最低限のスコープのみを使用してください
- リフレッシュトークンを使用してトークンの有効期限を適切に処理してください
- ユーザーがアプリを解除し、またはアカウントを削除した場合、トークンを無効化：

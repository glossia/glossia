%{
  title: "Glossia でログイン",
  summary: "OAuth 2.1 を使用した Glossia アカウントでアプリへのサインインが可能です。",
  category: "使い方",
  order: 2
}
---
このガイドでは、お使いのアプリケーションに「Login with Glossia」を追加する手順を案内します。これにより、ユーザーは Glossia アカウントでサインインでき、アプリはユーザーの代わりに Glossia API を呼び出すためにアクセストークンを取得できます。

Glossia は～を使用。 **OAuth 2.1 with PKCE** （Proof Key for Code Exchange）です。PKCE はすべてのクライアント、サーバーサイドアプリケーションを含め必須です。

## 1\. OAuth アプリケーションを登録

アプリケーションを登録する方法には 2 つあります：

### オプション A: ダッシュボード経由（推奨）

1. Glossia にサインインし、アカウントダッシュボードへ移動してください。
2. サイドバーにある API **API** セクションをクリックして、 **OAuth アプリ**.
3. クリック **新しいアプリケーション**.
4. アプリケーションを **名** と **コールバック URL** （リダイレクト URI と呼ばれる）
5. クリック **アプリケーションを作成**。

作成後、以下の **クライアント ID** と **クライアントシークレット**. シークレットは一度のみ表示されるため、安全に保存してください。

### オプション B: 動的クライアント登録

リクエストを送信 `POST` 宛先に `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

レスポンスには含まれます `client_id` と `client_secret`。

## 2\. PKCE コード照合を生成

ユーザーのリダイレクト前に、PKCE コード検証と照合を生成：

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
| `code_challenge` | はい | PKCE コードチャレンジ (S256) |
| `code_challenge_method` | はい | 常に `S256` |
| `scope` | 番号 | スペース区切りリストの [スコープ](/docs/reference/apis/authentication). 省略された場合は最小限のアクセス権限がデフォルトです |
| `state` | 推奨 | ユーザーが戻った際に一致を確認する CSRF 攻撃を防止するランダムな文字列 |

ユーザーはご自身のアプリケーション名と要求されたスコープを表示する同意画面が表示されます。承認後、Glossia は認可コードを伴ってコールバック URL へリダイレクトします。

## 4\. コードをトークンに交換する

ユーザーがコールバック URL へリダイレクトされた場合、URL には `code` パラメータ：

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

まず、確認してください。 `state` ステップ 3 で送信したものと一致している。次に、コードをトークンに交換してください：

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

両方のトークンを安全に保存してください。アクセストークンは API リクエストに使用されます。リフレッシュ トークンは、有効期限が切れた場合に新しいアクセストークンを取得するために使用されます。

## 5\. ユーザーの代わりに API を呼び出す

アクセストークンを使用して、認証済み API リクエストを送信:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセス可能なエンドポイントを制限します。リソースレベルの認可も依然として適用されます - 例えば、トークンでは `project:read` ユーザーがアクセスできるプロジェクトのみを読み込むことができます。

## 6\. トークンをリフレッシュする

アクセストークンが切れたら、ユーザーを同意フローへ再び通すことなく、リフレッシュ トークンを使って新しいアクセストークンを取得します:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. トークンの無効化

ユーザーがアプリを切断した場合、またはもはやアクセスが必要なくなった場合、トークンを無効化してください：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープを選択

アプリケーションに必要なスコープのみをリクエストしてください。ここでは一般的な組み合わせを以下に示します：

| ユースケース | スコープ |
|----------|--------|
| ユーザープロフィールの読み取り | `user:read` |
| プロジェクトとコンテンツの閲覧 | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 組織全体の完全アクセス | `user:read organization:read organization:write members:read members:write project:read project:write` |

参照 [完全スコープ参照](/docs/reference/apis/authentication) 利用可能なすべてのスコープに対して。

## ディスカバリーエンドポイント

サーバーメタデータを取得することで、あなたのアプリケーションは自動的に Glossia の OAuth エンドポイントを検出できます：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これは、以下のを含む JSON ドキュメントを返します。 `authorization_endpoint`, `token_endpoint`再結合されたドキュメントが以前検証に失敗しました：Markdown テキスト文字列の回復は同等の長さの JSON 文字列配列を返す必要があります `revocation_endpoint`、およびその他の詳細。ディスカバリーを使用することで、統合はエンドポイントの変更にも対応可能です。

## エラー処理

### 認証エラー

ユーザーが同意を拒否し、または認証中に問題が発生した場合、Glossia はあなたのコールバック URL へ `error` パラメータ:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

共通エラーコード:

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは認証リクエストを拒否しました |
| `invalid_request` | 必須パラメータが不足しています |
| `invalid_scope` | 指定されたスコープのいずれかが無効です |

### トークンエラー

トークンエンドポイントは HTTP 400 を返し、JSON エラーボディを含みます:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート制限

OAuth エンドポイントでは各 IP あたりにレート制限が適用されます。制限に達すると HTTP 429 が返されます。詳細は [レート制限参照](/docs/reference/apis/authentication) 詳細については。

## セキュリティチェックリスト

本番環境へ移行する前に、実装が以下の実践に従うことを確認してください：

- 本番環境のコールバック URL には常に HTTPS を使用してください。
- Validate の `state` パラメータを確認することで CSRF を防ぐ
- トークンを暗号化して格納してください
- クライアントサイドの JavaScript またはブラウザの URL にトークンを公開しないでください
- 必要な最小限のスコープのみを使用してください
- リフレッシュトークンを使用して、トークンの有効期限を円滑に処理してください
- ユーザーが接続を解除またはアカウントを削除した際にトークンを無効化してください
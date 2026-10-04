%{
  title: "Glossia でログイン",
  summary: "ユーザーが OAuth 2.1 を使用した Glossia アカウントでアプリにログインできるようにします。",
  category: "ハウツー",
  section: "platform",
  order: 2
}
---
このガイドでは、アプリケーションに「Glossia ログイン」を追加する手順を案内します。完了すると、ユーザーは自身の Glossia アカウントでサインインでき、アプリはユーザーの代わりに Glossia API を呼び出すためのアクセストークンを取得できるようになります。

Glossia は **OAuth 2.1 with PKCE** （Proof Key for Code Exchange）。PKCE は、サーバーサイドアプリケーションを含むすべてのクライアントに対して必須です。

## 1\. OAuth アプリケーションを登録する

アプリケーションの登録には 2 つの方法があります:

### オプション A: ダッシュボード経由（推奨）

1. Glossia にサインインし、アカウントダッシュボードへ移動します。
2. を開いて **API** サイドバーのセクションをクリックし、然后点击 **OAuth アプリ**。
3. をクリックして **新しいアプリ**。
4. アプリケーションを **名前** と **コールバック URL** （リダイレクト URI と呼びます。）
5. クリック **アプリケーションを作成**。

作成後、以下の **クライアント ID** と **クライアントシークレット**。シークレットは一度しか表示されないため、安全に保管してください。

### オプション B: ダイナミッククライアント登録

送信 `POST` リクエストを `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

レスポンスには含まれます `client_id` および `client_secret`.

## 2\. PKCE のコードチャレンジを生成する

ユーザーをリダイレクトする前に、PKCE のコード検証トークンとコードチャレンジを生成してください：

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

認証 URL を構築して、ユーザーのブラウザをリダイレクトしてください：

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**パラメーター:**

| パラメーター | 必須 | 説明 |
|-----------|----------|-------------|
| `response_type` | はい | 常時 `code` |
| `client_id` | はい | お使いのアプリケーションのクライアント ID
| `redirect_uri` | はい | 登録済みのコールバック URL と一致する必要があります |
| `code_challenge` | はい | PKCE コード チャレンジ (S256) |
| `code_challenge_method` | はい | 常に `S256` |
| `scope` | No. | スペース区切りの [スコープ](/docs/reference/apis/authorization). アクションスコープは省略された場合許可されません |
| `state` | 推奨 | CSRF 攻撃を防止するためのランダムな文字列です。ユーザーが戻ってきた際に、一致していることを確認してください |

ユーザーは、あなたのアプリケーション名とリクエストされたスコープが表示された同意画面を見ます。承認後、Glossia は認証コードと共にあなたのコールバック URL にリダイレクトします。

## 4\. コードをトークンに交換する

ユーザーがコールバック URL にリダイレクトされると、その URL には a を含みます `code` パラメータ:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

まず、ご確認ください `state` 3 ステップで送信したものと一致しているか。その後、コードをトークンに交換してください:

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

両方のトークンを安全に保管してください。アクセストークンは API リクエストに使用されます。リフレッシュトークンは、現在のトークンが期限切れになった際に新しいアクセストークンを取得するために使用されます。

## 5\. ユーザーの代わりに API を呼び出す

アクセストークンを使用して認証済み API リクエストを作成してください:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセス可能なエンドポイントを制限します。リソースレベルの権限は引き続き適用されます。例えば、権限を持つトークン `project:read` ユーザーがアクセスできるプロジェクトのみ閲覧できます。

## 6\. トークンのリフレッシュ

アクセストークンが期限切れになった場合、ユーザーを再度同意フローに送ることなく、リフレッシュトークンを使用して新しいトークンを取得します:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. トークンの無効化

ユーザーがアプリを解除した場合、またはアクセス権がもはや不要な場合は、トークンを無効化してください：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープの選択

アプリに必要なスコープのみをリクエストしてください。一般的な組み合わせの例：

| 使用ケース | スコープ |
|----------|--------|
| ユーザープロフィールの読み取り | `user:read` |
| プロジェクトとコンテンツの閲覧 | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 組織リソースの管理 | `user:read organization:read organization:write members:read members:write project:read project:write` |

スコープのドキュメントを [参照](/docs/reference/apis/authorization) 利用可能なすべてのスコープに対して。

## ディスカバリーエンドポイント

アプリケーションはサーバーメタデータを取得することで、自動的に Glossia の OAuth エンドポイントを発見できます：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これにより、以下の情報を含む JSON ドキュメントが返されます `authorization_endpoint`以前、再構成されたドキュメントが検証に失敗しました：Markdown テキストリテラルの復元が無効な JSON を返しました `token_endpoint`再結合されたドキュメントは以前検証に失敗しました：Markdown テキストリテラルの復元が無効な JSON を返しました `revocation_endpoint`、およびその他の詳細。自動検出機能により、統合はエンドポイントの変更にも耐性があります。

## エラーハンドリング

### 認証エラー

ユーザーが同意を拒否した場合、または認証中に問題が発生した場合、Glossia はあなたのコールバック URL へリダイレクトします `error` パラメータ:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

共通エラーコード:

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは認証リクエストを拒否しました |
| `invalid_request` | リクエストに必須のパラメーターが不足しています |
| `invalid_scope` | リクエストされたスコープのいずれかが無効です |

### トークンエラー

トークンエンドポイントは、HTTP 400 で JSON エラーレスポンスを返します:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート制限

OAuth エンドポイントは IP ごとにレート制限されます。制限に達した場合、HTTP 429 を受信します。ご参照ください。 [レート制限の参照資料](/docs/reference/apis/authentication) 詳細については。

## セキュリティ チェックリスト

本番展開前に、実装が以下のプラクティスに従っていることを確認してください：

- 本番環境では、コールバック URL に常にある HTTPS を使用してください
- 検証する `state` コールバックパラメータを CSRF を防ぐため
- 暗号化されたトークンを保存する
- クライアントサイドの JavaScript またはブラウザの URL にトークンを暴露しないでください
- 必要最低限のスコープのみを使用してください
- リフレッシュトークンを使用してトークンの有効期限切れを円滑に処理してください
- ユーザーが接続を切断またはアカウントを削除した場合、トークンを無効化してください
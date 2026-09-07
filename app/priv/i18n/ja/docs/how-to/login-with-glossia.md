%{
  title: "Glossia でログイン",
  summary: "OAuth 2.1 を使用してユーザーが Glossia アカウントでアプリにサインインできるようにする。",
  category: "使い方",
  order: 2
}
---
本ガイドでは、アプリに "Glossia でログイン" を追加する方法を案内します。これにより、ユーザーは Glossia アカウントでサインインでき、アプリはユーザーの代わりに Glossia API を呼び出すためのアクセストークンを取得できるようになります。

Glossia は **OAuth 2.1 with PKCE** （コード交換のための証明鍵）。PKCE は、すべてのクライアント、サーバーサイドアプリケーションを含む場合に必要です。

## 1\. OAuth アプリケーションを登録する

アプリケーションの登録には 2 つの選択肢があります：

### オプション A: ダッシュボード経由（推奨）

1. Glossia にサインインし、アカウントのダッシュボードへ移動してください。
2. を開く **API** サイドバーのセクションをクリック **OAuth アプリ**.
3. クリック **新規アプリケーション**.
4. アプリ **名** と **コールバック URL** （リダイレクト URI の別名です）。
5. クリックしてください **アプリケーション作成**.

作成後、以下の **クライアント ID** と **クライアントシークレット**. シークレットは一度だけ表示されるため、安全に保管してください。

### オプション B：動的クライアント登録

リクエストを `POST` 送信する `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

応答に含まれます `client_id` および `client_secret`.

## 2\. PKCE コードチャレンジを生成する

ユーザーをリダイレクトする前に、PKCE 検証コードおよびコードチャレンジを生成してください：

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

## 3\. ユーザーを Glossia にリダイレクトする

認証 URL を構築し、ユーザーのブラウザをリダイレクトしてください：

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
| `response_type` | はい | 常に | `code` |
| `client_id` | はい | アプリケーションのクライアント ID |
| `redirect_uri` | はい | 登録済みコールバック URL に一致する必要があります |
| `code_challenge` | はい | PKCE コードチャレンジ (S256) |
| `code_challenge_method` | はい | 常に `S256` |
| `scope` | 番号 | スペース区切りリスト [スコープ](/docs/reference/apis/authentication). 省略すると最小のアクセス権になります |
| `state` | 推奨 | CSRF 攻撃を防ぐためのランダムな文字列です。ユーザーが戻ったときに一致しているか確認してください |

ユーザーは、あなたのアプリケーション名と要求されたスコープが表示された同意画面を確認します。承認後、Glossia はあなたのコールバック URL に、認可コードとともにリダイレクトします。

## 4\. コードをトークンに交換

ユーザーがあなたのコールバック URL へリダイレクトされた場合、URL には a `code` パラメータ:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

まず、～を確認 `state` ステップ 3 で送信した内容と一致するかを確認し、その後、コードをトークンに交換してください:

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

両方のトークンを安全に保存してください。アクセストークンは API リクエストに使用され、現在のアクセストークンが期限切れになると、新しいアクセストークンを取得するためにリフレッシュトークンが使用されます。

## 5\. ユーザーの代わりに API を呼び出す

アクセストークンを使用して認証された API リクエストを作成します:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセス可能なエンドポイントを制限します。リソースレベルの権限は依然として適用されます - 例えば、トークンでは `project:read` ユーザーがアクセスできるプロジェクトのみを閲覧できます。

## 6\. トークンをリフレッシュする

アクセストークンが期限切れになった場合、ユーザーを同意フローに再度送ることなく、リフレッシュトークンを使用して新しいアクセストークンを取得してください:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. トークンを失効

ユーザーがアプリとの接続を切断した場合、またはもはやアクセス権限の必要性がない場合は、トークンを失効してください：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープの選択

アプリケーションに必要なスコープのみをリクエストしてください。一般的な組み合わせについては以下に示します：

| ユースケース | スコープ |
|----------|--------|
| ユーザープロファイルの読み取り | `user:read` |
| プロジェクトとコンテンツの読み取り | `user:read project:read voice:read` |
| プロジェクト管理 | `user:read project:read project:write` |
| 組織全体へのアクセス | `user:read organization:read organization:write members:read members:write project:read project:write` |

ご参照 [全スコープ参照](/docs/reference/apis/authentication) 利用可能なすべてのスコープに対して。

## Discovery エンドポイント

サーバーメタデータを取得することで、あなたのアプリケーションは Glossia の OAuth エンドポイントを自動的に発見できます。

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これにより、次のような JSON ドキュメントが返されます。 `authorization_endpoint`再結合されたドキュメントが以前の検証に失敗しました：マークダウンテキストリテラルの回復は、一致する長さの JSON 文字列配列を返す必要があります `token_endpoint`再構成されたドキュメントは以前にバリデーションに失敗しました：Markdown text-literal の復元は、長さが一致する JSON 文字列配列を返す必要があります。 `revocation_endpoint`、その他詳細。ディスカバリーを使用することで、統合はエンドポイントの変更にも堅牢になります。

## エラーハンドリング

### 認証エラー

ユーザーが同意を拒否した場合や、認証中に問題が発生した場合は、Glossia がコールバック URL にリダイレクトし、 `error` パラメータ：

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

主なエラーコード：

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは認証リクエストを拒否しました |
| `invalid_request` | 必要なパラメータが不足しています |
| `invalid_scope` | 要求されたスコープのいずれかが無効です |

### トークンエラー

トークン エンドポイントでは HTTP 400 が返され、JSON エラー本文が含まれます:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート制限

OAuth エンドポイントは IP ごとにレート制限されています。制限に達した場合、HTTP 429 を返します。参照 [レート制限リファレンス](/docs/reference/apis/authentication) 詳細については。

## セキュリティチェックリスト

本番環境へ移行する前に、実装が以下のプラクティスに従っているか確認してください。

- 本番環境では、コールバック URL には常に HTTPS を使用してください。
- ～を検証する `state` コールバック上のパラメータを、CSRF 防止のため
- トークンを暗号化して、静止状態で保存してください。
- クライアントサイドの JavaScript またはブラウザ URL にトークンを公開しない
- 必要なスコープの最小限を使用する
- リフレッシュトークンを用いてトークンの有効期限切れを適切に処理する
- ユーザーが接続を解除またはアカウントを削除した際にトークンを無効化する
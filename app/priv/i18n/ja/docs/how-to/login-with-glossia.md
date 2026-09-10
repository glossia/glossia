%{
  title: "Glossia でログイン",
  summary: "ユーザーが OAuth 2.1 を使用して、自分の Glossia アカウントであなたのアプリにサインインできるようにします。",
  category: "ハウツー",
  order: 2
}
---
このガイドでは「Glossia でログイン」をアプリケーションに追加する方法をご案内します。完了すると、ユーザーは自分の Glossia アカウントでサインインし、アプリケーションはユーザーの代わりに Glossia API を呼び出すためのアクセストークンを取得できます。

Glossia は **OAuth 2.1 with PKCE** （コード キー交換の証明）。PKCE はすべてのクライアントで必須であり、サーバーサイドアプリケーションも含まれます。

## 1\. OAuth アプリケーションを登録する

アプリケーションの登録には次の 2 つの方法があります:

### オプション A: ダッシュボード経由（推奨）

1. Glossia にサインインし、自分のアカウントのダッシュボードに移動してください。
2. サイドバーの **API** セクションを開き、 **OAuth apps**。をクリックします。
3. クリック **New application**。
4. アプリ入力 **名** および **コールバック URL** （リダイレクト URL とも呼ばれます）。
5. クリック **アプリ作成**。

作成後、以下の項目を **クライアント ID** から **クライアントシークレット**. シークレットは一度だけ表示されるため、安全に保管してください。

### オプション B：動的クライアント登録

送信する `POST` リクエスト先を `/oauth/register`：

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

レスポンスに含まれます `client_id` 、 `client_secret`.

## 2\. PKCE コードチャレンジを生成

ユーザーをリダイレクトする前に、PKCE のコード検証値とコードチャレンジを生成：

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

## 3\. ユーザーを Glossia へリダイレクト

認証 URL を構築し、ユーザーのブラウザへリダイレクト：

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
| `client_id` | はい | お使いのアプリケーションのクライアント ID |
| `redirect_uri` | はい | 登録済みのコールバック URL に一致する必要があります |
| `code_challenge` | はい | PKCE コードチャレンジ (S256) |
| `code_challenge_method` | はい | 常に `S256` |
| `scope` | No | スペース区切りのリスト | [スコープ](/docs/reference/apis/authentication). 省略されている場合は最小アクセスがデフォルトです |
| `state` | 推奨 | CSRF 攻撃を防ぐためのランダムな文字列です。ユーザーが戻った際に一致しているか確認してください |

ユーザーは、アプリケーション名と要求されたスコープが表示された同意画面を見ます。承認後、Glossia は認証コードを含め、あなたのコールバック URL へリダイレクトします。

## 4\. コードをトークンに交換する

ユーザーがあなたのコールバック URL へリダイレクトされると、URL には a が含まれます。 `code` パラメータ:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

まず、確認してください `state` ステップ 3 で送信したものと一致していること。その後、コードをトークンに交換してください：

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

両方のトークンを安全に保管してください。アクセストークンは API リクエストに使用されます。リフレッシュトークンは、現在のものが期限切れになったときに新しいアクセストークンを取得するために使用されます。

## 5\. ユーザー名義で API を呼び出す

認証された API リクエストを作成するには、アクセストークンを使用します:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセス可能なエンドポイントを制限します。リソースレベルの認可も適用されます -- 例えば、トークンでは `project:read` ユーザーにアクセスできるプロジェクトのみを読み込むことができます。

## 6\. トークンのリフレッシュ

アクセストークンの有効期限が切れる場合、ユーザーを同意フローに再度送ることなく、リフレッシュトークンを使用して新しいトークンを取得してください:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. トークンの無効化

ユーザーがアプリとの連携を解除した場合、またはアクセスする必要性がなくなった場合は、トークンを無効化してください:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープの選択

アプリケーションに必要なスコープのみをリクエストしてください。一般的な組み合わせは以下の通りです:

| 使用ケース | スコープ |
|----------|--------|
| ユーザープロフィールの読み取り | `user:read` |
| プロジェクトおよびコンテンツの読取 | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 組織全体への完全アクセス | `user:read organization:read organization:write members:read members:write project:read project:write` |

詳細 [完全スコープの参照](/docs/reference/apis/authentication) 利用可能なすべてのスコープに対して。

## ディスカバリーエンドポイント

アプリケーションはサーバーメタデータを取得することで、自動的に Glossia の OAuth エンドポイントを発見できます：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これは、以下の JSON ドキュメントを返します： `authorization_endpoint`以前に検証に失敗した組み立てられたドキュメント：Markdown テキストリテラルの回復は、対応する長さの JSON 文字列配列を返す必要があります。 `token_endpoint`再構築ドキュメントの検証が以前に失敗しました：Markdown テキストリテラル復元は、一致する長さの JSON 文字列配列を返す必要があります `revocation_endpoint`、他の詳細など。ディスカバリー機能を用いることで、統合はエンドポイントの変更に対して耐性を確保できます。

## エラーハンドリング

### 認証エラー

ユーザーが同意を拒否した場合、または認証中に問題が発生した場合、Glossia はあなたのコールバック URL へエラーコードを `error` パラメータ:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

一般的なエラーコード:

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは認証リクエストを拒否しました |
| `invalid_request` | 必須のパラメータが含まれていません |
| `invalid_scope` | 1 つ以上の要求されたスコープが無効です |

### トークンエラー

トークンエンドポイントは HTTP 400 と JSON エラーボディを返します:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート制限

OAuth エンドポイントは IP ごとにレート制限されます。制限に達すると、HTTP 429 を返します。詳細は [リート制限の参考](/docs/reference/apis/authentication) 詳細は。

## セキュリティチェックリスト

本番へ移行する前に、実装が以下のプラクティスに従っていることを確認してください：

- 本番環境でのコールバック URL では常に HTTPS を使用してください
- Validate the `state` パラメータを検証し、CSRF を防ぐ
- トークンを暗号化して保存してください
- クライアントサイドの JavaScript または ブラウザの URL にトークンを暴露しないでください
- 必要な最小限のスコープのみを使用してください
- リフレッシュトークンを使用して、トークンの失効を適切に処理してください
- ユーザーが接続を解除またはアカウントを削除した場合はトークンを撤回してください
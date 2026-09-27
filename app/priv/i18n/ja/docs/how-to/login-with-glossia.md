%{
  title: "Glossia でログイン",
  summary: "OAuth 2.1 を使用して、ユーザーが Glossia アカウントであなたのアプリにサインインできます。",
  category: "手順",
  section: "プラットフォーム",
  order: 2
}
---
このガイドでは、アプリに "Login with Glossia" を追加する方法を案内します。完了すると、ユーザーは Glossia アカウントでサインインでき、アプリはアクセス トークンを使用してユーザーの代わりに Glossia API を呼び出すことができます。

Glossia は **OAuth 2.1 with PKCE** （Proof Key for Code Exchange）。すべてのクライアント、サーバーサイドのアプリケーションを含め、PKCE が必須です。

## 1\. OAuth アプリケーションを登録する

アプリを登録するには 2 つの方法があります：

### オプション A: ダッシュボード経由（推奨）

1. Glossia にサインインし、アカウントダッシュボードへ移動します。
2. 「を開いて **API** 「サイドバーのセクションを開いてクリックし **OAuth アプリ**。
3. 「をクリックしてください **「を選択してください**.
4. ご入力のアプリケーション **名** および **コールバック URL** （リダイレクト URI とも）.
5. クリック **アプリケーション作成**。

作成後、 **クライアント ID** および **クライアントシークレット**. シークレットは一度のみ表示されるため、安全に保存してください。

### オプション B: 動的クライアント登録

リクエストを `POST` 宛てに送信する `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

応答には `client_id` と `client_secret`.

## 2\. PKCE コードチャレンジを発行

ユーザーをリダイレクトする前に、PKCE コード検証者とコードチャレンジを作成します：

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

## 3\. Glossia へユーザーをリダイレクト

認証 URL を作成して、ユーザーのブラウザをリダイレクトします：

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
| `code_challenge` | はい | PKCE コード チャレンジ (S256) |
| `code_challenge_method` | はい | 常に `S256` |
| `scope` | なし | スペース区切りリスト [スコープ](/docs/reference/apis/authentication). 省略された場合は最小アクセス権限です |
| `state` | 推奨 | CSRF 攻撃防止用のランダム文字列。ユーザーが戻る際に一致を確認してください

ユーザーはアプリケーション名と要求されたスコープが表示された同意画面を確認します。承認後、Glossia は認証コードを伴ってコールバック URL にリダイレクトします。

## 4\. コードをトークンに交換

ユーザーがコールバック URL にリダイレクトされると、URL にはコードが含まれます `code` パラメータ:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

まず、～を確認してください。 `state` ステップ 3 で送信したものと一致しているかを確認してください。次に、コードをトークンに交換してください：

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

両方のトークンを安全に保存してください。アクセストークンは API リクエストに使用されます。リフレッシュトークンは現在のアクセストークンが有効期限切れになると、新しいアクセストークンを取得するために使用されます。

## 5\. ユーザー代わりに API を呼び出す

アクセストークンを使用して認証された API リクエストを作成:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセスできるエンドポイントを制限します。リソースレベルの認証も引き続き適用されます - 例えば、トークンには `project:read` ユーザーがアクセスできるプロジェクトのみを読み取ることができます。

## 6\. トーキンをリフレッシュする

アクセストークンが有効期限切れになると、同意フローを再度通さずに、リフレッシュトークンを使用して新しいトークンを取得できます:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. トークンの無効化

ユーザーがアプリを切断する場合、またはもはやアクセス権限を必要としない場合は、トークンを無効化してください.

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープの選択

アプリケーションに必要なスコープのみをリクエストしてください。一般的な組み合わせを以下に示します:

| 使用事例 | スコープ |
|----------|--------|
| ユーザープロファイルの読み取り | `user:read` |
| プロジェクトとコンテンツの閲覧 | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 全組織への完全アクセス | `user:read organization:read organization:write members:read members:write project:read project:write` |

以下の [全スコープ参照](/docs/reference/apis/authentication) 利用可能なすべてのスコープ。

## 検出用エンドポイント

アプリケーションはサーバーメタデータを取得することで、自動的に Glossia の OAuth エンドポイントを発見できます:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これは、JSON ドキュメントを含め返します `authorization_endpoint`再構築ドキュメントの検証が以前に失敗しました： Markdown テキスト文字列リテラルの回復は、一致する長さの JSON 文字列配列を返す必要があります。 `token_endpoint`再構成されたドキュメントは以前検証に失敗しました：Markdown テキストリテラルの回復は長さが一致する JSON 文字列配列を返す必要があります `revocation_endpoint`\`, およびその他の詳細。ディスカバリー機能を活用することで、統合がエンドポイントの変更に対して堅牢になります。

## エラー処理

### 認証エラー

同意を拒否した場合や、認証中に問題が発生した場合、Glossia はお使いのコールバック URL の `error` パラメータ :

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

よくあるエラーコード:

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは認証要求を拒否しました |
| `invalid_request` | 必須パラメータが不足しています |
| `invalid_scope` | 要求されたスコープのうち 1 つ以上が無効です |

### トークンエラー

トークン エンドポイントは HTTP 400 を返 し、JSON のエラーボディを含みます:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### レート制限

OAuth エンドポイントは IP ごとにレート制限されています。制限に達すると HTTP 429 が返されます。詳細については [レート制限の参照](/docs/reference/apis/authentication) 詳細については

## セキュリティチェックリスト

本番環境へ移行する前に、実装が以下の実践に従っていることを確認してください:

- 本番環境でのコールバック URL には常に HTTPS を使用してください
- 検証する `state` 対象パラメータを、コールバック上で検証し、CSRF を防止する
- トークンを暗号化された状態のまま保持すること
- クライアントサイドの JavaScript またはブラウザの URL にトークンを決して公開しないでください
- 必要な最小限のスコープのみを使用してください
- リフレッシュトークンを使ってトークンの期限切れを適切に処理してください
- ユーザーが接続を切断またはアカウントを削除した際はトークンを無効化してください
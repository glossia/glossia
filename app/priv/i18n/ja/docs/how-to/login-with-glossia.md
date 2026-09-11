%{
  title: "Glossia でログイン",
  summary: "ユーザーが OAuth 2.1 を使用して、Glossia アカウントを通じてアプリにサインインできるようにする。",
  category: "チュートリアル",
  order: 2
}
---
このガイドでは、あなたのアプリケーションに「Glossia でログイン」を追加する方法をご案内します。このガイドを完了すると、ユーザーは Glossia アカウントを使用してサインインでき、あなたのアプリはユーザーの代わりに Glossia API を呼び出すためのアクセストークンを取得できます。

Glossia は利用しています **PKCE を採用した OAuth 2.1** （Proof Key for Code Exchange）PKCE は、サーバーサイドのアプリケーションを含むすべてのクライアントに対して必須です。

## 1\. OAuth アプリケーションの登録

アプリケーションを登録するには、2 つの選択肢があります：

### オプション A：ダッシュボード経由（推奨）

1. Glossia にサインインし、アカウントダッシュボードへ移動してください。
2. を開く **API** のサイドバーのセクション を開いてクリック **OAuth アプリ**。
3. クリック **新しいアプリケーション**。
4. アプリケーションを入力 **名称** および **コールバック URL** (別名リダイレクト URI).
5. クリック **アプリケーションを作成**。

作成後、メモしてください、 **クライアント ID** と **クライアントシークレット**。シークレットは一度のみ表示されるため、安全に保管してください。

### オプション B: ダイナミッククライアント登録

リクエストを `POST` 送信します `/oauth/register`:

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

## 2\. PKCE コード チャレンジを生成する

ユーザーをリダイレクトする前に、PKCE 検証コードおよびチャレンジを生成:

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

認証 URL を構築し、ユーザーのブラウザをリダイレクト:

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
| `response_type` | はい | 常時 `code` |
| `client_id` | はい | アプリの client ID |
| `redirect_uri` | はい | 登録済みのコールバック URL と一致する必要があります |
| `code_challenge` | はい | PKCE コード チャレンジ (S256) |
| `code_challenge_method` | はい | 常に | `S256` |
| `scope` | 番号 | スペース区切りで｜ [scopes](/docs/reference/apis/authentication). 省略された場合は、デフォルトは最小限のアクセスになります｜
｜ `state` ｜推奨｜CSRF 攻撃を防ぐためのランダムな文字列です。ユーザーが戻った際、一致を確認してください｜

ユーザーには、お客様のアプリケーション名と要求されたスコープを表示する同意画面が表示されます。承認後、Glossia はお客様のコールバック URL へ認証コードを伴ってリダイレクトします。

## 4\. コードをトークンに交換する

ユーザーがお客様のコールバック URL へリダイレクトされた場合、URL には...が含まれます `code` パラメータ:

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

まず、 `state` ステップ 3 で送信したものと一致していることを確認してください。次に、コードをトークンに交換します：

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

両方のトークンを安全に保管してください。アクセストークンは API リクエストに使用されます。リフレッシュトークンは現在のが失効した際に新しいアクセストークンを取得するために使用されます。

## 5\. ユーザーの代わりに API を呼び出す

認証された API リクエストを作成するには、アクセストークンを使用してください:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセス可能なエンドポイントを制限します。リソースレベルの認証も引き続き適用されます - たとえば、トークンに `project:read` ユーザーがアクセスできるプロジェクトのみを読み取ることができます。

## 6\. トークンをリフレッシュする

アクセストークンが失効した場合、ユーザーを同意フローに再度送ることなく、リフレッシュトークンを使用して新しいアクセストークンを取得してください:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. トークンの取り消し

ユーザーがアプリの接続を解除した場合、またはアクセスが不要になった場合は、トークンを取り消してください：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープの選択

アプリに必要なスコープのみリクエストしてください。一般的な組み合わせは以下の通りです：

| 使用ケース | スコープ |
|----------|--------|
| ユーザープロフィールの読み取り | `user:read` |
| プロジェクトとコンテンツの閲覧 | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 組織全体へのアクセス | `user:read organization:read organization:write members:read members:write project:read project:write` |

以下の [全スコープの参照](/docs/reference/apis/authentication) 利用可能なすべてのスコープに対して。

## 発見エンドポイント

アプリケーションは、サーバーメタデータを取得することで、Glossia の OAuth エンドポイントを自動的に発見できます：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これは、～を含む JSON ドキュメントを返します `authorization_endpoint`再構成ドキュメントは以前検証に失敗しました：Markdown テキストノード回復処理で空の翻訳が生成されました `token_endpoint`再まとめされたドキュメントが以前検証に失敗しました： Markdown テキストノードの復元により空の翻訳が生成されました `revocation_endpoint`その他の詳細、例など。ディスカバリー機能を使用することで、統合をエンドポイントの変更に対して堅固化できます。

## エラー処理

### 権限付与エラー

ユーザーが同意を拒否した場合、または認証中に問題が発生した場合は、Glossia はあなたのコールバック URL に `error` パラメータ:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

共通エラーコード:

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは権限付与依頼を拒否しました |
| `invalid_request` | リクエストに必須パラメータが不足しています |
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

OAuth エンドポイントは IP アドレスごとにレート制限されます。制限に達した場合、HTTP 429 を受信します。ご参照 [レート制限の参照](/docs/reference/apis/authentication) 詳細については。

## セキュリティ チェックリスト

本番環境へ移行する前に、実装がこれらのプラクティスに従っていることを確認してください:

- 本番環境のコールバック URL には常に HTTPS を使用してください
- 確認する `state` パラメータを、コールバック上で、CSRF を防止する
- 暗号化して保存してください
- クライアントサイドの JavaScript またはブラウザの URL にトークンを決して曝さない
- 必要な最小限のスコープを使用する
- リフレッシュトークンを用いてトークンの期限切れを円滑に処理する
- ユーザーが接続を切断またはアカウントを削除した際にトークンを無効化する
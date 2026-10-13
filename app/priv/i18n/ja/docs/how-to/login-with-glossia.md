%{
  title: "Glossia でログイン",
  summary: "OAuth 2.1 を使用して、Glossia アカウントでアプリへのログインを可能にします。",
  category: "操作ガイド",
  section: "platform",
  order: 2
}
---

このガイドではアプリケーションに「Glossia ログイン」を追加する方法を案内します。完了時には、ユーザーが Glossia アカウントを使用してログインができるようになりますし、あなたのアプリはユーザーを代表して Glossia API を呼び出すためのアクセストークンを取得できます。

Glossia は **OAuth 2.1 with PKCE**（コード交換の証明キー）を使用します。PKCE はサーバーサイドアプリケーションを含むすべてのクライアントで必須です。

## 1. OAuth アプリケーションを登録する

アプリケーションの登録方法には 2 つのオプションがあります：

### オプション A: ダッシュボードを通じて（推奨）

1. Glossia にログインして、アカウントダッシュボードへ移動します。
2. サイドバーの **API** セクションを開き、**OAuth アプリ** をクリックします。
3. **新アプリケーション** をクリックします。
4. アプリケーションの **名称** と **コールバック URL**（リダイレクト URI とも呼ばれる）、を入力します。
5. **アプリ作成** をクリックします。

登録後、**クライアント ID** と **クライアントシークレット** をメモしてください。シークレットは一度だけ表示されるため、安全に保管してください。

### オプション B: ダイナミッククライアント登録

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

レスポンスは `client_id` と `client_secret` を含みます。

## 2. PKCE コードチャレンジを生成する

ユーザーをリダイレクトする前に、PKCE コード検証者とチャレンジを生成します：

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

## 3. ユーザーを Glossia にリダイレクトする

認証 URL を構築し、ユーザーのブラウザをリダイレクトします：

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

**パラメータ:**

| パラメータ | 必須 | 説明 |
|-----------|----------|-------------|
| `response_type` | あり | 常に `code` |
| `client_id` | あり | あなたのアプリケーションのクライアント ID |
| `redirect_uri` | あり | 登録されたコールバック URL と一致する必要があります |
| `code_challenge` | あり | PKCE コードチャレンジ (S256) |
| `code_challenge_method` | あり | 常に `S256` |
| `scope` | なし | [スコープ](/docs/reference/apis/authorization) のスペース区切りリスト。省略された場合はアクションスコープは許可されません |
| `state` | 推奨 | CSRF 攻撃を防ぐためのランダムな文字列。ユーザーが戻る際に一致していることを確認してください |

ユーザーは、アプリケーション名と要求されたスコープが表示された同意画面が表示されます。承認後、Glossia は認証コードとともにコールバック URL にリダイレクトされます。

## 4. コードをトークンに交換する

ユーザーがコールバック URL にリダイレクトされる際、URL には `code` パラメータが含まれます：

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

まず、ステップ 3 に送った `state` と一致するか確認してください。その後、コードをトークンに交換します：

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

両方のトークンを安全に保管してください。アクセストークンは API リクエストに使用されます。リフレッシュトークンは現在のトークンが期限切れになったときに新しいアクセストークンを取得するために使用されます。

## 5. ユーザー代わりに API を呼び出す

アクセストークンを使用して認証済み API リクエストを作成します:

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

トークンのスコープはアクセスできるエンドポイントを制限します。リソースレベルの認証も適用されます -- 例えば、`project:read` を持つトークンはユーザーがアクセスできるプロジェクトのみを読むことができます。

## 6. トークンをリフレッシュする

アクセストークンが期限切れになると、リフレッシュトークンを使用して新しいトークンを取得し、ユーザーを同意フローに再度送らないでください:

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. トークンを取り消す

ユーザーがアプリを解除したか、またはもはやアクセスが不要になった場合には、トークンを取り消します:

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## スコープの選択

必要なスコープのみをリクエストします。一般的な組み合わせ例を示します:

| 使用ケース | スコープ |
|----------|--------|
| ユーザープロフィールの読込み | `user:read` |
| プロジェクトとコンテンツの読込み | `user:read project:read voice:read` |
| プロジェクトの管理 | `user:read project:read project:write` |
| 組織リソースの管理 | `user:read organization:read organization:write members:read members:write project:read project:write` |

すべての利用可能なスコープについては、[スコープの参考情報](/docs/reference/apis/authorization) を参照してください。

## ディスカバリーエンドポイント

アプリケーションはサーバーメタデータを取得することで、Glossia の OAuth エンドポイントを自動的に発見できます:

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

これによって、`authorization_endpoint`, `token_endpoint`, `revocation_endpoint` およびその他の詳細を含む JSON ドキュメントが返されます。ディスカバリーを使用することで、エンドポイントの変化に対する統合の堅牢性が向上します。

## エラー処理

### 認証エラー

ユーザーが同意を拒否した場合、または認証中に何か問題が発生すると、Glossia はエラーパラメータを含むコールバック URL にリダイレクトされます:`error` パラメータ:

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

一般的なエラーコード:

| エラー | 意味 |
|-------|---------|
| `access_denied` | ユーザーは認証リクエストを拒否しました |
| `invalid_request` | リクエストに必須のパラメータが不足しています |
| `invalid_scope` | リクエストしたスコープの一つ以上が無効です |

### トークンエラー

トークンエンドポイントは JSON エラーボディと共に HTTP 400 を返します:

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### RATE limits

OAuth エンドポイントは IP 別レート制限が適用されます。制限に達すると HTTP 429 が返されます。詳細は [レート制限の参考情報](/docs/reference/apis/authentication) を参照してください。

## セキュリティ チェックリスト

本番環境に送る前に、実装がこれらの実践に従うことを確認してください:

- 本番環境でコールバック URL には常に HTTPS を使用する
- CSRF を防ぐためにコールバック上の `state` パラメータを検証する
- トークンを暗号化して保存する
- クライアントサイド JavaScript やブラウザ URL におけるトークンの公開を避免する
- 必要な最小限のスコープのみ使用する
- リフレッシュトークンを使ってトークンの有効期限切れを適切に処理する
- ユーザーがアプリを解除またはアカウントを削除した場合には、トークンを取り消す

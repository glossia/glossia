%{
  title: "使用 Glossia 登录",
  summary: "让用户使用其 Glossia 账户通过 OAuth 2.1 登录到您的应用程序。",
  category: "操作指南",
  order: 2
}
---
本指南将指导您如何将“通过 Glossia 登录”添加到您的应用中。完成后，您的用户将能够通过他们的 Glossia 账户登录，且您的应用将获得访问令牌以便代表他们调用 Glossia API。

Glossia 采用 **OAuth 2.1 与 PKCE** （代码交换证明密钥）。PKCE 对所有客户端（包括服务器端应用程序）都是必需的。

## 1\. 注册您的 OAuth 应用

注册您的应用有两种选项：

### 选项 A：通过控制台（推荐）

1. 登录 Glossia 并进入您的账户控制台。
2. 打开 **API** 侧边栏中的部分并点击 **OAuth 应用**。
3. 点击 **新建应用**。
4. 填写应用程序 **名称** 和 **回调 URL** （也称为重定向 URI）。
5. 点击 **创建应用程序**。

创建后，请注意 **客户端 ID** 和 **客户端密钥**. 密钥仅显示一次，因此请妥善保管。

### 选项 B：动态客户端注册

发送一个 `POST` 请求 `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

响应中包含 `client_id` 和 `client_secret`.

## 2\. 生成 PKCE 代码挑战

在重定向用户之前，生成 PKCE 代码验证器和挑战：

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

## 3\. 将用户重定向到 Glossia

构建授权 URL 并重定向用户浏览器：

    https://glossia.ai/oauth/authorize?
      response_type=code
      &client_id=YOUR_CLIENT_ID
      &redirect_uri=https://myapp.com/auth/callback
      &code_challenge=YOUR_CODE_CHALLENGE
      &code_challenge_method=S256
      &scope=user:read+project:read
      &state=RANDOM_STATE_VALUE

**参数：**

| 参数 | 必需 | 描述 |
|-----------|----------|-------------|
| `response_type` | 是 | 始终 `code` |
| `client_id` | 是 | 您应用的客户端 ID |
| `redirect_uri` | 是 | 必须匹配已注册的回调 URL |
| `code_challenge` | 是 | PKCE 代码挑战 (S256) |
| `code_challenge_method` | 是 | 始终 `S256` |
| `scope` | 无 | 空格分隔的列表 | [作用域](/docs/reference/apis/authentication). 若省略则默认为最小访问权限 |
| `state` | 推荐 | 用于防止 CSRF 攻击的随机字符串。请在用户返回时验证其是否匹配 |

用户将看到一个同意屏幕，显示您的应用名称和请求的作用域。批准后，Glossia 将重定向回您的回调 URL 并携带授权代码。

## 4\. 用代码交换令牌

当用户被重定向回您的回调 URL 时，该 URL 将包含 `code` 参数：

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

首先，核实 `state` 与您在第 3 步中发送的内容匹配。然后将代码兑换为令牌：

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

响应：

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

安全存储这两个令牌。访问令牌用于 API 请求。刷新令牌用于在当前访问令牌过期时获取新的访问令牌。

## 5\. 代表用户调用 API

使用访问令牌进行身份验证 API 请求：

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

令牌的范围限制了你可访问的端点。资源级别的授权仍然适用 - 例如，一个具有 `project:read` 仅能读取用户有访问权限的项目。

## 6\. 刷新令牌

当访问令牌过期时，使用刷新令牌获取新令牌，无需再次让用户通过同意流程：

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. 撤销令牌

当用户断开您的应用连接或您不再需要访问权限时，请撤销令牌：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 选择范围

仅请求您应用程序所需的范围。以下是一些常见组合：

| 使用场景 | 范围 |
|----------|--------|
| 读取用户资料 | `user:read` |
| 查看项目和内容 | `user:read project:read voice:read` |
| 管理项目 | `user:read project:read project:write` |
| 完整组织访问权限 | `user:read organization:read organization:write members:read members:write project:read project:write` |

查看 [完整作用域参考](/docs/reference/apis/authentication) 适用于所有可用范围。

## 发现端点

您的应用程序可以通过获取服务器元数据自动发现 Glossia 的 OAuth 端点：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

这将返回一个包含 `authorization_endpoint`， `token_endpoint`， `revocation_endpoint`，以及其他详细信息。使用发现功能可使集成具备应对端点变化的韧性。

## 错误处理

### 授权错误

如果用户拒绝同意或授权过程中出现问题，Glossia 会将您重定向到您的回调 URL 并附带 `error` 参数:

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

常见错误代码:

| 错误 | 含义 |
|-------|---------|
| `access_denied` | 用户拒绝了授权请求 |
| `invalid_request` | 请求缺少必需参数 |
| `invalid_scope` | 一个或多个请求的作用范围无效 |

### Token 错误

Token 端点返回 HTTP 400 及 JSON 错误体：

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 速率限制

OAuth 端点按 IP 限制速率。如触发限制，您将收到 HTTP 429。查看 [速率限制参考](/docs/reference/apis/authentication) 详见。

## 安全检查清单

在生产环境部署前，请验证您的实现是否遵循以下准则：

- 生产环境的回调 URL 应始终使用 HTTPS
- 验证 `state` 回调参数以防止 CSRF
- 在存储中对令牌进行加密
- 切勿在客户端 JavaScript 或浏览器 URL 中暴露令牌
- 仅使用所需的最小权限范围
- 通过刷新令牌优雅地处理令牌过期
- 当用户断开连接或删除账户时吊销令牌
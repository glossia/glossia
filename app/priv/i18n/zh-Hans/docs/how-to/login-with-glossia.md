%{
  title: "使用 Glossia 登录",
  summary: "让用户使用他们的 Glossia 账户通过 OAuth 2.1 登录您的应用程序。",
  category: "教程",
  section: "平台",
  order: 2
}
---
本指南将引导您为应用程序添加"使用 Glossia 登录"。操作完成后，您的用户即可使用其 Glossia 账户登录，您的应用还将获得访问令牌，以便代表用户调用 Glossia API。

Glossia 使用 **OAuth 2.1 搭配 PKCE** (代码交换证明密钥)。所有客户端都需要 PKCE，包括服务器端应用程序。

## 1\. 注册您的 OAuth 应用程序

注册应用程序有两种方式：

### 选项 A：通过仪表板（推荐）

1. 登录 Glossia 并前往您的账户仪表板。
2. 打开 **API** 侧边栏中的部分并点击 **OAuth 应用**.
3. 点击 **新建应用**.
4. 填写应用 **名称** 和 **回调 URL** (也称为重定向 URI)。
5. 点击 **创建应用**。

创建后，请注意 **客户端 ID** 和 **客户端密钥**。密钥仅显示一次，请妥善保管。

### 选项 B：动态客户端注册

发送一个 `POST` 请求至 `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

响应包含 `client_id` 和 `client_secret`.

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

**参数:**

| 参数 | 必需 | 描述 |
|-----------|----------|-------------|
| `response_type` | 是 | 始终 `code` |
| `client_id` | 是 | 您的应用客户端 ID |
| `redirect_uri` | 是 | 必须匹配已注册的回调 URL |
| `code_challenge` | 是 | PKCE 代码挑战 (S256) |
| `code_challenge_method` | 是 | 始终 `S256` |
| `scope` | 无 | 空格分隔的列表 [作用域](/docs/reference/apis/authentication). 如果省略，则默认为最小访问权限 |
| `state` | 推荐 | 用于防止 CSRF 攻击的随机字符串。用户返回时请验证它是否匹配

用户将看到一个同意屏幕，显示您的应用程序名称和请求的作用域。获得批准后，Glossia 会将他们重定向回您的回调 URL，并附带授权代码。

## 4\. 用代码交换令牌

当用户被重定向回您的回调 URL 时，URL 将包含一个 `code` 参数：

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

首先，确认 `state` 与您在第 3 步中发送的内容一致。然后将代码兑换为令牌：

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

安全存储两个令牌。访问令牌用于 API 请求。刷新令牌用于在现有令牌过期时获取新的访问令牌。

## 5\. 代表用户调用 API

使用访问令牌发出经过身份验证的 API 请求：

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

令牌的权限范围限制您可以访问的端点。资源级授权仍然适用 - 例如，一个拥有 `project:read` 只能读取用户有权访问的项目。

## 6\. 刷新令牌

当访问令牌过期时，使用刷新令牌获取新的访问令牌，而无需再次让用户经历同意流程：

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7\. 撤销令牌

当用户断开您的应用连接，或您不再需要访问权限时，撤销令牌：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 选择作用域

仅请求您的应用程序所需的作用域。以下是一些常见的组合：

| 用例 | 作用域 |
|----------|--------|
| 读取用户资料 | `user:read` |
| 查看项目和内容 | `user:read project:read voice:read` |
| 管理项目 | `user:read project:read project:write` |
| 完整组织访问 | `user:read organization:read organization:write members:read members:write project:read project:write` |

参见 [完整范围参考](/docs/reference/apis/authentication) 适用于所有可用作用域。

## 发现端点

您的应用可以通过获取服务器元数据自动发现 Glossia 的 OAuth 端点：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

这将返回一个包含该的 JSON 文档 `authorization_endpoint`， `token_endpoint`， `revocation_endpoint`，以及其他详细信息。使用发现功能可使集成对端点变更具有弹性。

## 错误处理

### 授权错误

如果用户在授权过程中拒绝同意或出现异常，Glossia 会将您重定向到您的回调 URL 并带有一个 `error` 参数：

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

常见错误代码：

| 错误 | 含义 |
|-------|---------|
| `access_denied` | 用户拒绝了授权请求 |
| `invalid_request` | 请求缺少必需参数 |
| `invalid_scope` | 请求的一个或多个作用域无效 |

### 令牌错误

令牌端点返回 HTTP 400 及 JSON 错误响应体：

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 速率限制

OAuth 端点按 IP 进行速率限制。如果达到限制，将收到 HTTP 429。请参阅 [速率限制参考](/docs/reference/apis/authentication) 详情。

## 安全检查清单

在部署至生产环境前，请验证您的实现是否遵循以下实践：

- 生产环境中的回调 URL 必须使用 HTTPS
- 验证 `state` 回调参数以预防 CSRF
- 将令牌静态加密存储
- 切勿在客户端 JavaScript 或浏览器 URL 中暴露令牌
- 仅使用所需的最小作用域
- 使用刷新令牌优雅处理令牌过期
- 用户断开连接或删除账户时撤销令牌
%{
  title: "使用 Glossia 登录",
  summary: "让用户通过 OAuth 2.1 使用其 Glossia 账户登录您的应用。",
  category: "教程",
  order: 2
}
---
本指南将指导您向应用程序添加"使用 Glossia 登录"。完成后，您的用户将能够使用其 Glossia 账户登录，您的应用程序将拥有一个访问令牌，以便代表他们调用 Glossia API。

Glossia 使用 **OAuth 2.1 及 PKCE** （代码交换证明密钥）。PKCE 对所有客户端均为必需，包括服务端应用程序。

## 1\. 注册您的 OAuth 应用程序

您有两种注册应用程序的选项：

### 选项 A：通过仪表板（推荐）

1. 登录 Glossia 并前往您的账户仪表板。
2. 打开 **API** 在侧边栏中的部分并点击 **OAuth 应用**。
3. 点击 **新应用**。
4. 填写应用 **名称** 和 **回调 URL** （也称为重定向 URI）。
5. 点击 **创建应用**.

创建后，记下 **客户端 ID** 和 **客户端密钥**。密钥仅显示一次，请妥善保管。

### 选项 B：动态客户端注册

发送 `POST` 请求 `/oauth/register`:

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

响应中包含 `client_id` 以及 `client_secret`。

## 2\. 生成 PKCE 代码挑战

在重定向用户之前，生成 PKCE 代码验证器和挑战:

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

构建授权 URL 并重定向用户浏览器:

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
| `client_id` | 是 | 您的应用客户端 ID |
| `redirect_uri` | 是 | 必须匹配已注册的回调 URL |
| `code_challenge` | 是 | PKCE 代码挑战（S256）|
| `code_challenge_method` | 是 | 始终 `S256` |
| `scope` | 编号 | 空格分隔的 [作用域](/docs/reference/apis/authentication)如果省略，则默认为最小访问权限 |
| `state` | 推荐 | 一个用于防止 CSRF 攻击的随机字符串。当用户返回时，请验证它是否匹配 |

用户将看到一个同意屏幕，显示您的应用名称和请求的作用域。在用户批准后，Glossia 将附带授权代码重定向回您的回调 URL。

## 4\. 用代码换取令牌

当用户被重定向回您的回调 URL 时，URL 将包含 `code` 参数：

    https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE

首先，确认 `state` 与您在第 3 步中发送的内容匹配。然后兑换代码以获取令牌：

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

安全地存储这两个令牌。访问令牌用于 API 请求。刷新令牌用于在当前访问令牌过期时获取新的访问令牌。

## 5\. 代表用户调用 API

使用访问令牌发起已认证的 API 请求：

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

令牌的作用域限制了您可访问的端点。资源级别的授权仍然适用 - 例如，一个具有 `project:read` 只能读取用户已获访问权限的项目。

## 6\. 刷新令牌

当访问令牌过期后，使用刷新令牌获取新令牌，无需再次引导用户通过授权流程：

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

## 选择权限范围

仅请求应用程序所需的权限范围。以下是常见组合：

| 用例 | 权限范围 |
|----------|--------|
| 读取用户资料 | `user:read` |
| 阅读项目和内容 | `user:read project:read voice:read` |
| 管理项目 | `user:read project:read project:write` |
| 完整组织访问权限 | `user:read organization:read organization:write members:read members:write project:read project:write` |

查看 [完整作用域参考](/docs/reference/apis/authentication) 适用于所有可用范围。

## Discovery endpoints

您的应用程序可通过获取服务器元数据自动发现 Glossia 的 OAuth 端点：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

此返回一个包含 `authorization_endpoint`先前重组文档验证失败：Markdown 文本字面量恢复必须返回长度匹配的 JSON 字符串数组 `token_endpoint`, `revocation_endpoint`, 及其他细节。使用发现功能可使您的集成对端点变更具有弹性。

## 错误处理

### 授权错误

如果用户拒绝同意或在授权期间出现问题，Glossia 会将您的回调 URL 重定向并附带一个 `error` 参数：

    https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE

常见错误代码：

| 错误 | 说明 |
|-------|---------|
| `access_denied` | 用户拒绝了授权请求 |
| `invalid_request` | 请求缺少必需的参数 |
| `invalid_scope` | 请求的一个或多个作用域无效 |

### 令牌错误

令牌端点返回 HTTP 400 及 JSON 错误内容：

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 速率限制

每个 IP 的 OAuth 端点均受速率限制。达到限制时将收到 HTTP 429。请查看 [速率限制参考](/docs/reference/apis/authentication) 详情。

## 安全检查清单

在生产环境部署前，请确认您的实现遵循以下实践：

- 生产中回调 URL 始终使用 HTTPS
- 验证 `state` 回调中的参数以防止 CSRF
- 静态加密存储令牌
- 切勿在前端 JavaScript 或浏览器 URL 中暴露令牌
- 仅使用所需的最小权限范围
- 利用刷新令牌优雅地处理令牌过期
- 当用户断开连接或删除账户时撤销令牌
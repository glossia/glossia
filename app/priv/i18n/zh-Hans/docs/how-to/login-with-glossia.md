%{
  title: "使用 Glossia 登录",
  summary: "让用户使用其 Glossia 账户通过 OAuth 2.1 登录您的应用程序。",
  category: "操作指南",
  section: "platform",
  order: 2
}
---

本指南将指导您为您的应用程序添加“使用 Glossia 登录”。结束时，您的用户将能够使用他们的 Glossia 帐户登录，并且您的应用程序将获得访问令牌，以便代表他们调用 Glossia API。

Glossia 使用 **OAuth 2.1 with PKCE**（证明密钥代码交换）。PKCE 是所有客户端（包括服务器端应用程序）所必需的。

## 1. 注册您的 OAuth 应用程序

您注册应用程序有两种选择：

### Option A: 通过仪表板（推荐）

1. 登录 Glossia 后进入您的帐户仪表板。
2. 从侧边栏打开 **API** 部分并点击 **OAuth apps**。
3. 点击 **New application**。
4. 填写应用程序的 **名称** 和 **回呼 URL**（也称为重定向 URI）。
5. 点击 **Create application**。

创建后，记下 **客户端 ID** 和 **客户端密钥**。该密钥仅显示一次，因此请安全地保存它。

### Option B: 动态客户端注册

向 `POST` 发送 `/oauth/register` 请求：

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

响应包含 `client_id` 和 `client_secret`。

## 2. 生成 PKCE 代码挑战

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

## 3. 将用户重定向至 Glossia

构建授权 URL 并重定向用户浏览器：

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

**参数:**

| 参数 | 必需 | 描述 |
|-----------|----------|-------------|
| `response_type` | 是 | 始终 `code` |
| `client_id` | 是 | 您的应用程序客户端 ID |
| `redirect_uri` | 是 | 必须与已注册的回呼 URL 匹配 |
| `code_challenge` | 是 | 该 PKCE 代码挑战（S256） |
| `code_challenge_method` | 是 | 始终 `S256` |
| `scope` | 否 | 空格分隔的 [作用域](/docs/reference/apis/authorization) 列表。如果省略，不会授予任何操作范围。 |
| `state` | 推荐 | 一个随机字符串以防止 CSRF 攻击。用户返回时验证它是否匹配。 |

用户将看到一个同意屏幕，显示您的应用程序名称和请求的作用域。他们批准后，Glossia 会将用户重定向回您的回呼 URL，并附带授权代码。

## 4. 交换代码以获取令牌

当用户被重定向回您的回呼 URL 时，URL 将包含一个 `code` 参数：

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

首先，验证 `state` 是否与您在第 3 步中发送的一致。然后交换代码以获取令牌：

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

安全地存储两个令牌。访问令牌用于 API 请求。刷新令牌用于在现有令牌过期时获取新的访问令牌。

## 5. 代表用户调用 API

使用访问令牌进行身份验证的 API 请求：

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

令牌的权限范围限制了您可以访问的端点。资源级别的授权仍然适用——例如，具有 `project:read` 的令牌只能读取用户有权访问的项目。

## 6. 刷新令牌

访问令牌过期时，使用刷新令牌获取新令牌，而无需再次让用户经过同意流程：

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. 撤销令牌

当用户断开您的应用程序连接或您不再需要访问权限时，撤销令牌：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 选择作用域

仅请求您的应用程序所需的作用域。以下是一些常见组合：

| 用例 | 作用域 |
|----------|--------|
| 读取用户个人资料 | `user:read` |
| 读取项目和内容 | `user:read project:read voice:read` |
| 管理项目 | `user:read project:read project:write` |
| 管理组织资源 | `user:read organization:read organization:write members:read members:write project:read project:write` |

查看所有可用作用域，请参阅 [scopes reference](/docs/reference/apis/authorization)。

## 发现端点

您的应用程序可以通过获取服务器元数据自动发现 Glossia 的 OAuth 端点：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

这将返回一个包含 `authorization_endpoint`、`token_endpoint`、`revocation_endpoint` 和其他详情的 JSON 文档。使用发现机制可以使您的集成对端点变更具有弹性。

## 错误处理

### 授权错误

如果用户拒绝同意或授权过程中出现问题，Glossia 将通过一个 `error` 参数将用户重定向到您的回呼 URL：

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

常见错误代码：

| 错误 | 含义 |
|-------|---------|
| `access_denied` | 用户拒绝了授权请求 |
| `invalid_request` | 请求缺少必需参数 |
| `invalid_scope` | 一个或多个请求的作用域无效 |

### 令牌错误

令牌端点返回 HTTP 400，包含 JSON 错误体：

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 速率限制

OAuth 端点按 IP 进行速率限制。如果您触达限制，将收到 HTTP 429。有关详细信息，请参阅 [rate limiting reference](/docs/reference/apis/authentication)。

## 安全检查清单

在上线生产前，核实您的实施是否符合以下做法：

- 生产环境中始终为回呼 URL 使用 HTTPS
- 在回呼中验证 `state` 参数以防止 CSRF
- 将令牌加密存储
- 切勿在客户端 JavaScript 或浏览器 URL 中暴露令牌
- 使用所需的最小作用域集合。
- 使用刷新令牌妥善处理令牌过期。
- 当用户断开您的应用程序连接或删除其账户时，撤销令牌。

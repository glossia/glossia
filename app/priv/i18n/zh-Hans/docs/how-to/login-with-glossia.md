%{
  title: "使用 Glossia 登录",
  summary: "使用 OAuth 2.1 让用户通过其 Glossia 账户登录您的应用。",
  category: "指南",
  section: "platform",
  order: 2
}
---

本指南将指导您为您的应用程序添加“使用 Glossia 登录”功能。完成后，您的用户将能够使用他们的 Glossia 账户登录，您的应用程序将拥有一个访问令牌，代表他们调用 Glossia API。

Glossia 使用 **OAuth 2.1 与 PKCE**（密钥交换证明代码）。PKCE 对所有客户端都是必需的，包括服务器端应用程序。

## 1. 注册您的 OAuth 应用程序

注册您的应用程序有两种选项：

### 选项 A：通过仪表板（推荐）

1. 登录 Glossia 并进入您的账户仪表板。
2. 从侧边栏打开 **API** 部分并点击 **OAuth 应用**。
3. 点击 **创建应用程序**。
4. 填写应用程序 **名称** 和 **回调 URL**（也称为重定向 URI）。
5. 点击 **创建应用程序**。

创建后，记下 **客户端 ID** 和 **客户端密钥**。密钥仅显示一次，因此请安全存储。

### 选项 B：动态客户端注册

向 `/oauth/register` 发送一个 `POST` 请求：

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

在重定向用户之前，生成一个 PKCE 代码验证器和挑战：

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

**参数：**

| 参数 | 必需 | 描述 |
|-----------|----------|-------------|
| `response_type` | 是 | 始终 `code` |
| `client_id` | 是 | 您的应用程序的客户端 ID |
| `redirect_uri` | 是 | 必须与已注册的回调 URL 匹配 |
| `code_challenge` | 是 | PKCE 代码挑战（S256） |
| `code_challenge_method` | 是 | 始终 `S256` |
| `scope` | 否 | 用空格分隔的 [范围](/docs/reference/apis/authorization) 列表。如果省略，则不会授予任何操作权限范围 |
| `state` | 推荐 | 一个用于防止 CSRF 攻击的随机字符串。当用户返回时，请验证其是否匹配 |

用户将看到一个同意屏幕，显示您的应用程序名称和请求的权限范围。他们同意后，Glossia 将重定向回您的回调 URL，并携带授权代码。

## 4. 用代码交换令牌

当用户被重定向回您的回调 URL 时，URL 中将包含一个 `code` 参数：

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

首先，验证 `state` 是否与您在第 3 步中发送的一致。然后用代码交换令牌：

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

安全存储这两个令牌。访问令牌用于 API 请求。刷新令牌用于在当前令牌过期时获取新的访问令牌。

## 5. 返回代表用户身份验证的 API 请求

使用访问令牌发起经过身份验证的 API 请求：

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

令牌的权限范围限制了您可以访问的端点。资源级授权仍然适用 -- 例如，拥有 `project:read` 权限的令牌只能读取用户有权访问的项目。

## 6. 刷新令牌

当访问令牌过期时，使用刷新令牌获取新令牌，而无需再次将用户引导至同意流程：

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. 撤销令牌

当用户断开应用程序连接或您不再需要访问权限时，撤销令牌：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 选择权限范围

仅提交您的应用程序需要的权限范围。以下是一些常见组合：

| 使用场景 | 范围 |
|----------|--------|
| 读取用户档案 | `user:read` |
| 读取项目和内容 | `user:read project:read voice:read` |
| 管理项目 | `user:read project:read project:write` |
| 管理组织资源 | `user:read organization:read organization:write members:read members:write project:read project:write` |

查看所有可用范围，请查阅 [范围参考](/docs/reference/apis/authorization)。

## 发现端点

您的应用程序可以通过获取服务器元数据自动发现 Glossia 的 OAuth 端点：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

这将返回一个 JSON 文档，包含 `authorization_endpoint`、`token_endpoint`、`revocation_endpoint` 和其他详细信息。使用发现功能可使您的集成对端点变更具有弹性。

## 错误处理

### 授权错误

如果用户拒绝同意或授权过程中出现问题，Glossia 将重定向回您的回调 URL，并附带 `error` 参数：

```
https://myapp.com/auth/callback?error=access_denied&state=RANDOM_STATE_VALUE
```

常见错误代码：

| 错误 | 含义 |
|-------|---------|
| `access_denied` | 用户拒绝了授权请求 |
| `invalid_request` | 请求缺少必需参数 |
| `invalid_scope` | 一个或多个请求的权限范围无效 |

### 令牌错误

令牌端点返回 HTTP 400，并带有 JSON 错误主体：

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 速率限制

OAuth 端点按 IP 进行速率限制。如果您达到限制，将收到 HTTP 429。有关详情，请参阅 [速率限制参考](/docs/reference/apis/authentication)。

## 安全检查清单

在生产环境中部署前，请验证您的实现是否符合以下做法：

- 在生产环境中始终使用 HTTPS 用于回调 URL
- 在回调中验证 `state` 参数以防止 CSRF
- 加密存储令牌
- 切勿在客户端 JavaScript 或浏览器 URL 中暴露令牌
- 使用所需的最小权限范围集合
- 使用刷新令牌优雅地处理令牌过期
- 当用户断开连接或删除其账户时撤销令牌

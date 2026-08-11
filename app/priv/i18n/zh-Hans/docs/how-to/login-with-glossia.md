%{
  title: "使用 Glossia 登录",
  summary: "使用 OAuth 2.1，让用户通过其 Glossia 账户登录您的应用。",
  category: "how-to",
  order: 2
}
---
本指南将引导您在应用中添加“使用 Glossia 登录”功能。完成后，您的用户将能够使用 Glossia 账户登录，您的应用也将获得访问令牌，以代表用户调用 Glossia 应用程序编程接口（API）。

Glossia 使用带有 PKCE（授权码交换证明）的 **OAuth 2.1**。所有客户端都必须使用 PKCE，包括服务器端应用。

## 1. 注册 OAuth 应用

您可以通过以下两种方式注册应用：

### 选项 A：通过控制面板注册（推荐）

1. 登录 Glossia 并进入账户控制面板。
2. 在侧边栏中打开 **API** 部分，然后点击 **OAuth 应用**。
3. 点击 **新建应用**。
4. 填写应用的**名称**和**回调 URL**（也称为重定向 URI）。
5. 点击**创建应用**。

创建后，请记录**客户端 ID**和**客户端密钥**。密钥仅显示一次，请妥善安全保存。

### 选项 B：动态客户端注册

向 `/oauth/register` 发送 `POST` 请求：

```bash
curl -X POST https://glossia.ai/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "My App",
    "redirect_uris": ["https://myapp.com/auth/callback"],
    "grant_types": ["authorization_code"]
  }'
```

响应中包含 `client_id` 和 `client_secret`。

## 2. 生成 PKCE 代码质询

在重定向用户之前，生成 PKCE 代码验证器和代码质询：

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

## 3. 将用户重定向到 Glossia

构建授权 URL，并重定向用户的浏览器：

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

| 参数 | 是否必填 | 说明 |
|-----------|----------|-------------|
| `response_type` | 是 | 始终为 `code` |
| `client_id` | 是 | 您的应用客户端 ID |
| `redirect_uri` | 是 | 必须与已注册的回调 URL 匹配 |
| `code_challenge` | 是 | PKCE 代码质询（S256） |
| `code_challenge_method` | 是 | 始终为 `S256` |
| `scope` | 否 | 以空格分隔的[权限范围](/docs/reference/apis/authentication)列表。省略时默认为最低访问权限 |
| `state` | 建议 | 用于防止跨站请求伪造（CSRF）攻击的随机字符串。用户返回时，请验证该字符串是否匹配 |

用户将看到一个授权同意页面，其中显示您的应用名称和所请求的权限范围。用户批准后，Glossia 会将其重定向回您的回调 URL，并附带授权码。

## 4. 使用授权码交换令牌

用户被重定向回您的回调 URL 时，该 URL 将包含一个 `code` 参数：

```
https://myapp.com/auth/callback?code=AUTHORIZATION_CODE&state=RANDOM_STATE_VALUE
```

首先，验证 `state` 是否与您在第 3 步中发送的值匹配。然后，使用授权码交换令牌：

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

响应如下：

```json
{
  "access_token": "eyJhbGciOiJSUzI1...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "dGhpcyBpcyBhIHJl..."
}
```

请妥善安全保存这两个令牌。访问令牌用于 API 请求。当前访问令牌过期后，可使用刷新令牌获取新的访问令牌。

## 5. 代表用户调用 API

使用访问令牌发出经过身份验证的 API 请求：

```bash
curl -H "Authorization: Bearer eyJhbGciOiJSUzI1..." \
  https://glossia.ai/api/projects
```

令牌的权限范围会限制您可以访问的端点。资源级授权仍然适用。例如，具有 `project:read` 权限范围的令牌只能读取该用户有权访问的项目。

## 6. 刷新令牌

访问令牌过期后，使用刷新令牌获取新的访问令牌，无需让用户再次完成授权同意流程：

```bash
curl -X POST https://glossia.ai/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=dGhpcyBpcyBhIHJl..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 7. 撤销令牌

当用户断开您的应用连接，或您不再需要访问权限时，请撤销令牌：

```bash
curl -X POST https://glossia.ai/oauth/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=eyJhbGciOiJSUzI1..." \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

## 选择权限范围

仅请求应用所需的权限范围。以下是一些常见组合：

| 用例 | 作用域 |
|----------|--------|
| 读取用户资料 | `user:read` |
| 读取项目和内容 | `user:read project:read voice:read` |
| 管理项目 | `user:read project:read project:write` |
| 完整的组织访问权限 | `user:read organization:read organization:write members:read members:write project:read project:write` |

有关所有可用作用域，请参阅[完整的作用域参考](/docs/reference/apis/authentication)。

## 发现端点

您的应用程序可以通过获取服务器元数据，自动发现 Glossia 的 OAuth 端点：

```bash
curl https://glossia.ai/.well-known/oauth-authorization-server
```

此请求返回一个 JSON 文档，其中包含 `authorization_endpoint`、`token_endpoint`、`revocation_endpoint` 和其他详细信息。使用发现机制可以使您的集成不受端点变更的影响。

## 错误处理

### 授权错误

如果用户拒绝授权，或授权过程中出现问题，Glossia 会重定向到您的回调 URL，并附带 `error` 参数：

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

令牌端点返回 HTTP 400，响应正文为 JSON 格式的错误信息：

```json
{
  "error": "invalid_grant",
  "error_description": "The authorization code has expired or was already used."
}
```

### 速率限制

OAuth 端点按 IP 实施速率限制。如果达到限制，您将收到 HTTP 429。有关详细信息，请参阅[速率限制参考](/docs/reference/apis/authentication)。

## 安全检查清单

在投入生产环境之前，请确认您的实现遵循以下实践：

- 在生产环境中，回调 URL 始终使用 HTTPS
- 在回调中验证 `state` 参数，以防止 CSRF
- 对静态存储的令牌进行加密
- 切勿在客户端 JavaScript 或浏览器 URL 中暴露令牌
- 仅使用所需的最小作用域集合
- 使用刷新令牌妥善处理令牌过期
- 当用户断开连接或删除账户时撤销令牌
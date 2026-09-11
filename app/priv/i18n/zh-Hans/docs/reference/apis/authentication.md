%{
  title: "认证与授权",
  summary: "Glossia 如何认证用户并授权 API 访问权限。",
  category: "参考",
  subcategory: "API",
  order: 1
}
---
## 身份验证方法

Glossia 支持两种身份验证方法，具体取决于使用场景。

### 浏览器会话

当你通过 Web 界面登录时，Glossia 使用基于会话的身份验证。你通过第三方提供商（GitHub 或 GitLab）使用 [Assent](https://github.com/pow-auth/assent) 库。成功登录后，会设置会话 cookie 并在后续请求中使用。

### Bearer 令牌（OAuth 2.1）

对于 API 访问（例如来自 CLI 或其他工具），Glossia 实现了采用授权码流程和 PKCE 的 OAuth 2.1。客户端获取 Bearer 令牌并将其包含在 `Authorization` 标题：

    Authorization: Bearer <access_token>

## OAuth 2.1 流程

### 1\. 动态客户端注册

客户端通过调用自行注册 `POST /oauth/register` 及其元数据。这遵循了 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

服务器返回 `client_id` 和 `client_secret`.

### 2\. 授权请求

客户端将用户重定向到 `/oauth/authorize` 并携带 PKCE 参数：

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**所有客户端均需 PKCE。** 仅 `S256` 挑战方法已支持。

### 3\. 令牌交换

用户批准后，客户端将授权码交换为令牌 `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>

响应包含访问令牌，并可选包含刷新令牌。

### 4\. 令牌刷新

访问令牌过期时，请使用刷新令牌：

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

## 作用域

作用域控制令牌可以执行的操作。它们遵循 `object:action` 模式。

| 范围 | 描述 |
|-------|-------------|
| `user:read` | 读取用户资料信息 |
| `user:write` | 更新用户资料 |
| `account:read` | 列出您能访问的组织账户 |
| `organization:read` | 查看组织详情（并列出您的组织） |
| `organization:write` | 创建或更新组织 |
| `organization:delete` | 删除组织 |
| `organization:admin` | 组织管理操作 |
| `members:read` | 查看组织成员和邀请 |
| `members:write` | 管理组织成员和邀请 |
| `project:read` | 查看项目 |
| `project:write` | 创建或更新项目 |
| `project:admin` | 管理项目操作 |
| `project:delete` | 删除项目 |
| `voice:read` | 读取语音配置 |
| `voice:write` | 创建或更新语音配置 |
| `voice:admin` | 语音管理操作 |
| `glossary:read` | 查看术语条目 |
| `glossary:write` | 创建或更新术语条目 |
| `glossary:admin` | 管理术语设置 |

## 授权模型

Glossia 强制 **两层** 针对 REST API 和 MCP 服务器：

1. **作用域检查**：访问令牌必须包含所需的 `object:action` 作用域。
2. **资源级策略**：当前用户必须针对特定资源获得授权，通过 `Glossia.Policy`。

作用域代表 *最大* 令牌的能力。策略系统强制实施 *实际* 特定资源的权限。

### 角色

| 角色 | 描述 |
|------|-------------|
| `self` | 访问自身资源的用户 |
| `organization_member` | 资源所属组织的成员 |
| `organization_admin` | 拥有该资源的组织的管理员 |
| `public_account` | 该账户为公开（只读） |

### 角色权限

| 范围 | 自身 | 组织成员 | 组织管理员 | 公共账户 |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | 是 | 是 | | |
| `user:write` | 是 | | | |
| `account:read` | | 是 | 是 | 是 |
| `organization:read` | | 是 | 是 | |
| `organization:write` | | | 是 | |
| `organization:delete` | | | 是 | |
| `organization:admin` | | | 是 | |
| `members:read` | | 是 | 是 | |
| `members:write` | | | 是 | |
| `project:read` | | 是 | 是 | 是 |
| `project:write` | | | 是 | |
| `project:admin` | | | 是 | |
| `project:delete` | | | 是 | |
| `voice:read` | | 是 | 是 | 是 |
| `voice:write` | | | 是 | |
| `voice:admin` | | | 是 | |
| `glossary:read` | | 是 | 是 | |
| `glossary:write` | | | 是 | |
| `glossary:admin` | | | 是 | |

## 发现端点

Glossia 在标准已知 URL 上发布元数据，以便客户端可以自动发现端点。

### OAuth 授权服务器元数据 (RFC 8414)

    GET /.well-known/oauth-authorization-server

返回颁发者、端点、支持的授权范围、授权类型和代码挑战方法。

### 受保护资源元数据 (RFC 9728)

    GET /.well-known/oauth-protected-resource

返回资源标识符、授权服务器、支持的授权范围以及凭证方法。

## 速率限制

OAuth 端点按 IP 地址限制速率：

| 端点 | 限制 |
|----------|-------|
| `POST /oauth/register` | 每分钟 5 次请求 |
| `POST /oauth/token` | 每分钟 30 次请求 |
| `POST /oauth/revoke` | 每分钟 30 次请求 |
| `POST /oauth/introspect` | 每分钟 30 次请求 |

当触发速率限制时，服务器将返回 HTTP 429（请求过多）。
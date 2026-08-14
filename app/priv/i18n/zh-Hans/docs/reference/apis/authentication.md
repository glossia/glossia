%{
  title: "身份认证与授权",
  summary: "Glossia 如何对用户进行身份认证并授权 API 访问。",
  category: "reference",
  subcategory: "apis",
  order: 1
}
---
## 身份验证方法

Glossia 根据使用场景支持两种身份验证方法。

### 浏览器会话

通过 Web 界面登录时，Glossia 使用基于会话的身份验证。您通过第三方提供商（GitHub 或 GitLab）并使用 [Assent](https://github.com/pow-auth/assent) 库进行身份验证。成功登录后，系统会设置会话 Cookie，并将其用于后续请求。

### 持有者令牌（OAuth 2.1）

对于 API 访问（例如来自 CLI 或其他工具的访问），Glossia 采用基于授权码流程和 PKCE 的 OAuth 2.1。客户端获取持有者令牌，并将其包含在 `Authorization` 标头中：

```
Authorization: Bearer <access_token>
```

## OAuth 2.1 流程

### 1. 动态客户端注册

客户端通过调用 `POST /oauth/register` 并提供自身元数据来完成注册。此过程遵循 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

服务器返回 `client_id` 和 `client_secret`。

### 2. 授权请求

客户端使用 PKCE 参数将用户重定向至 `/oauth/authorize`：

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**所有客户端都必须使用 PKCE。** 仅支持 `S256` 质询方法。

### 3. 令牌交换

用户批准后，客户端在 `POST /oauth/token` 使用授权码交换令牌：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&code_verifier=<verifier>
```

响应包含访问令牌，并可能包含刷新令牌。

### 4. 令牌刷新

访问令牌过期后，使用刷新令牌：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

## 作用域

作用域控制令牌可以执行的操作。作用域遵循 `object:action` 模式。

| 作用域 | 说明 |
|-------|-------------|
| `user:read` | 读取用户个人资料信息 |
| `user:write` | 更新用户个人资料 |
| `account:read` | 列出您可以访问的组织账户 |
| `organization:read` | 读取组织详细信息（并列出您的组织） |
| `organization:write` | 创建或更新组织 |
| `organization:delete` | 删除组织 |
| `organization:admin` | 执行组织管理操作 |
| `members:read` | 读取组织成员和邀请 |
| `members:write` | 管理组织成员和邀请 |
| `project:read` | 读取项目 |
| `project:write` | 创建或更新项目 |
| `project:admin` | 执行项目管理操作 |
| `project:delete` | 删除项目 |
| `voice:read` | 读取文风配置 |
| `voice:write` | 创建或更新文风配置 |
| `voice:admin` | 执行文风管理操作 |
| `glossary:read` | 读取术语条目 |
| `glossary:write` | 创建或更新术语条目 |
| `glossary:admin` | 管理术语设置 |

## 授权模型

Glossia 对 REST API 和 MCP 服务器实施**两层**授权：

1. **作用域检查**：访问令牌必须包含所需的 `object:action` 作用域。
2. **资源级策略**：当前用户必须通过 `Glossia.Policy` 获得访问特定资源的授权。

作用域表示令牌的*最大*能力。策略系统强制执行用户对特定资源的*实际*权限。

### 角色

| 角色 | 描述 |
|------|-------------|
| `self` | 访问自身资源的用户 |
| `organization_member` | 资源所属组织的成员 |
| `organization_admin` | 资源所属组织的管理员 |
| `public_account` | 账户为公开状态（只读） |

### 角色权限

| 权限范围 | self | organization_member | organization_admin | public_account |
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

Glossia 在标准的众所周知 URL 上发布元数据，以便客户端自动发现端点。

### OAuth 授权服务器元数据（RFC 8414）

```
GET /.well-known/oauth-authorization-server
```

返回颁发者、端点、支持的权限范围、授权类型和代码质询方法。

### 受保护资源元数据（RFC 9728）

```
GET /.well-known/oauth-protected-resource
```

返回资源标识符、授权服务器、支持的权限范围和持有者令牌传输方法。

## 速率限制

OAuth 端点按 IP 地址实施速率限制：

| 端点 | 限制 |
|----------|-------|
| `POST /oauth/register` | 每分钟 5 个请求 |
| `POST /oauth/token` | 每分钟 30 个请求 |
| `POST /oauth/revoke` | 每分钟 30 个请求 |
| `POST /oauth/introspect` | 每分钟 30 个请求 |

触发速率限制时，服务器返回 HTTP 429（请求过多）。
%{title: "认证", summary: "浏览器登录、访问令牌和认证端点。", category: "参考", subcategory: "API", order: 1}
---

本页面介绍了 [开放授权](https://oauth.net/2.1/)（OAuth）、[代码交换证明密钥](https://datatracker.ietf.org/doc/html/rfc7636)（PKCE）和 [应用程序编程接口](https://developer.mozilla.org/en-US/docs/Glossary/API)（API）。下方链接的协议规范以请求意见（RFCs）形式发布。

## 认证方法

Glossia 支持浏览器会话和 Bearer 令牌。可以通过以下授权流程颁发 Bearer 令牌，或作为 [账户令牌](/docs/reference/apis/account-tokens) 创建。

### 浏览器会话

当通过 Web 界面登录时，Glossia 使用基于会话的身份验证。您可以使用 [Assent](https://github.com/pow-auth/assent) 库通过 GitHub、GitLab、Google 或配置的机构身份提供商进行身份验证。成功登录后，会设置会话 Cookie 并用于后续请求。

组织可以在允许自动注册之前配置 Google Workspace 或 Okta，并验证其工作邮件域名。有关设置及账户链接要求，请参阅 [配置机构登录](/docs/how-to/organization-sign-in)。

### Bearer 令牌（OAuth 2.1）

客户端获取 Bearer 令牌并将其包含在 `Authorization` 标头中：

```
Authorization: Bearer <access_token>
```

## OAuth 2.1 流程

### 1. 动态客户端注册

客户端通过调用 `POST /oauth/register` 并附带其元数据进行注册。这遵循 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia 会返回 `client_id` 和 `client_secret`。本示例中的 `localhost` 重定向属于开发期间的应用程序。生产级应用程序应注册自己的安全回调地址。

### 2. 授权请求

客户端将用户重定向到 `/oauth/authorize`，并附带 PKCE 参数：

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**PKCE 对所有客户端都是必需的。** 仅支持 `S256` 挑战方法。

### 3. 令牌交换

用户批准后，客户端在 `POST /oauth/token` 处使用授权代码交换令牌：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

响应中包括访问令牌和可选的刷新令牌。

### 4. 令牌刷新

当访问令牌过期时，使用刷新令牌：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

请参阅 [授权](/docs/reference/apis/authorization) 了解权限范围、成员访问和资源级检查。

## 发现端点

Glossia 在标准已知的 URL 上发布元数据，以便客户端可以自动发现端点。

### OAuth 授权服务器元数据（RFC 8414）

```
GET /.well-known/oauth-authorization-server
```

返回颁发者、端点、支持的权限范围、授权类型和代码挑战方法。

### 受保护资源元数据（RFC 9728）

```
GET /.well-known/oauth-protected-resource
```

返回资源标识符、授权服务器、支持的权限范围以及 Bearer 方法。

## 速率限制

注册由客户端地址限制。令牌、撤销和自省请求受到客户端地址和客户端标识符的双重限制：

| 端点 | 限制 |
|----------|-------|
| `POST /oauth/register` | 每分钟 5 次请求 |
| `POST /oauth/token` | 每分钟 30 次请求 |
| `POST /oauth/revoke` | 每分钟 30 次请求 |
| `POST /oauth/introspect` | 每分钟 30 次请求 |

当受速率限制影响时，服务器返回 HTTP 429（请求过多）。

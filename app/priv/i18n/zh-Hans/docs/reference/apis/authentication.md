%{title: "身份认证", summary: "浏览器登录、访问令牌和身份认证端点。", category: "参考", subcategory: "接口", order: 1}
---
本页面描述 [开放授权](https://oauth.net/2.1/) (OAuth)、 [代码交换证明密钥](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE)、以及 [应用程序编程接口](https://developer.mozilla.org/en-US/docs/Glossary/API) (API)。下方链接的协议规范以请求评论 (RFC) 形式发布。

## 认证方法

Glossia 支持浏览器会话和访问令牌。访问令牌可通过下方的授权流程签发或创建为 [账户令牌](/docs/reference/apis/account-tokens)。

### 浏览器会话

当通过 Web 界面登录时，Glossia 使用基于会话的认证。您通过 GitHub、GitLab、Google 或已配置的组织机构身份提供商进行身份验证，使用 [Assent](https://github.com/pow-auth/assent) 库。成功登录后，会设置会话 Cookie 并用于后续请求。

组织可以配置 Google Workspace 或 Okta，并在允许自动注册前验证其工作邮箱域名。参见 [配置组织登录](/docs/how-to/organization-sign-in) 用于设置及账号关联要求。

### Bearer 令牌 (OAuth 2.1)

对于 API 访问（例如来自 CLI 或其他工具），Glossia 采用带有授权码流程和 PKCE 的 OAuth 2.1。客户端获取 Bearer 令牌并包含在 `Authorization` 请求头：

    Authorization: Bearer <access_token>

## OAuth 2.1 流程

### 1\. 动态客户端注册

客户端通过调用自行注册 `POST /oauth/register` 及其元数据。这遵循 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia 返回 `client_id` 和 `client_secret`。该 `localhost` 此示例中的重定向属于您开发期间的应用程序。生产应用程序应注册自己的安全回调地址。

### 2\. 授权请求

客户端将用户重定向到 `/oauth/authorize` 携带 PKCE 参数：

    GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>

**所有客户端均需使用 PKCE。** 仅 `S256` 支持挑战方法。

### 3\. 令牌交换

用户批准后，客户端使用授权码换取令牌于 `POST /oauth/token`:

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>

响应中包含访问令牌，并可选地包含刷新令牌。

### 4\. 令牌刷新

访问令牌过期时，请使用刷新令牌：

    POST /oauth/token
    Content-Type: application/x-www-form-urlencoded
    
    grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>

请参阅 [授权](/docs/reference/apis/authorization) 关于权限范围、成员访问和资源级检查。

## 发现端点

Glossia 在标准已知 URL 上发布元数据，以便客户端自动发现端点。

### OAuth 授权服务器元数据 (RFC 8414)

    GET /.well-known/oauth-authorization-server

返回颁发方、端点、支持的作用域、授权类型和代码挑战方法。

### 受保护资源元数据 (RFC 9728)

    GET /.well-known/oauth-protected-resource

返回资源标识符、授权服务器、支持的作用域和承载方法。

## 速率限制

注册受客户端地址限制。令牌、撤销和内省请求受客户端地址和客户端标识符限制。

| 接口 | 限制 |
|----------|-------|
| `POST /oauth/register` | 每分钟 5 次请求 |
| `POST /oauth/token` | 每分钟 30 次请求 |
| `POST /oauth/revoke` | 每分钟 30 次请求 |
| `POST /oauth/introspect` | 每分钟 30 次请求 |

当触发速率限制时，服务器会返回 HTTP 429（请求过多）。
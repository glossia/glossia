%{title: "认证", summary: "浏览器登录、访问令牌和认证端点。", category: "参考", subcategory: "API", order: 1}
---

本页面介绍 [开放授权](https://oauth.net/2.1/) (OAuth)、[证明密钥代码交换](https://datatracker.ietf.org/doc/html/rfc7636) (PKCE) 和 [应用程序接口](https://developer.mozilla.org/en-US/docs/Glossary/API) (API)。下方链接的协议规范以请求规范（RFCs）形式发布。

## ## 认证方法

Glossia 支持浏览器会话和承载令牌。承载令牌可以通过以下授权流程发放，也可以创建为 [账户令牌](/docs/reference/apis/account-tokens)。

### ### 浏览器会话

当通过 Web 界面登录时，Glossia 使用基于会话的身份验证。您通过 GitHub、GitLab、Google 或配置的组织机构身份提供商使用 [Assent](https://github.com/pow-auth/assent) 库进行身份验证。登录成功后，会设置会话 cookie 并在后续请求中使用。

组织可以配置 Google Workspace 或 Okta，并在允许自动注册之前验证其工作电子邮件域。请查看 [配置组织登录](/docs/how-to/organization-sign-in) 以了解设置和账户关联要求。

### ### Bearer 令牌 (OAuth 2.1)

对于 API 访问（例如来自 CLI 或其他工具），Glossia 实现了带有授权码流和 PKCE 的 OAuth 2.1。客户端获取 Bearer 令牌并将其包含在 `Authorization` 请求头：

```
Authorization: Bearer <access_token>
```

## ### OAuth 2.1 流程

### ### 1. 动态客户端注册

客户端使用元数据调用 `POST /oauth/register` 进行注册。这遵循 [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)。

```json
{
  "client_name": "My Tool",
  "redirect_uris": ["http://localhost:8080/callback"],
  "grant_types": ["authorization_code"]
}
```

Glossia 返回 `client_id` 和 `client_secret`。此示例中的 `localhost` 重定向属于您的开发应用程序。生产应用程序应注册自己的安全回调地址。

### ### 2. 授权请求

客户端将用户重定向到 `/oauth/authorize` 并带有 PKCE 参数：

```
GET /oauth/authorize?response_type=code&client_id=<id>&redirect_uri=<uri>&code_challenge=<challenge>&code_challenge_method=S256&state=<state>
```

**所有客户端都必须支持 PKCE。** 仅支持 `S256` 挑战方法。

### ### 3. 令牌交换

用户批准后，客户端在 `POST /oauth/token` 处将授权代码交换为令牌：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=authorization_code&code=<code>&redirect_uri=<uri>&client_id=<id>&client_secret=<secret>&code_verifier=<verifier>
```

响应包括访问令牌，可选刷新令牌。

### ### 4. 令牌刷新

访问令牌过期时，使用刷新令牌：

```
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=<token>&client_id=<id>&client_secret=<secret>
```

有关权限范围、成员访问和资源级别检查，请查看 [授权](/docs/reference/apis/authorization)。

## ### 发现端点

Glossia 在标准的已知 URL 上发布元数据，以便客户端可以自动发现端点。

### ### OAuth 授权服务器元数据 (RFC 8414)

```
GET /.well-known/oauth-authorization-server
```

返回颁发者、端点、支持的作用域、授权类型和验证码挑战方法。

### ### 受保护资源元数据 (RFC 9728)

```
GET /.well-known/oauth-protected-resource
```

返回资源标识符、授权服务器、支持的作用域和承载方法。

## ### 速率限制

注册受客户端地址限制。令牌、撤销和反查请求受客户端地址和客户端标识符限制：

| 端点 | 限制 |
|----------|-------|
| `POST /oauth/register` | 每分钟 5 次请求 |
| `POST /oauth/token` | 每分钟 30 次请求 |
| `POST /oauth/revoke` | 每分钟 30 次请求 |
| `POST /oauth/introspect` | 每分钟 30 次请求 |

当触发速率限制时，服务器返回 HTTP 429 (请求过多)。

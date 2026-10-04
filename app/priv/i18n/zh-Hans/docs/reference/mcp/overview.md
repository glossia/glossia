%{
  title: "概述",
  summary: "通过模型上下文协议将编程代理连接到您的 Glossia 项目。",
  category: "参考",
  subcategory: "mcp",
  order: 1
}
---
Glossia 提供 [模型上下文协议](https://modelcontextprotocol.io) (MCP) 服务器允许代码代理与您的本地化项目交互。该服务器实现了 OAuth 2.1、PKCE 和动态客户端注册 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))，因此任何 MCP 兼容的客户端均可在无手动凭据设置的情况下进行身份验证。

## MCP 服务器提供的内容

连接后，代码代理可以列出账户和项目、创建项目、管理组织成员及邀请、读取或更新语音和术语表设置、以及管理账户模型和令牌，受限于其权限。

当前该服务器不提供启动翻译或修订的工具，也不支持检查单个文件翻译状态。请参见 [工具参考](/docs/reference/mcp) 针对可用工具。

## 服务器 URL

连接至 Glossia 的托管服务，位于 `https://glossia.ai/mcp`. Glossia 运行并维护此端点；您只需在您的编码代理中配置连接。

## 身份验证流程

MCP 服务器使用标准的带 PKCE 的 OAuth 2.1 授权码流程。您无需手动创建 OAuth 客户端。流程如下：

1. 代理通过 `https://glossia.ai/.well-known/oauth-authorization-server`
2. 它通过动态注册端点将自己注册为 OAuth 客户端
3. 它将打开您的浏览器进行登录和授权
4. 批准后，代理将接收访问令牌并将其附加到所有 MCP 请求

## 将 Glossia 添加到编程代理

### OpenAI Codex

按照 [Codex 连接指南](https://developers.openai.com/codex/mcp)，将服务器添加到您的 Codex 配置文件，在 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

然后运行 OAuth 登录：

```bash
codex mcp login glossia
```

您的浏览器将打开进行身份验证。批准后，Codex 将在本地存储令牌并用于未来的会话。

验证连接：

```bash
codex mcp list
```

### Claude Code

使用文档中记录的命令添加托管服务器至 [Claude Code 连接指南](https://code.claude.com/docs/en/mcp):

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

运行 `/mcp` 在 Claude Code 中运行并遵循浏览器认证流程。

### 其他 MCP 客户端

客户端必须支持 [模型上下文协议授权流程](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 由 Glossia 实现。连接需要：

- **传输**: 流式 HTTP
- **发现**: 客户端必须支持 OAuth 2.0 受保护资源元数据 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **注册**: 动态客户端注册 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **认证流程**: 使用 PKCE (S256) 的授权码

将客户端指向 `https://glossia.ai/mcp` 并让它自动处理发现与注册。

## 发现端点

服务器发布两份元数据文档，供 MCP 客户端引导 OAuth 流程：

| 端点 | 描述 |
|---|---|
| `/.well-known/oauth-authorization-server` | 授权服务器元数据 (端点，支持的授权类型，PKCE 方法) |
| `/.well-known/oauth-protected-resource` | 受保护资源元数据 (作用域，授权服务器) |

## 速率限制

OAuth 端点实施速率限制以防止滥用：

| 端点 | 限制 |
|---|---|
| `POST /oauth/register` | 每分钟 5 次请求 |
| `POST /oauth/token` | 每分钟 30 次请求 |
| `POST /oauth/introspect` | 每分钟 30 次请求 |
| `POST /oauth/revoke` | 每分钟 30 次请求 |

当速率限制超出时，服务器返回 HTTP 429 及一个 `Retry-After` 响应头。

## 故障排查

### 注册失败，错误为 "invalid\_client\_metadata"

动态注册端点仅接受特定 `token_endpoint_auth_method` 值。公共客户端（大多数编码代理）应发送 `"none"`, Glossia 会自动通过回退到默认认证方法并强制执行 PKCE。

### "无效的 OAuth 回调"审批之后

确认您的编码代理可以访问 `https://glossia.ai`。回调发生在编码代理在您计算机上临时打开的本地端口上。Glossia 仍托管；此本地监听器属于您的代理。防火墙或虚拟专用网络有时会阻止回调。

### 令牌交换失败

检查 `code_challenge_methods_supported` 该字段必须存在于授权服务器元数据中。服务器必须支持 PKCE 的 S256 编码以正常运行。Glossia 默认包含此功能。

### 代理无法连接到服务器

请检查配置的端点 `https://glossia.ai/mcp` 并确保您的网络允许编程代理访问该端点。如果托管服务仍不可用，请联系 Glossia 支持。
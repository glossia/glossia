%{
  title: "概述",
  summary: "通过模型上下文协议将编码代理连接到您的 Glossia 项目。",
  category: "参考",
  subcategory: "mcp",
  order: 1
}
---

Glossia 提供一个 [模型上下文协议](https://modelcontextprotocol.io) (MCP) 服务器，让编程代理与您的本地化项目交互。该服务器实现了带有 PKCE 和动态客户端注册 ( [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) ) 的 OAuth 2.1，因此任何兼容 MCP 的客户端都可以在无需手动设置凭据的情况下进行身份验证。

## MCP 服务器提供的功能

连接后，编程代理可以列出账户和项目，创建项目，管理组织成员和邀请，读取或更新语音和词汇表设置，并在其权限范围内管理账户模型和令牌。

服务器当前未提供启动翻译或修订的工具，或检查文件级别的翻译状态。请查看 [工具参考](/docs/reference/mcp) 以了解可用工具。

## 服务器 URL

连接到 Glossia 的托管服务 `https://glossia.ai/mcp`。Glossia 运行并维护此端点；您只需在您的编码代理中配置连接。

## 身份验证流程

MCP 服务器使用带有 PKCE 的标准 OAuth 2.1 授权码流程。您不需要手动创建 OAuth 客户端。流程如下：

1. 代理通过 `https://glossia.ai/.well-known/oauth-authorization-server` 发现 Glossia。
2. 通过动态注册端点将自己注册为 OAuth 客户端
3. 为您的登录和同意打开浏览器
4. 在您批准后，代理接收访问令牌并将其附加到所有 MCP 请求

## 将 Glossia 添加到编程代理

### OpenAI Codex

遵循 [Codex 连接指南](https://developers.openai.com/codex/mcp)，将服务器添加到您的 Codex 配置文件 `~/.codex/config.toml`：

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

然后运行 OAuth 登录：

```bash
codex mcp login glossia
```

您的浏览器将打开进行身份验证。批准后，Codex 将令牌本地存储并在后续会话中使用。

验证连接：

```bash
codex mcp list
```

### Claude Code

使用 [Claude Code 连接指南](https://code.claude.com/docs/en/mcp) 中记录的命令添加托管服务器：

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

在 Claude Code 中运行 `/mcp`，并遵循浏览器身份验证流程。

### 其他 MCP 客户端

客户端必须支持由 Glossia 实现的 [模型上下文协议授权流程](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)。连接需要：

- **传输**：流式 HTTP
- **发现**：客户端必须支持 OAuth 2.0 保护资源元数据 ( [RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728) )
- **注册**：动态客户端注册 ( [RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591) )
- **授权流程**：带 PKCE (S256) 的授权码

将客户端指向 `https://glossia.ai/mcp`，并让其自动处理发现和注册。

## 发现端点

服务器发布两个元数据文档，MCP 客户端使用这些文档启动 OAuth 流程：

| 端点 | 描述 |
|---|---|
| `/.well-known/oauth-authorization-server` | 授权服务器元数据（端点、支持的授权类型、PKCE 方法） |
| `/.well-known/oauth-protected-resource` | 保护资源元数据（范围、授权服务器） |

## 速率限制

OAuth 端点实施速率限制以防止滥用：

| 端点 | 限制 |
|---|---|
| `POST /oauth/register` | 每分钟 5 次请求 |
| `POST /oauth/token` | 每分钟 30 次请求 |
| `POST /oauth/introspect` | 每分钟 30 次请求 |
| `POST /oauth/revoke` | 每分钟 30 次请求 |

当超过速率限制时，服务器返回 HTTP 429 及 `Retry-After` 标头。

## 故障排查

### 注册失败并显示 "invalid_client_metadata"

动态注册端点仅接受特定的 `token_endpoint_auth_method` 值。公共客户端（大多数编码代理）应发送 `"none"`，Glossia 会自动处理，通过回退到带有 PKCE 强制执行的默认身份验证方法。

### "无效的 OAuth 回传"批准后

确认您的编码代理可以访问 `https://glossia.ai`。回传发生在您的计算机上被代理临时打开的本地端口上。Glossia 仍托管；此本地监听器属于您的代理。防火墙或虚拟专用网络有时会阻止回传。

### 令牌交换失败

请检查授权服务器元数据中是否存在 `code_challenge_methods_supported` 字段。服务器必须声明支持 PKCE 的 S256 以正常工作。Glossia 默认包含此项。

### 代理无法访问服务器

请检查配置的端点是否为 `https://glossia.ai/mcp`，且您的网络允许编码代理访问该端点。如果托管服务仍然不可用，请联系 Glossia 支持。

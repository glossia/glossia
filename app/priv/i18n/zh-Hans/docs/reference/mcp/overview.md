%{
  title: "概述",
  summary: "通过模型上下文协议将代码智能体连接到您的 Glossia 项目。",
  category: "参考",
  subcategory: "mcp",
  order: 1
}
---
Glossia 提供一个 [模型上下文协议](https://modelcontextprotocol.io) (MCP) 服务器，允许编程智能体与您的本地化项目交互。该服务器实现了采用 PKCE 的 OAuth 2.1 和动态客户端注册 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))，因此任何兼容 MCP 的客户端均可无需手动配置凭据进行身份验证。

## MCP 服务器提供的功能

连接后，编程智能体可以：

- 查询各个项目的翻译状态
- 触发翻译和修订
- 检查配置和内容条目
- 访问项目上下文以获取更智能的代码建议

## 服务器 URL

| 环境 | URL |
|---|---|
| 生产 | `https://glossia.ai/mcp` |
| 本地开发 | `http://localhost:4050/mcp` |

## 认证流程

MCP 服务器使用标准的带有 PKCE 的 OAuth 2.1 授权代码流程。您无需手动创建 OAuth 客户端。流程如下：

1. 代理发现您的服务器通过 `/.well-known/oauth-authorization-server`
2. 它通过动态注册端点将自己注册为 OAuth 客户端
3. 它打开您的浏览器进行登录和授权
4. 您批准后，代理将收到访问令牌并将其附加到所有 MCP 请求

## 将 Glossia 添加到代码代理

### OpenAI Codex

将服务器添加到您的 Codex 配置文件 `~/.codex/config.toml`：

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

然后运行 OAuth 登录：

```bash
codex mcp login glossia
```

您的浏览器将打开以进行身份验证。批准后，Codex 会在本地存储令牌，并在未来的会话中使用。

验证连接：

```bash
codex mcp list
```

对于本地开发，替换 URL：

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

将服务器添加到您的Claude Code MCP设置（`.claude/settings.json` 或全局配置文件）:

```json
{
  "mcpServers": {
    "glossia": {
      "url": "https://glossia.ai/mcp",
      "transport": "streamable-http"
    }
  }
}
```

Claude Code将在首次连接时自动处理OAuth流程。

### 其他MCP客户端

任何支持该 [MCP授权规范](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 将可以工作。关键要求包括：

- **传输**: 可流式 HTTP
- **发现**: 客户端必须支持 OAuth 2.0 受保护资源元数据 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **注册**: 动态客户端注册 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 或客户端 ID 元数据文档
- **认证流程**：使用 PKCE (S256) 的授权码

将客户端指向您的 Glossia MCP 服务器 URL，并让其自动处理发现和注册。

## 发现端点

服务器发布两个元数据文档，供 MCP 客户端使用以启动 OAuth 流程：

| 端点 | 描述 |
|---|---|
| `/.well-known/oauth-authorization-server` | 授权服务器元数据（端点、支持的授权类型、PKCE 方法） |
| `/.well-known/oauth-protected-resource` | 受保护资源元数据（作用域、授权服务器） |

## 速率限制

OAuth 端点实施速率限制以防止滥用：

| 端点 | 限制 |
|---|---|
| `POST /oauth/register` | 5 次请求/分钟 |
| `POST /oauth/token` | 30 次请求/分钟 |
| `POST /oauth/introspect` | 30 次请求/分钟 |
| `POST /oauth/revoke` | 每分钟 30 次请求 |

当速率限制超出时，服务器返回 HTTP 429 带有一个 `Retry-After` 标头。

## 故障排除

### 注册失败，原因为 "invalid\_client\_metadata"

动态注册端点仅接受特定 `token_endpoint_auth_method` 值。公有客户端（大多数编码代理）应发送 `"none"`, Glossia 会自动回退到默认身份验证方法并强制执行 PKCE 进行处理。

### "无效的 OAuth 回调" 批准后

确保您的 Glossia 服务器正在运行，并且可以在您配置的 URL 上访问。回调发生在代码代理临时打开的本地端口上。防火墙或 VPN 有时会阻断此连接。

### 令牌交换失败

检查授权服务器元数据中是否存在 `code_challenge_methods_supported` 字段。服务器必须支持 S256 才能让 PKCE 正常工作。Glossia 默认包含此项配置。

### 代理无法连接服务器

对于本地开发，请确保 Phoenix 服务器正在运行（`mix phx.server`）并监听预期的端口（默认：4050）。代理进程必须能够访问 MCP 端点。
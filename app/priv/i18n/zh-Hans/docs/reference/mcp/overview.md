%{
  title: "概述",
  summary: "通过模型上下文协议将编码智能体连接到您的 Glossia 项目。",
  category: "reference",
  subcategory: "mcp",
  order: 1
}
---
Glossia 提供了一个[模型上下文协议](https://modelcontextprotocol.io)（MCP）服务器，使编码代理能够与您的本地化项目交互。该服务器实现了采用 PKCE 的 OAuth 2.1 和动态客户端注册（[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)），因此任何兼容 MCP 的客户端都可以进行身份验证，无需手动设置凭据。

## MCP 服务器提供的功能

连接后，编码代理可以：

- 查询各项目的翻译状态
- 触发翻译和修订
- 检查配置和内容条目
- 访问项目上下文，以提供更智能的代码建议

## 服务器 URL

| 环境 | URL |
|---|---|
| 生产环境 | `https://glossia.ai/mcp` |
| 本地开发环境 | `http://localhost:4050/mcp` |

## 身份验证流程

MCP 服务器使用采用 PKCE 的标准 OAuth 2.1 授权码流程。您无需手动创建 OAuth 客户端。流程如下：

1. 代理通过 `/.well-known/oauth-authorization-server` 发现您的服务器
2. 代理通过动态注册端点将自身注册为 OAuth 客户端
3. 代理打开浏览器，供您登录并授权
4. 获得您的批准后，代理会收到访问令牌，并将其附加到所有 MCP 请求中

## 将 Glossia 添加到编码代理

### OpenAI Codex

将服务器添加到位于 `~/.codex/config.toml` 的 Codex 配置文件：

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

然后运行 OAuth 登录：

```bash
codex mcp login glossia
```

浏览器将打开以进行身份验证。获得批准后，Codex 会在本地存储令牌，并在后续会话中使用该令牌。

验证连接：

```bash
codex mcp list
```

对于本地开发，请替换 URL：

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

将服务器添加到 Claude Code MCP 设置（`.claude/settings.json` 或全局设置文件）：

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

Claude Code 首次连接时会自动处理 OAuth 流程。

### 其他 MCP 客户端

任何支持 [MCP 授权规范](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)的客户端都可以使用。主要要求如下：

- **传输方式**：可流式传输的 HTTP
- **发现机制**：客户端必须支持 OAuth 2.0 受保护资源元数据（[RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728)）
- **注册机制**：动态客户端注册（[RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)）或客户端 ID 元数据文档
- **身份验证流程**：采用 PKCE（S256）的授权码流程

将客户端指向您的 Glossia MCP 服务器 URL，并让其自动处理发现和注册。

## 发现端点

服务器发布两个元数据文档，MCP 客户端使用它们来启动 OAuth 流程：

| 端点 | 说明 |
|---|---|
| `/.well-known/oauth-authorization-server` | 授权服务器元数据（端点、支持的授权类型、PKCE 方法） |
| `/.well-known/oauth-protected-resource` | 受保护资源元数据（作用域、授权服务器） |

## 速率限制

OAuth 端点实施速率限制以防止滥用：

| 端点 | 限制 |
|---|---|
| `POST /oauth/register` | 每分钟 5 个请求 |
| `POST /oauth/token` | 每分钟 30 个请求 |
| `POST /oauth/introspect` | 每分钟 30 个请求 |
| `POST /oauth/revoke` | 每分钟 30 个请求 |

超过速率限制时，服务器会返回 HTTP 429，并包含 `Retry-After` 标头。

## 故障排除

### 注册失败并显示“invalid_client_metadata”

动态注册端点仅接受特定的 `token_endpoint_auth_method` 值。公共客户端（大多数编码智能体）应发送 `"none"`，Glossia 会自动回退到默认身份验证方法，并强制使用 PKCE。

### 授权后出现“OAuth 回调无效”

请确保 Glossia 服务器正在运行，并且可通过您配置的 URL 访问。回调发生在编码智能体临时打开的本地端口上。防火墙或虚拟专用网络有时可能会阻止此连接。

### 令牌交换失败

请检查授权服务器元数据中是否存在 `code_challenge_methods_supported` 字段。服务器必须声明支持 S256，PKCE 才能正常工作。Glossia 默认包含此配置。

### 智能体无法连接服务器

在本地开发环境中，请确保 Phoenix 服务器正在运行（`mix phx.server`），并监听预期端口（默认：4050）。智能体进程必须能够访问 MCP 端点。
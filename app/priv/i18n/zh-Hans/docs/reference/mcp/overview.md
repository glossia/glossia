%{
  title: "概览",
  summary: "通过 Model Context Protocol 将代码代理连接到您的 Glossia 项目。",
  category: "参考",
  subcategory: "mcp",
  order: 1
}
---
Glossia 提供一个 [模型上下文协议](https://modelcontextprotocol.io) (MCP) 服务器，使编码代理能够与您的本地化项目进行交互。该服务器实现了 OAuth 2.1 与 PKCE 及动态客户端注册 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))，因此任何兼容 MCP 的客户端均可进行身份验证，无需手动设置凭据。

## MCP 服务器提供的功能

连接后，编码代理可以：

- 查询您所有项目的翻译状态
- 触发翻译和修订
- 检查配置和内容条目
- 访问项目上下文以获取更智能的代码建议

## 服务器 URL

| 环境 | URL |
|---|---|
| 生产 | `https://glossia.ai/mcp` |
| 本地开发 | `http://localhost:4050/mcp` |

## 认证流程

MCP 服务器使用带有 PKCE 的标准 OAuth 2.1 授权码流程。您无需手动创建 OAuth 客户端。流程如下：

1. 代理通过此方式发现您的服务器 `/.well-known/oauth-authorization-server`
2. 代理作为 OAuth 客户端通过动态注册端点注册自身
3. 代理打开您的浏览器以进行登录和授权同意
4. 在您批准后，代理会接收访问令牌并将其附加到所有 MCP 请求中

## 将 Glossia 添加到编程代理

### OpenAI Codex

将服务器添加到您的 Codex 配置文件位置 `~/.codex/config.toml`:

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

然后运行 OAuth 登录：

```bash
codex mcp login glossia
```

您的浏览器将打开以进行身份验证。批准后，Codex 会在本地存储令牌并用于后续会话。

验证连接：

```bash
codex mcp list
```

本地开发时，替换 URL：

```toml
[mcp_servers.glossia-local]
url = "http://localhost:4050/mcp"
```

### Claude Code

将服务器添加到您的 Claude Code MCP 设置（`.claude/settings.json` 或全局设置文件）：

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

首次连接时，Claude Code 将自动处理 OAuth 流程。

### 其他 MCP 客户端

任何支持以下 [MCP 授权规范](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization) 均可使用。关键要求如下：

- **传输**：流式 HTTP
- **发现**：客户端必须支持 OAuth 2.0 受保护资源元数据 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **注册**：动态客户端注册 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 或 客户端 ID 元数据文档
- **认证流程**: 使用 PKCE (S256) 的授权码

将客户端指向您的 Glossia MCP 服务器 URL，并让它自动处理发现和注册。

## 发现端点

服务器发布两个元数据文档，MCP 客户端使用它们来启动 OAuth 流程：

| 端点 | 描述 |
|---|---|
| `/.well-known/oauth-authorization-server` | 授权服务器元数据（端点、支持的授权类型、PKCE 方法） |
| `/.well-known/oauth-protected-resource` | 受保护资源元数据（范围、授权服务器） |

## 速率限制

OAuth 端点实施速率限制以防止滥用：

| 端点 | 限制 |
|---|---|
| `POST /oauth/register` | 5 每分钟请求 |
| `POST /oauth/token` | 30 每分钟请求 |
| `POST /oauth/introspect` | 30 每分钟请求 |
| `POST /oauth/revoke` | 每分钟 30 次请求 |

当速率限制被超过时，服务器返回 HTTP 429 及一个 `Retry-After` 标头。

## 故障排除

### 注册失败，错误为 "invalid\_client\_metadata"

动态注册端点仅接受特定 `token_endpoint_auth_method` 值。公开客户端（大多数编码代理）应发送 `"none"`, Glossia 会自动处理，通过回退到默认身份验证方法并强制执行 PKCE。

### "OAuth 回调无效" 审批后

确保您的 Glossia 服务器正在运行，且可在您配置的 URL 处访问。回调发生在代码代理临时打开的本地端口上。防火墙或 VPN 有时会阻止此通信。

### 令牌交换失败

请检查 `code_challenge_methods_supported` 字段是否存在于授权服务器元数据中。服务器必须支持 S256 协议以确保 PKCE 正常工作。Glossia 默认已包含此支持。

### 代理无法连接服务器

进行本地开发时，请确保 Phoenix 服务器正在运行（`mix phx.server`），并监听预期的端口（默认：4050）。MCP 端点必须可被代理进程访问。
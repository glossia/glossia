%{
  title: "概述",
  summary: "通过模型上下文协议将代码智能体连接到您的 Glossia 项目。",
  category: "参考",
  subcategory: "mcp",
  order: 1
}
---

Glossia 提供一个 [Model Context Protocol](https://modelcontextprotocol.io) (MCP) 服务器，使编码代理能够与您的本地化项目交互。该服务器实现了带有 PKCE 和动态客户端注册 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591)) 的 OAuth 2.1，因此任何兼容 MCP 的客户端都可以在无需手动配置凭据的情况下进行身份验证。

## MCP 服务器提供的内容

连接后，编码代理可以列出账户和项目、创建项目、管理组织成员和邀请、读取或更新语音和术语表设置，以及管理账户模型和令牌，具体取决于其权限。

该服务器目前不提供启动翻译或修订的工具，也无法检查每个文件的翻译状态。请查看 [工具参考](/docs/reference/mcp) 以获取可用工具。

## 服务器 URL

连接到 Glossia 的托管服务在 `https://glossia.ai/mcp`。Glossia 运行并维护此端点；您只需在编码代理中配置连接。

## 身份验证流程

MCP 服务器使用带有 PKCE 的标准 OAuth 2.1 授权码流程。您无需手动创建 OAuth 客户端。流程如下：

1. 代理通过 `https://glossia.ai/.well-known/oauth-authorization-server` 发现 Glossia。
2. 它通过动态注册端点将自己注册为 OAuth 客户端
3. 它为您打开浏览器进行登录和同意
4. 您同意后，代理会收到访问令牌并将其附加到所有 MCP 请求

## 将 Glossia 添加到编码代理

### OpenAI Codex

按照 [Codex 连接指南](https://developers.openai.com/codex/mcp)，将服务器添加到您的 Codex 配置文件 `~/.codex/config.toml`：

```toml
[mcp_servers.glossia]
url = "https://glossia.ai/mcp"
```

然后运行 OAuth 登录：

```bash
codex mcp login glossia
```

您的浏览器将打开进行身份验证。批准完成后，Codex 将令牌本地存储并用于将来会话。

验证连接：

```bash
codex mcp list
```

### Claude Code

按照 [Claude Code 的连接指南](https://code.claude.com/docs/en/mcp) 中记录的命令添加托管服务器：

```bash
claude mcp add --transport http glossia https://glossia.ai/mcp
```

在 Claude Code 中运行 `/mcp` 并遵循浏览器身份验证流程。

### 其他 MCP 客户端

客户端必须支持 Glossia 实现的 [Model Context Protocol 授权流程](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)。连接需要：

- **Transport**：流式 HTTP
- **Discovery**：客户端必须支持 OAuth 2.0 保护资源元数据 ([RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728))
- **Registration**：动态客户端注册 ([RFC 7591](https://datatracker.ietf.org/doc/html/rfc7591))
- **Auth flow**：带有 PKCE (S256) 的授权码

将客户端指向 `https://glossia.ai/mcp` 并让它自动处理发现和注册。

## 发现端点

服务器发布两个元数据文档，MCP 客户端使用这些文档来引导 OAuth 流程：

| 端点 | 描述 |
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

当超过速率限制时，服务器会返回 HTTP 429，包含 `Retry-After` 标头。

## 故障排除

### 注册失败并显示"invalid_client_metadata"

动态注册端点仅接受特定的 `token_endpoint_auth_method` 值。公共客户端（大多数编码代理）应发送 `"none"`，Glossia 会自动处理，通过回退到默认身份验证方法（强制 PKCE）来处理。

### 批准后出现"无效的 OAuth 回调"

确认您的编码代理能够访问 `https://glossia.ai`。回调发生在本地端口，加密代理会在您的计算机上暂时打开该端口。Glossia 保持托管；此本地监听器属于您的代理。防火墙或虚拟私有网络有时可能会阻止回调。

### 令牌交换失败

检查授权服务器元数据中是否包含 `code_challenge_methods_supported` 字段。服务器必须 advertised S256 支持才能使 PKCE 正常工作。Glossia 默认包含此功能。

### 代理无法连接到服务器

检查配置的端点是否为 `https://glossia.ai/mcp`，且您的网络允许编码代理访问该端点。如果托管服务仍然不可用，请联系 Glossia 支持。

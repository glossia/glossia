%{
  title: "REST API",
  summary: "以开发者为先的 REST API，配备 OpenAPI 文档、OAuth 2.1 认证及细粒度授权。您在控制台可进行的所有操作，均可通过 API 完成。",
  order: 4,
  icon: "终端",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI 文档支持",
      description: "完整的 OpenAPI 3.1 规范通过 Scalar 驱动交互式文档。探索端点，尝试请求，并从单一规范文件中生成客户端代码。",
      icon: "书籍"
    },
    %{
      title: "OAuth 2.1 和 PKCE",
      description: "动态客户端注册，带 PKCE 的授权码流程，令牌检查和撤销。第三方客户端无需共享密钥即可安全认证。",
      icon: "密钥"
    },
    %{title: "分页和筛选", description: "每个列表端点均原生支持基于页的分页、字段筛选和排序。可预测的响应元数据使构建客户端变得简单。", icon: "代码"}
  ]
}
---
## 开发者优先

REST API 是 Glossia 的核心。仪表板、CLI 和 [MCP 服务器](/features/mcp-server) 都调用相同的端点。当我们添加新功能时，它首先接入 API，然后从 API 统一暴露于其他所有渠道。

这意味着您永远不会被界面限制。您能想象的任何工作流，从 CI/CD 集成到自定义仪表板，都可以构建在同一个稳定且文档化的接口之上。

## 认证

Glossia 对所有 API 认证使用带 PKCE 的 OAuth 2.1。该流程同时支持第一方和第三方客户端。请参阅 [认证和授权文档](/docs/reference/apis/authentication) 了解完整指南。

**动态客户端注册** -- 客户端在 `/oauth/register` 处通过编程方式注册，携带它们的重定向 URI 和授权类型。无需手动审批步骤，无需点击门户跳转。

**带 PKCE 的授权码** -- 用户通过基于浏览器的同意屏幕授权客户端。PKCE 扩展确保令牌安全，即使对于无法存储密钥的公开客户端也是如此。

**令牌生命周期** -- 访问令牌可以通过标准 OAuth 端点进行交换、检查并撤销。令牌端点的速率限制可防止暴力破解。

## 授权

访问控制使用两层架构。[认证文档](/docs/reference/apis/authentication) 详细涵盖作用域、角色和完整的权限矩阵。

**作用域**定义令牌可访问的资源类别。带有 `voice:read` 的令牌可以读取语音配置，但无法对其进行修改。作用域遵循 `resource:action` 模式：`account:read`、`organization:write`、`glossary:admin` 用于术语管理，以此类推。

**策略**验证用户与特定资源之间的关系。即使拥有正确作用域的有效令牌，也无法访问用户不属于的组织。每个请求都会按照这两层进行检查。

## 分页、过滤和排序

所有列表端点均返回带有统一元数据结果的分页结果：

每个响应均包含 `total_count`、`total_pages`、`current_page`、`page_size`、`has_next_page?` 和 `has_previous_page?`，以便客户端无需猜测即可构建分页控件。

使用 `filters[field]=value` 查询参数按任意索引字段过滤。使用 `order_by[]` 参数按升序或降序排序。接口在所有资源处保持一致。

## OpenAPI 和交互式文档

完整的 OpenAPI 3.1 规范位于 `/api/openapi.json`。[交互式 API 参考](/docs/reference/apis/rest) 由 Scalar 支持，允许您从浏览器中探索端点、检查架构并直接发送测试请求。

任何语言的客户端库均可从规范生成。约定已版本化且稳定，因此当您发布新特性时，您的集成不会出现故障。
%{
  title: "REST API",
  summary: "一款面向开发者的 REST API，具备 OpenAPI 文档、OAuth 2.1 认证和细粒度授权。您可以在 API 中完成仪表盘上的所有操作。",
  order: 4,
  icon: "terminal",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "支持 OpenAPI 文档",
      description: "完整的 OpenAPI 3.1 规范通过 Scalar 提供交互式文档。探索端点、尝试请求，并从单一规范文件生成客户端代码。",
      icon: "book-open"
    },
    %{
      title: "支持 OAuth 2.1 及 PKCE",
      description: "支持动态客户端注册、PKCE 授权码流程、令牌内省和吊销。第三方客户端可安全认证，无需共享密钥。",
      icon: "key-round"
    },
    %{title: "分页与过滤", description: "所有列表端点均原生支持分页、字段过滤和排序。可预测的响应元数据简化了客户端构建。", icon: "code"}
  ]
}
---
## 开发者优先

REST API 是 Glossia 的核心。仪表板、CLI 和 [MCP 服务器](/features/mcp-server) 它们都使用相同的端点。当我们添加功能时，它首先在 API 上线，然后从那里在其他地方展现。

这意味着您永远不受界面限制。您可以想象的任何工作流，从 CI/CD 集成到自定义仪表板，都可以构建在相同的稳定、文档化接口之上。

## 身份验证

Glossia 对所有 API 身份验证使用带 PKCE 的 OAuth 2.1。该流程支持第一方和第三方客户端。查看 [身份验证和授权文档](/docs/reference/apis/authentication) 完整操作指南。

**动态客户端注册** -- 客户端通过程序化方式注册于 `/oauth/register` 携带其重定向 URI 和授权类型。无需手动审批步骤，无需点击门户。

**带有 PKCE 的授权码** -- 用户通过基于浏览器的同意屏幕授权客户端。PKCE 扩展确保令牌保持安全，即使对于无法存储密钥的公开客户端。

**令牌生命周期** -- 访问令牌可通过标准 OAuth 端点进行交换、内省和撤销。令牌端点的速率限制可防止暴力破解。

## 授权

访问控制包含两层。 [身份认证文档](/docs/reference/apis/authentication) 涵盖作用域、角色及完整的权限矩阵详情。

**作用域** 定义了令牌可访问的资源类别。一个带有 `voice:read` 特定作用域的令牌可以读取语音配置，但无法修改它们。作用域遵循 `resource:action` 模式： `account:read`、 `organization:write`, `glossary:admin` 用于术语表管理，等等。

**策略** 验证用户与特定资源之间的关系。即使拥有具有正确范围的有效令牌，用户也无法访问其不属于的组织。每个请求都会针对这两层进行检查。

## 分页、过滤和排序

所有列表端点都会返回带有统一元数据的分页结果：

每个响应都包含 `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, 且 `has_previous_page?` , 这样用户即可构建分页控件，无需猜测。

按任意索引字段过滤，使用 `filters[field]=value` , 查询参数。按升序或降序排序，使用 `order_by[]` 参数。在所有资源中界面保持一致。

## OpenAPI 与交互式文档

完整 OpenAPI 3.1 规范可在以下位置查阅 `/api/openapi.json`. 该 [交互式 API 参考](/docs/reference/apis/rest) 由 Scalar 驱动，支持您在浏览器中直接探索端点、检查模式并发送测试请求。

任何语言的客户端库均可基于规范生成。契约经过版本控制且保持稳定，因此在我们发布新功能时，您的集成不会中断。
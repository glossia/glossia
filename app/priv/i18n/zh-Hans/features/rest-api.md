%{
  title: "REST API",
  summary: "以开发者为先的 REST API，配备 OpenAPI 文档、OAuth 2.1 认证和细粒度授权。你在仪表板中能做的一切，都可以通过 API 完成。",
  order: 4,
  icon: "终端",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "拥有 OpenAPI 文档",
      description: "完整的 OpenAPI 3.1 规范通过 Scalar 提供交互式文档。探索端点、尝试请求，并从单个规范文件生成客户端代码。",
      icon: "文档"
    },
    %{
      title: "带有 PKCE 的 OAuth 2.1 认证",
      description: "支持动态客户端注册、带 PKCE 的授权码流、令牌检查和撤销。第三方客户端在非共享密钥的情况下进行安全身份验证。",
      icon: "密钥"
    },
    %{title: "分页与筛选", description: "所有列表端点默认支持基于页面的分页、字段筛选和排序。可预测的响应元数据简化了客户端构建。", icon: "代码"}
  ]
}
---
## 开发者优先

REST API 是 Glossia 的核心。仪表板、CLI 和 [MCP 服务器](/features/mcp-server) 它们都调用相同的端点。当我们添加功能时，它首先在 API 上实现，并由此在其他地方提供。

这意味着你永远不会受限于用户界面。任何工作流，从 CI/CD 集成到自定义仪表板，都可以构建在同一个稳定、文档化的接口之上。

## 认证

Glossia 对所有 API 认证均使用带 PKCE 的 OAuth 2.1 协议。该流程支持第一方和第三方客户端。查看 [认证与授权文档](/docs/reference/apis/authentication) 完整指南。

**动态客户端注册** -- 客户端通过编程方式在 `/oauth/register` 对其重定向 URI 和授权类型注册。无需手动审批步骤，无需点击门户。

**含 PKCE 的授权码** -- 用户通过基于浏览器的同意界面授权客户端。PKCE 扩展确保令牌即使对无法存储密钥的公开客户端也保持安全。

**令牌生命周期** -- 可通过标准 OAuth 端点交换、反检和撤销访问令牌。令牌端点的速率限制可防止暴力破解。

## 授权

访问控制采用两层架构。 [身份验证文档](/docs/reference/apis/authentication) 详细涵盖作用域、角色以及完整的权限矩阵。

**作用域** 定义令牌可访问的资源类别。拥有 `voice:read` 可以读取语音配置，但无法修改。作用域遵循 `resource:action` 模式： `account:read`, `organization:write`, `glossary:admin` ,用于术语管理，等等。

**策略** 验证用户与特定资源之间的关系。即使令牌具有正确的范围，用户仍无法访问其不属于的组织。每个请求都会针对这两层进行检查。

## 分页、过滤和排序

所有列表端点均返回带有元数据的分页结果：

每个响应包含 `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`和 `has_previous_page?` so clients can build pagination controls without guessing.

Filter by any indexed field using `filters[field]=value` query parameters. Sort ascending or descending with `order_by[]` 参数。该接口在所有资源中均保持一致。

## OpenAPI 和交互式文档

完整的 OpenAPI 3.1 规范可在以下位置获取 `/api/openapi.json`。该 [交互式 API 参考](/docs/reference/apis/rest) 由 Scalar 提供支持，允许您从浏览器直接探索端点、检查模式并发送测试请求。

任何语言的客户端库均可从规范中生成。该契约采用版本控制并保持稳定，因此当我们发布新功能时，您的集成不会受到影响。
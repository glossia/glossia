%{
  title: "REST API",
  summary: "一款以开发者为核心的 REST API，支持 OpenAPI 文档、OAuth 2.1 认证及细粒度授权。仪表板上可进行的操作，也均可通过 API 实现。",
  order: 4,
  icon: "终端",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "支持 OpenAPI 文档",
      description: "完整的 OpenAPI 3.1 规范通过 Scalar 提供交互式文档。您可以探索端点、测试请求，并从单个规范文件生成客户端代码。",
      icon: "文档"
    },
    %{
      title: "支持 OAuth 2.1 及 PKCE",
      description: "支持动态客户端注册、带 PKCE 的授权码流程、令牌稽查和吊销。第三方客户端无需共享凭证即可安全认证。",
      icon: "密钥"
    },
    %{
      title: "分页与过滤",
      description: "所有列表端点均支持基于页面的分页、字段过滤和排序，开箱即用。可预测的响应元数据使构建客户端变得简单。",
      icon: "代码"
    }
  ]
}
---
## 开发者优先

REST API 是 Glossia 的核心。仪表盘、CLI 以及 [MCP 服务器](/features/mcp-server) 均使用相同的端点。当我们添加功能时，它首先在 API 中落地，并由此在其他所有地方体现。

这意味着您永远不会受用户界面的限制。任何您可以想象的流程，从 CI/CD 集成到自定义仪表板，都可以基于同一套稳定、文档完善的接口构建。

## 认证

Glossia 使用 OAuth 2.1 结合 PKCE 进行所有 API 认证。该流程支持第一方和第三方客户端。请参阅 [认证和授权文档](/docs/reference/apis/authentication) 完整操作指南。

**动态客户端注册** -- 客户端在此处进行程序化注册 `/oauth/register` 及其重定向 URI 和授权类型。无需手动审批，无需点击任何门户。

**带 PKCE 的授权码** -- 用户通过浏览器授权界面授权客户端。PKCE 扩展确保令牌保持安全，即使对于无法存储密钥的公开客户端也是如此。

**令牌生命周期** -- 访问令牌可通过标准 OAuth 端点进行交换、内省和撤销。令牌端点的限流可防止暴力破解。

## 授权

访问控制使用两层。所述 [身份验证文档](/docs/reference/apis/authentication) 详细介绍了范围、角色以及完整的权限矩阵。

**范围** 定义了令牌可访问的资源类别。拥有 `voice:read` 可读取语音配置但无法修改它们。范围遵循 `resource:action` 模式： `account:read`, `organization:write`, `glossary:admin` for terminology administration, and so on.

**Policies** verify the relationship between the user and the specific resource. A valid token with the right scope still cannot access an organization the user does not belong to. Every request is checked against both layers.

## Pagination, filtering, and sorting

All list endpoints return paginated results with consistent metadata:

Every response includes `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?`, 和 `has_previous_page?` 这样客户端即可构建分页控件，无需猜测。

使用任何索引字段进行筛选 `filters[field]=value` 查询参数。按升序或降序排序 `order_by[]` 参数。界面在每个资源中保持一致。

## OpenAPI 和交互式文档

完整的 OpenAPI 3.1 规范可在 `/api/openapi.json`。该 [交互式 API 参考](/docs/reference/apis/rest) 由 Scalar 驱动，支持您探索端点、检查模式，并直接从浏览器发送测试请求。

任何语言的客户端库均可从规范中生成。契约经过版本控制且稳定，因此即使我们发布新功能，您的集成也不会中断。
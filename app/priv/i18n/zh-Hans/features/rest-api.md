%{
  title: "REST API",
  summary: "面向开发者的 REST API，提供 OpenAPI 文档、OAuth 2.1 身份验证和精细粒度授权。您可以通过 API 完成仪表板中的所有操作。",
  order: 4,
  icon: "terminal",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "完整的 OpenAPI 文档", description: "完整的 OpenAPI 3.1 规范通过 Scalar 提供交互式文档。您可以基于同一份规范文件浏览端点、尝试请求并生成客户端代码。", icon: "book-open"},
    %{title: "采用 PKCE 的 OAuth 2.1", description: "支持动态客户端注册、采用 PKCE 的授权码流程、令牌内省和撤销。第三方客户端无需共享密钥即可安全地进行身份验证。", icon: "key-round"},
    %{title: "分页和筛选", description: "每个列表端点均默认支持基于页码的分页、字段筛选和排序。可预测的响应元数据让客户端开发更直接。", icon: "code"}
  ]
}
---
## 开发者优先

REST API 是 Glossia 的核心基础。控制面板、CLI 和 [MCP 服务器](/features/mcp-server)均使用相同的端点。我们添加功能时，会先在 API 中实现，再由此应用到其他所有界面。

这意味着您永远不会受限于 UI。无论是 CI/CD 集成还是自定义控制面板，您设想的任何工作流都可以基于同一个稳定且有完善文档的接口构建。

## 身份验证

Glossia 的所有 API 身份验证均使用带 PKCE 的 OAuth 2.1。该流程同时支持第一方和第三方客户端。有关完整操作说明，请参阅[身份验证和授权文档](/docs/reference/apis/authentication)。

**动态客户端注册** - 客户端通过 `/oauth/register` 以编程方式注册其重定向 URI 和授权类型。无需手动审批，也无需进入门户完成操作。

**带 PKCE 的授权码** - 用户通过基于浏览器的同意界面授权客户端。PKCE 扩展可确保令牌安全，即使对于无法存储密钥的公共客户端也是如此。

**令牌生命周期** - 可通过标准 OAuth 端点交换、内省和撤销访问令牌。令牌端点的速率限制可防止暴力破解。

## 授权

访问控制采用两层机制。[身份验证文档](/docs/reference/apis/authentication)详细说明了作用域、角色和完整的权限矩阵。

**作用域**定义令牌可以访问哪些类别的资源。具有 `voice:read` 的令牌可以读取语调配置，但无法修改它们。作用域遵循 `resource:action` 模式，例如 `account:read`、`organization:write`、用于术语管理的 `glossary:admin`，依此类推。

**策略**验证用户与特定资源之间的关系。即使令牌有效且具有正确的作用域，也无法访问用户不属于的组织。每个请求都会同时通过这两层检查。

## 分页、筛选和排序

所有列表端点都返回带有一致元数据的分页结果：

每个响应都包含 `total_count`、`total_pages`、`current_page`、`page_size`、`has_next_page?` 和 `has_previous_page?`，因此客户端无需猜测即可构建分页控件。

使用 `filters[field]=value` 查询参数按任意已建立索引的字段筛选。使用 `order_by[]` 参数进行升序或降序排序。所有资源都使用相同的接口。

## OpenAPI 和交互式文档

完整的 OpenAPI 3.1 规范可在 `/api/openapi.json` 获取。[交互式 API 参考文档](/docs/reference/apis/rest)由 Scalar 提供支持，您可以直接在浏览器中浏览端点、检查架构并发起测试请求。

可以根据该规范生成任意语言的客户端库。接口契约具有版本管理机制且保持稳定，因此我们发布新功能时不会破坏您的集成。
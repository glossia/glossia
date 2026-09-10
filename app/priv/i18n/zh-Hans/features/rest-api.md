%{
  title: "REST API",
  summary: "这是一款面向开发者的 REST API，具备 OpenAPI 文档、OAuth 2.1 认证及细粒度授权功能。在仪表盘上能完成的所有操作，均可通过 API 实现。",
  order: 4,
  icon: "终端",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI 文档",
      description: "完整的 OpenAPI 3.1 规范通过 Scalar 提供交互式文档。您可以探索端点、测试请求，并从单个规范文件生成客户端代码。",
      icon: "文档"
    },
    %{
      title: "支持 PKCE 的 OAuth 2.1",
      description: "支持动态客户端注册、PKCE 授权码流程、令牌内省和撤销。第三方客户端无需共享密钥即可安全认证。",
      icon: "密钥"
    },
    %{title: "分页与筛选", description: "所有列表端点均开箱即用，支持基于页的分页、字段筛选和排序。一致的响应元数据使客户端构建更加简便。", icon: "代码"}
  ]
}
---
## 开发者优先

REST API 是 Glossia 的核心。仪表盘、CLI 和[MCP 服务器](/features/mcp-server)都使用相同的 API 端点。当我们添加新功能时，它首先在 API 中落地，然后从那里暴露到所有其他端点。

这意味着您永远不受 UI 限制。任何您可以想象的流程，从 CI/CD 集成到自定义仪表盘，都可以构建在同样稳定、文档化的接口之上。

## 认证

Glossia 对所有 API 认证均使用基于 PKCE 的 OAuth 2.1。该流程同时支持自有方和第三方客户端。请见[身份认证和授权文档](/docs/reference/apis/authentication)以获取完整介绍。

**动态客户端注册** -- 客户端通过编程方式注册在`/oauth/register`其重定向 URI 和授权类型处。无手动审批步骤，无需浏览门户。

**使用 PKCE 的授权代码** -- 用户通过基于浏览器的同意屏幕授权客户端。PKCE 扩展确保令牌即使对于无法存储秘密的公共客户端也能保持安全。

**令牌生命周期** -- 访问令牌可以通过标准 OAuth 端点进行交换、查询和撤销。令牌端点的速率限制可防止暴力破解。

## 授权

访问控制使用两层。[身份认证文档](/docs/reference/apis/authentication)详细介绍了作用域、角色和完整的权限矩阵。

**作用域**定义令牌可以访问的资源类别。带有 `voice:read`的令牌可以读取语音配置，但不能修改它们。作用域遵循`resource:action`模式：`account:read`，`organization:write`，`glossary:admin`用于术语管理，以此类推。

**策略**验证用户与特定资源之间的关系。即使令牌有效且具有正确的作用域，仍无法访问用户不属于的组织。每个请求都会对照两层进行检查。

## 分页、筛选和排序

所有列表端点都会返回带有元数据的分页结果：

每个响应都包含 `total_count`、`total_pages`、`current_page`、`page_size`、`has_next_page?`和 `has_previous_page?`，以便客户端在无需猜测的情况下构建分页控件。

可以使用 `filters[field]=value`查询参数筛选任何索引字段。使用`order_by[]`参数对数据进行升序或降序排序。每个资源接口均保持一致。

## OpenAPI 和交互式文档

完整的 OpenAPI 3.1 规范位于 `/api/openapi.json`。[交互式 API 参考](/docs/reference/apis/rest)由 Scalar 支持，允许您在浏览器中探索端点、检查架构并直接发送测试请求。

任何语言的客户端库都可以从规范中生成。合约是版本化且稳定的，因此当发布新功能时，您的集成不会出现问题。
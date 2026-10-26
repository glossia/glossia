%{
  title: "REST API",
  summary: "面向开发者的 REST API，具备 OpenAPI 文档、OAuth 2.1 认证和细粒度权限控制。您可在 API 中执行仪表盘中的所有操作。",
  order: 4,
  icon: "终端",
  hero_cta_text: "立即开始",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI 文档",
      description: "完整的 OpenAPI 3.1 规范支持通过 Scalar 提供交互式文档。探索端点、测试请求，并从单个规范文件生成客户端代码。",
      icon: "文档"
    },
    %{
      title: "OAuth 2.1 (支持 PKCE)",
      description: "动态客户端注册、含 PKCE 的授权码流程、令牌的审查与吊销。第三方客户端可安全认证，无需共享秘密。",
      icon: "密钥"
    },
    %{title: "分页与筛选", description: "所有列表端点均原生支持基于页码的分页、字段筛选及排序。可预测的响应元数据简化了客户端开发。", icon: "代码"}
  ]
}
---

## 开发者优先

REST API 是 Glossia 的基石。仪表板、CLI 和 [MCP 服务器](/features/mcp-server) 都使用相同的端点。当我们添加功能时，它首先落地在 API 中，并由此向其他所有地方呈现。

这意味着您永远不会受到 UI 的限制。从 CI/CD 集成到自定义仪表板，您可以想象的任何工作流都可以构建在相同的、稳定且文档齐全的接口之上。

## 身份验证

Glossia 对所有 API 身份验证均使用带有 PKCE 的 OAuth 2.1。该流程同时支持一级和第三方客户端。请参阅 [身份验证和授权文档](/docs/reference/apis/authentication) 获取完整指南。

**动态客户端注册** -- 客户端在 `/oauth/register` 以程序方式注册，带入其重定向 URI 和授权类型。无需手动审批步骤，也无需点击任何门户。

**带有 PKCE 的授权码** -- 用户通过基于浏览器的同意屏幕授权客户端。PKCE 扩展确保证书安全，即使对于无法存储密钥的公开客户端也是如此。

**令牌生命周期** -- 访问令牌可通过标准 OAuth 端点进行交换、检测和撤销。令牌端点的速率限制可防止暴力破解。

## 授权

访问控制使用两层。[身份验证文档](/docs/reference/apis/authentication) 详细介绍了范围、角色和完整的权限矩阵。

**权限范围** 定义令牌可以访问的资源类别。带有 `voice:read` 的令牌可以读取语音配置，但不能修改它们。权限范围遵循 `resource:action` 模式：`account:read`, `organization:write`, `glossary:admin` 用于词库管理，等等。

**策略** 验证用户与特定资源之间的关系。拥有正确范围的合法令牌仍无法访问用户不属于的组织。每个请求都会针对这两层进行检查。

## 分页、筛选和排序

所有列表端点均返回带有统一元数据的数据：

每个响应均包含 `total_count`、`total_pages`、`current_page`、`page_size`、`has_next_page?` 和 `has_previous_page?`，以便客户端无需猜测即可构建分页控件。

使用 `filters[field]=value` 查询参数按任何索引字段筛选。使用 `order_by[]` 参数按升序或降序排序。每个资源的接口均相同。

## OpenAPI 和交互式文档

完整的 OpenAPI 3.1 规范可在 `/api/openapi.json` 获取。[交互式 API 参考](/docs/reference/apis/rest) 由 Scalar 驱动，让您可以在浏览器中直接探索端点、检查模式并发起测试请求。

各种语言的客户端库均可从规范中生成。该契约是版本化且稳定的，因此当我们发布新功能时，您的集成不会中断。

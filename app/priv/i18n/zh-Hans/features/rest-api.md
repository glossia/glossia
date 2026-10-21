%{
  title: "REST API",
  summary: "一款面向开发者的 REST API，提供 OpenAPI 文档、OAuth 2.1 认证和细粒度授权。您在仪表板中能完成的所有操作，都可通过 API 完成。",
  order: 4,
  icon: "terminal",
  hero_cta_text: "立即开始",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "支持 OpenAPI 文档",
      description: "完整的 OpenAPI 3.1 规范通过 Scalar 提供交互式文档。探索端点，测试请求，并从单一规范文件生成客户端代码。",
      icon: "book-open"
    },
    %{
      title: "OAuth 2.1 与 PKCE",
      description: "支持动态客户端注册、带有 PKCE 的授权码流程、令牌检查与撤销。第三方客户端可安全认证，无需共享密钥。",
      icon: "key-round"
    },
    %{
      title: "分页与筛选",
      description: "所有列表端点均原生支持基于页的分页、字段筛选和排序。可预测的响应元数据使得构建客户端更加简单。",
      icon: "code"
    }
  ]
}
---

## 开发者优先

REST API 是 Glossia 的核心。仪表板、CLI 和 [MCP 服务器](/features/mcp-server) 均使用相同的端点。当我们添加功能时，它首先在 API 中落地，然后展现至所有其他位置。

这意味着你永远不会受限于界面。任何你能想象到的工作流，从 CI/CD 集成到自定义仪表板，都可以建立在同一稳定、文档化界面之上。

## 身份验证

Glossia 在所有 API 认证中使用带 PKCE 的 OAuth 2.1。该流程支持第一方和第三方客户端。请查看 [身份验证和授权文档](/docs/reference/apis/authentication) 获取完整指南。

**动态客户端注册** -- 客户端在 `/oauth/register` 处通过程序注册其重定向 URI 和授权类型。没有手动审批步骤，没有需要点击的门户。

**带 PKCE 的授权码** -- 用户通过基于浏览器的同意屏幕授权客户端。PKCE 扩展确保令牌保持安全，即使是那些无法存储秘密的公开客户端也是如此。

**令牌生命周期** -- 访问令牌可以通过标准 OAuth 端点交换、检查并撤销。令牌端点的速率限制可抵御暴力破解。

## 授权

访问控制使用两层。[身份验证文档](/docs/reference/apis/authentication) 详细涵盖了范围、角色和完整的权限矩阵。

**范围** 定义了令牌可访问的资源类别。带有 `voice:read` 范围的令牌可以读取语音配置，但不能修改它们。范围遵循 `resource:action` 模式：`account:read`, `organization:write`, `glossary:admin` 用于术语表管理，等等。

**策略** 验证用户与特定资源之间的关系。即使拥有有效令牌和正确的范围，用户仍无法访问其不属于的组织。每个请求都会针对这两层进行检查。

## 分页、筛选和排序

所有列表端点均返回带有一致元数据的分页结果：

每个响应包含 `total_count`, `total_pages`, `current_page`, `page_size`, `has_next_page?` 和 `has_previous_page?`，因此客户端无需猜测即可构建分页控件。

使用 `filters[field]=value` 查询参数筛选任何索引字段。使用 `order_by[]` 参数进行升序或降序排序。每个资源的界面都是一样的。

## OpenAPI 和交互式文档

完整的 OpenAPI 3.1 规范可在 `/api/openapi.json` 获取。[交互式 API 参考](/docs/reference/apis/rest) 由 Scalar 提供支持，使您能够直接通过浏览器探索端点、检查架构并发送测试请求。

任何语言的客户端库均可从规范中生成。该合同版本化且稳定，因此即使我们发布新功能，您的集成也不会中断。

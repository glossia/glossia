%{
  title: "REST API",
  summary: "面向开发者的 REST API，具备 OpenAPI 文档、OAuth 2.1 身份验证和细粒度授权。您在仪表盘中可以做的所有操作，都可以通过 API 完成。",
  order: 4,
  icon: "terminal",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI 文档",
      description: "完整的 OpenAPI 3.1 规范通过 Scalar 提供交互式文档。探索端点、尝试请求，并从单个规范文件生成客户端代码。",
      icon: "book-open"
    },
    %{
      title: "带有 PKCE 的 OAuth 2.1",
      description: "支持动态客户端注册、包含 PKCE 的授权码流、令牌检查及撤销。第三方客户端可安全认证而无需共享密钥。",
      icon: "key-round"
    },
    %{title: "分页和筛选", description: "每个列表端点都支持基于分页、字段过滤和内置排序。可预测的响应元数据使得构建客户端变得简单。", icon: "code"}
  ]
}
---

## 开发者优先

REST API 是 Glossia 的基石。仪表板、CLI 和 [MCP 服务器](/features/mcp-server) 都消耗相同的端点。当我们添加功能时，它首先在 API 中落地，随后从那里呈现在其余所有地方。

这意味着你永远不会受限于 UI。任何你能想象到的工作流，从 CI/CD 集成到自定义仪表板，都可以建立在相同的稳定、文档化的接口之上。

## 身份验证

Glossia 使用带有 PKCE 的 OAuth 2.1 进行所有 API 身份验证。该流程支持第一方和第三方客户端。查看 [身份验证和授权文档](/docs/reference/apis/authentication) 获取完整教程。

**动态客户端注册** -- 客户端在 `/oauth/register` 处自动注册，带有其跳转 URI 和授权类型。无需人工审批步骤，无需点击门户。

**带有 PKCE 的授权代码** -- 用户通过基于浏览器的同意屏幕授权客户端。PKCE 扩展确保令牌即使对于无法存储密钥的公共客户端也能保持安全。

**令牌生命周期** -- 访问令牌可以通过标准 OAuth 端点进行交换、查询和撤销。令牌端点的速率限制防止暴力破解。

## 授权

访问控制使用两层。 [身份验证文档](/docs/reference/apis/authentication) 详细涵盖范围、角色和完整的权限矩阵。

**作用域** 定义了令牌可以访问的资源类别。带有 `voice:read` 的令牌可以读取语音配置但无法修改它们。作用域遵循 `resource:action` 模式：`account:read`、`organization:write`、`glossary:admin` 用于术语管理，以此类推。

**策略** 验证了用户与特定资源之间的关系。一个具有正确范围的合法令牌仍然无法访问用户不属于的组织。每个请求都会经过两层检查。

## 分页、筛选和排序

所有列表端点都返回带有统一元数据的分页结果：

每个响应都包括 `total_count`、`total_pages`、`current_page`、`page_size`、`has_next_page?` 和 `has_previous_page?`，因此客户端可以在不猜测的情况下构建分页控件。

使用 `filters[field]=value` 查询参数筛选任何索引字段。使用 `order_by[]` 参数按升序或降序排序。每个资源的接口都相同。

## OpenAPI 和交互式文档

完整的 OpenAPI 3.1 规范可在 `/api/openapi.json` 获取。该 [交互式 API 参考](/docs/reference/apis/rest) 由 Scalar 驱动，允许您直接在浏览器中探索端点、检查模式并发送测试请求。

任何语言的客户端库都可以基于规范生成。该合同是版本化且稳定的，因此无论我们发布什么新特性，你的集成都不会中断。

%{
  title: "REST API",
  summary: "一个面向开发者的 REST API，配备 OpenAPI 文档、OAuth 2.1 认证和细粒度授权。您在仪表板中能够做的每一件事，均可以通过 API 完成。",
  order: 4,
  icon: "终端",
  hero_cta_text: "开始",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "OpenAPI 文档",
      description: "完整的 OpenAPI 3.1 规范通过 Scalar 提供交互式文档。探索端点、尝试请求，并从单个规范文件生成客户端代码。",
      icon: "book-open"
    },
    %{
      title: "带 PKCE 的 OAuth 2.1",
      description: "支持动态客户端注册、带 PKCE 的授权代码流、令牌内省和吊销。第三方客户端无需共享密钥即可安全认证。",
      icon: "key-round"
    },
    %{title: "分页和筛选", description: "列表端点均支持基于页面的分页、字段筛选和开箱即用的排序。可预测的响应元数据使客户端构建更加简单。", icon: "代码"}
  ]
}
---
## 开发者优先

REST API 是 Glossia 的基石。仪表盘、CLI 以及 [MCP 服务器](/features/mcp-server) 它们都调用相同的端点。当我们添加功能时，它首先接入 API，随后从那里同步到所有其他渠道。

这意味着你永远不受用户界面的限制。任何你能想到的工作流，从 CI/CD 集成到自定义仪表盘，都可以构建在同一套稳定且文档化的接口之上。

## 身份验证

Glossia 在所有 API 认证中均使用带有 PKCE 的 OAuth 2.1。该流程支持第一方和第三方客户端。查看 [身份验证与授权文档](/docs/reference/apis/authentication) 完整操作指南。

**动态客户端注册** -- 客户端可程序化注册于 `/oauth/register` 并带有其重定向 URI 和授权类型。无需手动审批步骤，无需点击门户。

**带 PKCE 的授权码** -- 用户通过基于浏览器的同意界面授权客户端。PKCE 扩展确保令牌保持安全，即使对于无法存储密钥的公开客户端也适用。

**令牌生命周期** -- 访问令牌可通过标准 OAuth 端点进行交换、检查和吊销。令牌端点的速率限制保护免受暴力破解。

## 授权

访问控制采用两层机制。 [身份验证文档](/docs/reference/apis/authentication) 详细涵盖作用域、角色及完整权限矩阵。

**作用域** 定义令牌可访问的资源类别。一个具有 `voice:read` 的令牌可读取语音配置但无法修改它们。作用域遵循 `resource:action` 模式： `account:read`， `organization:write`， `glossary:admin` 包括术语管理等功能。

**策略** 验证用户与特定资源之间的关系。即使持有具有正确范围的合法令牌，也无法访问用户不隶属的组织。每个请求都会经过两层检查。

## 分页、过滤和排序

所有列表端点均返回具有统一元数据的分页结果：

每个响应都包含 `total_count`, `total_pages`, `current_page`重组后的文档先前验证失败：Markdown 文本字面量恢复必须返回长度匹配的 JSON 字符串数组 `page_size`重组后的文档此前验证失败：Markdown 文本字面量恢复必须返回长度匹配的 JSON 字符串数组 `has_next_page?`，以及 `has_previous_page?` 这样，客户端无需猜测即可构建分页控件。

按任意索引字段筛选，使用 `filters[field]=value` 查询参数。按升序或降序排序，使用 `order_by[]` 参数。所有资源的接口均相同。

## OpenAPI 和交互式文档

完整的 OpenAPI 3.1 规范可在 `/api/openapi.json`. 该 [交互式 API 参考](/docs/reference/apis/rest) 由 Scalar 提供支持，可直接在浏览器中探索端点、检查模式，并发送测试请求。

任何语言的客户端库均可从规范生成。协议经过版本控制且稳定，因此当我们发布新功能时，您的集成也不会中断。
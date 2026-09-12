%{
  title: "MCP 服务器",
  summary: "通过模型上下文协议将 AI 智能体和编程助手连接到 Glossia。使用任何 MCP 兼容客户端的自然语言管理声音、术语和组织等。",
  order: 3,
  icon: "cpu",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "自然语言接口",
      description: "通过纯文本与 Glossia 的语言引擎交互。AI 智能体调用 MCP 工具来管理声音、术语和组织，无需编写代码。",
      icon: "message-square-text"
    },
    %{
      title: "接入任意智能体",
      description: "支持 Claude、Cursor、Windsurf 及任何 MCP 兼容客户端。将 Glossia 服务器放入您现有的智能体工作流中，立即开始使用。",
      icon: "puzzle"
    },
    %{
      title: "默认安全",
      description: "每个 MCP 请求均通过 OAuth 2.1 访问令牌进行认证，并根据细粒度范围授权。采用与 REST API 相同的安全模型。",
      icon: "shield-check"
    }
  ]
}
---
## 什么是 MCP？

该 [模型上下文协议](https://modelcontextprotocol.io) 是连接 AI 助手与外部工具和数据来源的开放标准。您无需为每个编程助手构建自定义集成，只需暴露一个 MCP 服务器，任何兼容的客户端均可使用它。

Glossia 的 MCP 服务器为智能体提供平台的语言核心的直接访问权限：语音配置、术语管理、组织管理以及项目列表。

## 可用工具

MCP 服务器提供 16 个工具，围绕您日常工作的资源进行组织。查看 [完整工具参考](/docs/reference/mcp/tools) 有关参数和用法详情。

**账户与组织** -- 列出您的账户，创建和管理组织，邀请成员并控制访问权限。智能体可通过对话设置整个团队结构。

**声音配置** -- 查看并更新控制 Glossia 生成和修订内容的声音设置。无需离开编辑器即可调整语气、正式度、目标受众及各区域覆盖。

**术语管理** -- 保持所有内容中的术语一致性。添加、更新并版本化术语条目，确保智能体始终使用正确的术语。

**项目** -- 列出并审查各组织间的项目。

## 工作原理

将您的 MCP 客户端指向 `https://your-glossia-instance/mcp` 并通过 OAuth Bearer 令牌进行身份验证。该 [MCP 设置指南](/docs/reference/mcp/overview) 遍历完整的连接流程，包括动态客户端注册和 PKCE。该 [REST API](/features/rest-api)，因此适用于 API 的任何令牌同样适用于 MCP。

随后，您的 AI 助手可以调用 16 个工具中的任意一个。请让它“创建一个名为 Acme 的组织”或“将我的声音语调更新为专业”，代理会将您的意图转换为相应的工具调用。

## 专为代理工作流打造

MCP 不仅仅是一个便利层。它是将 Glossia 整合到更大代理流水线中的基础。编程助手可以在单次对话中读取您的代码库、检测未本地化内容、使用新术语更新术语、调整特定语言的声音设置，并触发本地化运行。

由于协议是标准化的，您不会局限于任何单一客户端。无需修改一行配置，即可在 Claude、Cursor 或您自己的定制代理之间切换。
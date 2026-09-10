%{
  title: "MCP 服务器",
  summary: "通过模型上下文协议将 AI 代理与编程助手连接到 Glossia。使用自然语言管理语音、术语及组织等，适用于任何兼容 MCP 的客户端。",
  order: 3,
  icon: "cpu",
  hero_cta_text: "立即开始",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "自然语言界面",
      description: "通过纯文本与 Glossia 语言引擎交互。AI 代理调用 MCP 工具管理语音、术语和组织，无需编写代码。",
      icon: "message-square-text"
    },
    %{
      title: "接入任意代理",
      description: "支持 Claude、Cursor、Windsurf 及任何兼容 MCP 的客户端。将 Glossia 服务器集成至您的现有代理工作流中并立即使用。",
      icon: "puzzle"
    },
    %{
      title: "默认安全",
      description: "每个 MCP 请求均通过 OAuth 2.1 访问令牌进行身份验证并基于细粒度范围授权，采用与 REST API 相同的安全模型。",
      icon: "shield-check"
    }
  ]
}
---
## 什么是 MCP？

该 [模型上下文协议](https://modelcontextprotocol.io) 是一种连接 AI 助手与外部工具和数据来源的开放标准。无需为每个编程助手构建自定义集成，您只需暴露一个 MCP 服务器，任何兼容的客户端均可使用。

Glossia 的 MCP 服务器为智能体提供平台语言核心的直接访问权限：语音配置、术语管理、组织管理及项目列表。

## 可用工具

该 MCP 服务器提供 16 个按您日常资源组织的工具。查看 [完整工具参考](/docs/reference/mcp/tools) 用于参数和用法详情。

**账户与组织** -- 列出您的账户，创建和管理组织，邀请成员并控制访问权限。智能体可通过对话搭建整个团队结构。

**语音配置** -- 查看并更新语音设置，以控制 Glossia 生成和修订内容的方式。在不离开编辑器的情况下，调整语气、正式程度、目标受众及本地化覆盖。

**术语管理** -- 维护所有内容的术语一致性。添加、更新和版本化术语条目，确保智能体始终使用正确的术语。

**项目** -- 列出并检查跨组织的项目。

## 工作原理

将您的 MCP 客户端指向 `https://your-glossia-instance/mcp` 并通过 OAuth bearer token 进行身份验证。该 [MCP 设置指南](/docs/reference/mcp/overview) 详细介绍了完整的连接流程，包括动态客户端注册和 PKCE。服务器使用相同的身份验证和授权系统与 [REST API](/features/rest-api)，因此适用于 API 的任何令牌也适用于 MCP。

从那里开始，您的 AI 助手可以调用这 16 个工具中的任何一项。您可以让它"创建一个名为 Acme 的组织"，或"更新我的语音语调为专业"，智能体将您的意图转化为正确的工具调用。

## 专为智能体工作流构建

MCP 不仅仅是一个便捷层。它是将 Glossia 集成到更大智能体流水线的基础。编程助手可以读取代码库，检测未本地化内容，用新术语更新术语，针对特定区域调整语音设置，并触发本地化运行，所有这些操作都在一次对话中完成。

由于该协议是标准化的，您不会被锁定在单一客户端上。您可以在 Claude、Cursor 或您自己的自定义智能体之间切换，而无需更改一行配置。
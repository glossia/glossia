%{
  title: "MCP 服务器",
  summary: "通过模型上下文协议将 AI 代理和编码助手连接到 Glossia。使用任何兼容的 MCP 客户端的自然语言来管理语音、词汇表、组织等。",
  order: 3,
  icon: "cpu",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "自然语言界面",
      description: "通过纯文本与 Glossia 的语言引擎交互。AI 代理调用 MCP 工具来管理语音、词汇表和组织，无需编写代码。",
      icon: "message-square-text"
    },
    %{
      title: "接入任意代理",
      description: "兼容 Claude、Cursor、Windsurf 及任何兼容的 MCP 客户端。将 Glossia 服务器集成至现有的代理工作流中即可立即使用。",
      icon: "puzzle"
    },
    %{
      title: "默认安全",
      description: "所有 MCP 请求均通过 OAuth 2.1 访问令牌进行身份验证，并针对细粒度作用域进行授权。采用与 REST API 相同的安全模型。",
      icon: "shield-check"
    }
  ]
}
---

## 什么是 MCP？

[MCP 语境协议](https://modelcontextprotocol.io) 是一项开放标准，用于将 AI 助手连接到外部工具和数据来源。您无需为每个编程助手构建自定义集成，只需暴露一个单一的 MCP 服务器，任何兼容的客户端都可以使用它。

Glossia 的 MCP 服务器为代理提供直接访问平台语言核心：语音配置、术语管理、组织管理和项目列表。

## 可用工具

MCP 服务器提供 16 个工具围绕您每日使用的资源组织。查阅 [完整工具参考](/docs/reference/mcp/tools)，了解参数和使用详情。

**账户和组织** -- 列出您的账户，创建和管理组织，邀请成员，并控制访问。代理可以通过对话设置整个团队结构。

**语音配置** -- 读取和更新语音设置，控制 Glossia 如何生成和修订内容。调整语气、正式程度、目标受众和每区域覆盖范围，无需离开编辑器。

**术语管理** -- 维护所有内容的术语一致性。添加、更新和版本化管理术语条目，确保代理始终使用正确的术语。

**项目** -- 列出并检查组织中的项目。

## 工作原理

将您的 MCP 客户端指向 `https://your-glossia-instance/mcp`，并使用 OAuth Bearer 令牌进行身份验证。 [MCP 设置指南](/docs/reference/mcp/overview) 介绍完整的连接流程，包括动态客户端注册和 PKCE。服务器使用与 [REST API](/features/rest-api) 相同的身份验证和授权系统，因此任何适用于 API 的令牌也适用于 MCP。

从那时起，您的 AI 助手可以调用任何 16 个工具中的任何一个。要求它“创建一个名为 Acme 的组织”或“更新我的语音语气为专业”，该代理会将您的意图转换为正确的工具调用。

## 专为代理工作流构建

MCP 不仅仅是一个便利层。它是将 Glossia 集成到更大代理管道的基石。编程助手可以读取代码库、检测未本地化内容、用新术语更新术语表、为特定区域调整语音设置，并触发本地化运行，所有这些都在单个对话中完成。

due to the standardized protocol, you are not restricted to any single client. You can seamlessly switch between Claude, Cursor, or your own custom agent without modifying a single line of configuration.

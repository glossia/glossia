%{
  title: "MCP 服务器",
  summary: "通过模型上下文协议 (MCP) 将 AI 代理和编程助手连接到 Glossia。利用自然语言，通过任何兼容 MCP 的客户端管理语音、术语、组织及其他内容。",
  order: 3,
  icon: "cpu",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "自然语言界面",
      description: "通过纯文本与 Glossia 的语言引擎进行交互。AI 代理调用 MCP 工具来管理语音、术语和组织，而无需编写代码。",
      icon: "message-square-text"
    },
    %{
      title: "连接任何智能体",
      description: "兼容 Claude、Cursor、Windsurf 以及任何支持 MCP 的客户端。将 Glossia 服务器集成到您的现有代理工作流中，立即开始使用。",
      icon: "puzzle"
    },
    %{
      title: "默认安全",
      description: "每个 MCP 请求均通过 OAuth 2.1 访问令牌进行身份验证，并根据细粒度作用域获得授权。采用与 REST API 相同的安全模型。",
      icon: "shield-check"
    }
  ]
}
---
## MCP 是什么？

该 [模型上下文协议](https://modelcontextprotocol.io) 是连接 AI 助手与外部工具和数据源的开放标准。无需为每个编程助手构建自定义集成，您只需提供单一 MCP 服务器，任何兼容客户端均可使用它。

Glossia 的 MCP 服务器为代理提供直接访问平台语言核心：语音配置、术语管理、组织管理和项目列表。

## 可用工具

该 MCP 服务器提供围绕您日常处理资源的 16 个工具。查看 [完整工具参考](/docs/reference/mcp/tools) 有关参数和使用详情。

**账户与组织** -- 列出您的账户，创建和管理组织，邀请成员并控制访问权限。代理可通过对话设置整个团队结构。

**语音配置** -- 读取并更新控制 Glossia 生成和修订内容的语音设置。无需离开编辑器即可调整语气、正式程度、目标受众以及各区域覆盖。

**术语管理** -- 保持所有内容中的术语一致性。添加、更新并管理术语条目的版本，以确保代理始终使用正确的术语。

**项目** -- 列出并检查跨组织的项目。

## 工作原理

将您的 MCP 客户端指向 `https://your-glossia-instance/mcp` 并使用 OAuth bearer 令牌进行身份验证。该 [MCP 设置指南](/docs/reference/mcp/overview) 详细介绍了完整的连接流程，包括动态客户端注册和 PKCE。该 [REST API](/features/rest-api), 因此任何适用于 API 的令牌也适用于 MCP.

此后，您的 AI 助手可以调用 16 种工具中的任意一种。您可以指示它"创建一个名为 Acme 的组织"或"将我的语音语调更新为专业"，代理会将您的意图转化为正确的工具调用。

## 专为代理工作流打造

MCP 不仅仅是一个便利层。它是将 Glossia 构建到更大代理流水线的基础。编程助手可以读取您的代码库，检测未本地化内容，用新术语更新术语表，针对特定区域调整语音设置，并触发一次本地化运行，所有这些都能在单次对话中完成。

由于该协议是标准化的，您不会被锁定在任何一个客户端上。您可以在 Claude、Cursor 或您自己的定制代理之间自由切换，而无需更改一行配置。
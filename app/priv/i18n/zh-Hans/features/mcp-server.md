%{
  title: "MCP 服务器",
  summary: "通过模型上下文协议将 AI 智能体和编程助手连接到 Glossia。在任意 MCP 兼容客户端中，使用自然语言管理语音、术语表、组织等。",
  order: 3,
  icon: "cpu",
  hero_cta_text: "立即开始",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "自然语言界面",
      description: "通过纯文本与 Glossia 的语言引擎交互。AI 智能体调用 MCP 工具管理语音、术语表和组织，无需编写代码。",
      icon: "message-square-text"
    },
    %{
      title: "接入任何智能体",
      description: "支持 Claude、Cursor、Windsurf 及任意 MCP 兼容客户端。将 Glossia 服务器部署到您现有的智能体工作流中，立即开始使用。",
      icon: "puzzle"
    },
    %{
      title: "默认安全",
      description: "每个 MCP 请求均通过 OAuth 2.1 Bearer 令牌验证，并根据细粒度范围授权。采用与 REST API 相同的安全模型。",
      icon: "shield-check"
    }
  ]
}
---

## MCP 是什么？

[Model Context Protocol](https://modelcontextprotocol.io) 是用于连接 AI 助手与外部工具和数据来源的开放标准。与其为每个编程助手构建自定义集成，不如暴露一个单一的 MCP 服务器，任何兼容的客户端都可以使用它。

Glossia 的 MCP 服务器为代理提供对平台语言核心的直接访问：语音配置、术语表管理、组织管理和项目列表。

## 可用工具

MCP 服务器提供了 16 个工具，围绕您日常使用的资源组织。有关参数和使用详情的，请参阅 [完整工具引用](/docs/reference/mcp/tools)。

**Accounts and organizations** -- 列出您的账户、创建和管理组织、邀请成员并控制访问。代理可以通过对话设置整个团队结构。

**Voice configuration** -- 读取和更新控制 Glossia 生成和修订内容的语音设置。在不离开编辑器的情况下调整语气、正式度、目标受众和本地化覆盖。

**Glossary management** -- 在所有内容中维护术语表的一致性。添加、更新和版本化术语表条目，以便代理始终使用正确的术语。

**Projects** -- 列出并检查跨组织的项目。

## 工作原理

将您的 MCP 客户端指向 `https://your-glossia-instance/mcp` 并使用 OAuth Bearer 令牌进行验证。[MCP 设置指南](/docs/reference/mcp/overview) 涵盖完整的连接流程，包括动态客户端注册和 PKCE。该服务器的身份验证和授权系统与 [REST API](/features/rest-api) 相同，因此任何对 API 有效的令牌也适用于 MCP。

从此处，您的 AI 助手可以调用这 16 个工具中的任何一个。要求它 "创建一个名为 Acme 的组织" 或 "将我的语音语气更新为专业"，代理会将您的意图转化为正确的工具调用。

## 专为代理工作流构建

MCP 不仅仅是便利层。它是将 Glossia 组合到更大的代理管道中的基础。编程助手可以读取您的代码库、检测未本地化的内容、用新术语更新术语表、针对特定本地化调整语音设置，并在一次对话中触发本地化运行。

由于协议是标准化的，您不会被锁定到任何单一客户端。可以在 Claude、Cursor 或您自己的自定义代理之间切换，而无需更改配置行。

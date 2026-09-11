%{
  title: "MCP 服务器",
  summary: "通过模型上下文协议将 AI 智能体和编程助手连接到 Glossia。使用任何其他 MCP 兼容客户端的自然语言来管理语音、术语、组织等。",
  order: 3,
  icon: "cpu",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "自然语言界面",
      description: "通过纯文本与 Glossia 的语言引擎进行交互。AI 智能体调用 MCP 工具来管理语音、术语和组织，无需编写代码。",
      icon: "message-square-text"
    },
    %{
      title: "连接任意智能体",
      description: "支持 Claude、Cursor、Windsurf 以及任何 MCP 兼容客户端。将 Glossia 服务器集成到现有的智能体工作流中，立即开始使用。",
      icon: "puzzle"
    },
    %{
      title: "默认安全",
      description: "每个 MCP 请求均通过 OAuth 2.1 访问令牌进行身份验证，并针对细粒度作用域进行授权。与 REST API 采用相同的安全模型。",
      icon: "shield-check"
    }
  ]
}
---
## 什么是 MCP？

该 [模型上下文协议](https://modelcontextprotocol.io) 是连接 AI 助手与外部工具和数据来源的开放标准。您无需为每个编程助手构建自定义集成，只需开放一个 MCP 服务器，任何兼容的客户端均可使用。

Glossia 的 MCP 服务器赋予代理直接访问平台的语言核心：语音配置、术语管理、组织管理和项目列表。

## 可用工具

MCP 服务器提供了 16 个工具，围绕您日常工作的资源组织。查看 [完整工具参考](/docs/reference/mcp/tools) 有关参数和使用详情。

**账户和组织** -- 列出您的账户、创建和管理组织、邀请成员并控制权限。代理可通过对话配置整个团队结构。

**语音配置** -- 阅读并更新控制 Glossia 生成及修订内容的语音设置。调整语调、正式程度、目标受众和各区域覆盖设置，无需离开编辑器。

**术语管理** -- 保持所有内容的术语一致性。添加、更新和版本化术语条目，以确保代理始终使用正确的术语。

**项目** -- 列出并检查跨组织的项目。

## 工作原理

将你的 MCP 客户端指向 `https://your-glossia-instance/mcp` 并使用 OAuth 访问令牌进行认证。该 [MCP 设置指南](/docs/reference/mcp/overview) 介绍了完整的连接流程，包括动态客户端注册和 PKCE。服务器使用相同的身份验证和授权系统作为 [REST API](/features/rest-api), 因此，适用于 API 的任何令牌也适用于 MCP.

从此之后，您的 AI 助手可以调用任意 16 个工具。要求它“创建一个名为 Acme 的组织”或“更新我的语音语调为专业”，助手会将您的意图转化为正确的工具调用。

## 专为代理工作流构建

MCP 不仅仅是一个便捷层。它是将 Glossia 组合进更大代理管道的基石。您的编码助手可以读取代码库，检测未本地化内容，用新术语更新术语，为特定区域调整语音设置，并在单一对话中触发本地化运行。

由于协议是标准化的，您不会被锁定在任何一个单一客户端。您可以在 Claude、Cursor 或您自己的自定义代理之间切换，而无需更改任何一行配置。
%{
  title: "MCP 服务器",
  summary: "通过模型上下文协议（MCP）将 AI 代理和编程助手连接到 Glossia。通过任何兼容 MCP 的客户端使用自然语言管理语音、术语、组织等内容。",
  order: 3,
  icon: "cpu",
  hero_cta_text: "立即开始",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "自然语言界面",
      description: "通过纯文本与 Glossia 的语言引擎交互。AI 代理调用 MCP 工具管理语音、术语和组织，无需编写代码。",
      icon: "message-square-text"
    },
    %{
      title: "接入任意代理",
      description: "兼容 Claude、Cursor、Windsurf 及任何兼容 MCP 的客户端。将 Glossia 服务器集成到现有的代理工作流中并立即开始使用。",
      icon: "puzzle"
    },
    %{
      title: "默认安全",
      description: "每个 MCP 请求均使用 OAuth 2.1 Bearer 令牌进行身份验证，并针对细粒度权限范围进行授权。与 REST API 采用相同的安全模型。",
      icon: "shield-check"
    }
  ]
}
---
## 什么是 MCP？

该 [模型上下文协议](https://modelcontextprotocol.io) 是连接 AI 助手与外部工具和数据源的开放标准。无需为每个编程助手构建自定义集成，只需暴露一个 MCP 服务器，任何兼容的客户端即可使用。

Glossia 的 MCP 服务器为智能体提供对平台语言核心的直接访问：语音配置、术语管理、组织管理和项目列表。

## 可用工具

该 MCP 服务器暴露了 16 个工具，围绕您日常使用的资源组织。请查看 [完整工具参考](/docs/reference/mcp/tools) 用于参数和用法详情。

**账户与组织** -- 列出您的账户，创建和管理组织，邀请成员并控制访问权限。代理可以通过对话设置整个团队结构。

**语音配置** -- 查看并更新控制 Glossia 生成和修订内容的语音设置。调整语调、正式程度、目标受众及各区域覆盖设置，而无需离开编辑器。

**术语管理** -- 在所有内容中保持术语一致性。添加、更新及版本化术语条目，确保代理始终使用正确的术语。

**项目** -- 列出并检查各个组织中的项目。

## 工作原理

将您的 MCP 客户端指向 `https://your-glossia-instance/mcp` 并通过 OAuth 访问令牌进行认证。该 [MCP 设置指南](/docs/reference/mcp/overview) 涵盖完整的连接流程，包括动态客户端注册和 PKCE。服务器使用相同的认证和授权系统与 [REST API](/features/rest-api)，因此任何适用于 API 的令牌也适用于 MCP。

从此处开始，您的 AI 助手可以调用这 16 个工具中的任意一个。指示它“创建一个名为 Acme 的组织”或“将我的语音语调更新为专业”，代理会将您的意图转换为正确的工具调用。

## 专为代理工作流构建

MCP 不仅仅是一个便捷层。它是将 Glossia 编排进更大代理流水线的基础。编程助手可以读取您的代码库，检测未本地化内容，根据新术语更新术语，为特定区域调整语音设置，并在单次对话中触发本地化运行。

由于协议是标准化的，您无需锁定在任何单一客户端上。在 Claude、Cursor 或您自己的自定义代理之间切换，无需更改一行配置。
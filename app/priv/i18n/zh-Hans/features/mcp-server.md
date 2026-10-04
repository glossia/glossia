%{
  title: "MCP 服务器",
  summary: "通过模型上下文协议 (MCP) 将 AI 代理和编程助手连接到 Glossia。使用任何 MCP 兼容客户端的自然语言管理语音、词汇表、组织等功能。",
  order: 3,
  icon: "cpu",
  hero_cta_text: "立即开始",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "自然语言界面",
      description: "通过纯文本与 Glossia 的语言引擎交互。AI 代理调用 MCP 工具，无需编写代码即可管理语音、词汇表和组织。",
      icon: "message-square-text"
    },
    %{
      title: "接入任意代理",
      description: "支持 Claude、Cursor、Windsurf 及任何 MCP 兼容客户端。将 Glossia 服务器直接放入您的现有代理工作流并立即开始使用。",
      icon: "puzzle"
    },
    %{
      title: "默认安全",
      description:
        "每个 MCP 请求均采用 OAuth 2.1 Bearer 令牌进行身份验证，并基于精细粒度的权限范围进行授权。与 REST API 采用相同的安全模型。",
      icon: "shield-check"
    }
  ]
}
---
## 什么是 MCP？

该 [模型上下文协议](https://modelcontextprotocol.io) 是一项用于连接 AI 助手与外部工具和数据源的开放标准。无需为每个编程助手构建自定义集成，只需暴露一个 MCP 服务器，任何兼容的客户端均可使用它。

Glossia 的 MCP 服务器为智能体直接提供平台的语言核心访问：语音配置、术语库管理、组织管理及项目列表。

## 可用工具

MCP 服务器提供 16 个工具，围绕您日常使用的资源进行组织。查看 [完整的工具参考](/docs/reference/mcp/tools) 有关参数和使用详情。

**账户与组织** -- 列出您的账户，创建和管理组织，邀请成员并控制访问权限。代理可以通过对话设置整个团队结构。

**语音配置** -- 查看并更新控制 Glossia 如何生成和修订内容的语音设置。无需离开编辑器即可调整语调、正式度、目标受众以及本地化覆盖。

**术语表管理** -- 确保所有内容中术语表的一致性。添加、更新并对术语表条目进行版本控制，确保代理始终使用正确的术语。

**项目** -- 列出并检查跨组织的项目。

## 工作原理

将您的 MCP 客户端指向 `https://your-glossia-instance/mcp` ，并使用 OAuth 访问令牌进行身份验证。该 [MCP 设置指南](/docs/reference/mcp/overview) 介绍了完整的连接流程，包括动态客户端注册和 PKCE。该 [REST API](/features/rest-api)，所以适用于 API 的任何令牌也适用于 MCP。

此后，您的 AI 助手可以调用 16 个工具中的任意一个。要求它"创建一个名为 Acme 的组织"或"将我的语音风格更新为专业"，代理会将您的意图转换为正确的工具调用。

## 专为代理工作流构建

MCP 不仅仅是一个便捷层。它是将 Glossia 集成到更大代理流水线的基础。编程助手可以读取您的代码库，检测未本地化的内容，用新术语更新术语表，为特定区域调整语音设置，并触发本地化运行，所有这些只需在单次对话中完成。

由于该协议是标准化的，您不会被锁定在任何单一客户端上。您可以在 Claude、Cursor 或您的自定义代理之间切换，而无需更改一行配置。
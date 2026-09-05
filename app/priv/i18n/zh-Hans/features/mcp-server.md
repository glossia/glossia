%{
  title: "MCP 服务器",
  summary: "通过模型上下文协议 (MCP) 将 AI 代理和编程助手连接到 Glossia。通过任何兼容 MCP 的客户端，使用自然语言来管理语音、术语、组织等内容。",
  order: 3,
  icon: "cpu",
  hero_cta_text: "开始使用",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "自然语言界面",
      description: "通过纯文本与 Glossia 的语言引擎交互。AI 代理调用 MCP 工具来管理语音、术语和组织，无需编写代码。",
      icon: "message-square-text"
    },
    %{
      title: "接入任意代理",
      description: "支持 Claude、Cursor、Windsurf 以及任何兼容 MCP 的客户端。将 Glossia 服务器置入现有的代理工作流中并立即开始使用。",
      icon: "puzzle"
    },
    %{
      title: "默认安全",
      description: "每个 MCP 请求均使用 OAuth 2.1 发件人令牌进行身份验证，且针对细粒度范围进行授权。采用与 REST API 相同的安全模型。",
      icon: "shield-check"
    }
  ]
}
---
## MCP 是什么？

该 [模型上下文协议](https://modelcontextprotocol.io) 是一种连接 AI 助手与外部工具和数据来源的开放标准。无需为每个编程助手构建自定义集成，只需提供单个 MCP 服务器，任何兼容的客户端即可使用它。

Glossia 的 MCP 服务器为智能体提供对平台语言核心（语音配置、术语管理、组织管理和项目列表）的直接访问。

## 可用工具

MCP 服务器提供 16 个工具，围绕您日常工作的资源组织。查看 [完整工具参考](/docs/reference/mcp/tools) 有关参数和使用详情。

**账户和组织** -- 列出您的账户，创建及管理组织，邀请成员并控制访问权限。智能体可通过对话构建整个团队结构。

**语音配置** -- 查看并更新控制 Glossia 生成和修订内容的语音设置。无需离开编辑器，即可调整语气、正式程度、目标受众及各区域覆盖。

**术语管理** -- 确保所有内容中的术语一致性。添加、更新及版本化术语条目，确保智能体始终使用正确的术语。

**项目** -- 列出并检查各组织下的项目。

## 工作原理

将你的 MCP 客户端指向 `https://your-glossia-instance/mcp` 并使用 OAuth 访问令牌进行身份验证。该 [MCP 设置指南](/docs/reference/mcp/overview) 详细说明了完整连接流程，包括动态客户端注册和 PKCE。该 [REST API](/features/rest-api), 因此任何适用于 API 的令牌也适用于 MCP。

从这里开始，您的 AI 助手可以调用 16 种工具中的任意一种。让它执行"创建一个名为 Acme 的组织"或"将我的语音语调更新为专业"，代理会将您的意图转换为正确的工具调用。

## 专为代理工作流而构建

MCP 不仅仅是一个便利层。它是将 Glossia 整合到更大代理管道的基础。编程助手可以读取您的代码库，检测未本地化内容，用新术语更新术语，针对特定区域调整语音设置，并触发本地化运行，所有这些都只需一次对话。

由于协议已标准化，您不会被锁定在特定的客户端上。无需修改一行配置，即可在 Claude、Cursor 或您自己的自定义代理之间切换。
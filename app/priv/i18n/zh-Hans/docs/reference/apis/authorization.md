%{title: "授权", summary: "权限范围、组织角色与资源级访问检查。", category: "参考", subcategory: "API", order: 2}
---

身份验证确立了身份；授权决定该身份可执行的操作。有关登录和令牌流程，请参阅 [身份验证](/docs/reference/apis/authentication)。

## 作用域

作用域控制令牌可以执行什么操作。它们遵循 `object:action` 模式。

| 作用域 | 描述 |
|-------|-------------|
| `admin:read` | 读取平台管理数据（仅限平台管理员） |
| `admin:write` | 更新平台管理数据（仅限平台管理员） |
| `ops:read` | 读取平台运维数据（仅限平台管理员） |
| `user:read` | 读取用户资料信息 |
| `user:write` | 更新用户资料 |
| `account:read` | 列出您可以访问的组织账户 |
| `organization:read` | 读取组织详情（并列出您的组织） |
| `organization:write` | 创建或更新组织 |
| `organization:claim` | 认领组织 |
| `organization:delete` | 删除组织 |
| `organization:admin` | 组织管理操作 |
| `members:read` | 读取组织成员和邀请 |
| `members:write` | 管理组织成员和邀请 |
| `project:read` | 读取项目 |
| `project:write` | 创建或更新项目 |
| `project:admin` | 项目管理操作 |
| `project:delete` | 删除项目 |
| `voice:read` | 读取语音配置 |
| `voice:write` | 创建或更新语音配置 |
| `voice:admin` | 语音管理操作 |
| `glossary:read` | 读取术语表条目 |
| `glossary:write` | 创建或更新术语表条目 |
| `glossary:admin` | 管理术语表设置 |
| `discussion:read` | 读取讨论 |
| `discussion:write` | 创建或更新讨论 |
| `discussion:admin` | 讨论管理操作 |
| `ticket:read` | 读取工单 |
| `ticket:write` | 创建或更新工单 |
| `ticket:admin` | 工单管理操作 |
| `llm_model:read` | 读取账户语言模型 |
| `llm_model:write` | 管理账户语言模型 |
| `translation:read` | 读取项目翻译活动 |
| `translation:write` | 写入翻译数据 |
| `analytics:read` | 读取项目网站分析数据 |
| `toki:read` | 读取您自己的私有项目对话 |
| `toki:write` | 创建私有对话并安排伴侣回复 |
| `api_credentials:read` | 读取访问凭证 |
| `api_credentials:write` | 管理访问凭证 |

身份验证服务器的 [发现元数据](/docs/reference/apis/authentication#discovery-endpoints) 发布可供客户端使用的作用域。可用范围本身并不直接授予访问权限。

## 授权模型

Glossia 针对 [表示状态转移](https://developer.mozilla.org/en-US/docs/Glossary/REST) 应用程序接口及 [模型上下文协议](https://modelcontextprotocol.io) 服务器 **实施两个层次**:

1. **作用域检查**: 访问令牌必须包含所需的 `object:action` 作用域。
2. **资源级策略**: 当前用户必须通过明确的成员权限或基于角色的策略获得特定资源授权。

作用域定义了令牌的 *最大* 能力。资源级检查强制执行特定资源的 *实际* 权限。

### 角色

| 角色 | 描述 |
|------|-------------|
| `self` | 访问自己资源的用户 |
| `organization_member` | 资源所属组织的成员 |
| `organization_admin` | 资源所属组织的管理员 |
| `public_account` | 资源属于公共账户 |

### 成员权限

非管理员组织成员资格可以携带明确的权限范围。新成员初始拥有对账户、组织、项目、语音、术语表、讨论、工单、翻译活动和分析的读取访问权限，以及访问自己私有 Toki 对话的权限。组织管理员可以通过 [成员 → 权限](/docs/how-to/member-permissions) 替换这些范围。使用令牌时，所请求的操作必须包含在成员的允许范围以及令牌的范围内。

私有 Toki 所有权会在组织成员范围覆盖之前进行检查。无论是成员资格授予还是管理员角色，均不允许访问其他用户的对话。项目可见性会单独检查。请参阅 [移动伴侣 API](/docs/reference/apis/mobile) 以获取端点范围限制。

组织管理员保留其管理员角色。现有的没有明确范围权限的成员资格将继续使用下方的基于角色的策略，直到权限被保存。

### 角色权限

下表显示了无明确范围权限成员资格中常见的基于角色的规则。这不是完整策略：集合请求、临时访问和平台管理员拥有额外规则。

| 作用域 | self | organization_member | organization_admin | public_account |
|-------|------|----------------------|--------------------|----------------|
| `user:read` | 是 | 是 | | |
| `user:write` | 是 | | | |
| `account:read` | | 是 | 是 | 是 |
| `organization:read` | | 是 | 是 | |
| `organization:write` | | | 是 | |
| `organization:delete` | | | 是 | |
| `organization:admin` | | | 是 | |
| `members:read` | | 是 | 是 | |
| `members:write` | | | 是 | |
| `project:read` | | 是 | 是 | 是 |
| `project:write` | | | 是 | |
| `project:admin` | | | 是 | |
| `project:delete` | | | 是 | |
| `voice:read` | | 是 | 是 | 是 |
| `voice:write` | | | 是 | |
| `voice:admin` | | | 是 | |
| `glossary:read` | | 是 | 是 | |
| `glossary:write` | | | 是 | |
| `glossary:admin` | | | 是 | |

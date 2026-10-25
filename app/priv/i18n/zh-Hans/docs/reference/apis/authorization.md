%{title: "授权", summary: "权限作用域、组织角色和资源级访问检查。", category: "参考", subcategory: "API", order: 2}
---

身份认证确立身份；授权决定该身份可执行的操作。请参阅 [身份认证](/docs/reference/apis/authentication) 以了解登录和令牌流程。

## 作用域

它们遵循 `object:action` 模式。

| 作用域 | 说明 |
|-------|-------------|
| `admin:read` | 读取平台管理数据（仅限平台管理员） |
| `admin:write` | 更新平台管理数据（仅限平台管理员） |
| `ops:read` | 读取平台操作数据（仅限平台管理员） |
| `user:read` | 读取用户个人资料信息 |
| `user:write` | 更新用户个人资料 |
| `account:read` | 列出您可访问的组织账户 |
| `organization:read` | 读取组织详情（并列出您的组织） |
| `organization:write` | 创建或更新组织 |
| `organization:claim` | 申领组织 |
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
| `toki:read` | 读取您的私有项目对话 |
| `toki:write` | 创建私有对话并排队伴侣回复 |
| `api_credentials:read` | 读取访问凭据 |
| `api_credentials:write` | 管理访问凭据 |

身份认证服务器的 [发现元数据](/docs/reference/apis/authentication#discovery-endpoints) 公布了客户端可用的范围。范围的可用性本身并不授予访问权。

## 授权模型

Glossia 为 [表示状态转移](https://developer.mozilla.org/en-US/docs/Glossary/REST) 应用程序编程接口和 [模型上下文协议](https://modelcontextprotocol.io) 服务器强制执行 **两层**：

1. **作用域检查**：访问令牌必须包含所需的 `object:action` 范围。
2. **资源级策略**：当前用户必须通过显式成员权限或基于角色的策略授权特定资源。

范围代表令牌的 *最大* 能力。资源级检查强制特定资源的 *实际* 权限。

### 角色

| 角色 | 描述 |
|------|-------------|
| `self` | 访问自身资源的用户 |
| `organization_member` | 拥有该资源的组织的成员 |
| `organization_admin` | 拥有该资源的组织的管理员 |
| `public_account` | 该资源属于公共账户 |

### 成员权限

非管理员组织成员资格可以携带显式权限范围。新成员初始拥有对账户、组织、项目、语音、术语表、讨论、工单、翻译活动和分析的读取访问权，以及对其私有 toki 对话的访问权。组织管理员可以通过 [成员 → 权限](/docs/how-to/member-permissions) 替换这些范围。使用令牌时，请求的操作必须包含在成员允许的范围以及令牌的范围中。

私有 toki 的所有权检查在组织成员范围覆盖之前进行。成员资格授予和管理员角色均不允许访问其他用户的对话。项目可见性是单独检查的。有关终结点范围及限制，请参阅 [移动和伴侣 API](/docs/reference/apis/mobile)。

组织管理员保留其管理员角色。在没有显式范围的现有成员资格将继续使用下方的基于角色的策略，直到权限被保存。

### 角色权限

下表显示了没有显式范围的成员资格的常见基于角色的规则。它不是完整的策略：集合请求、临时访问和平台管理员具有额外规则。

| 范围 | 自身 | 组织成员 | 组织管理员 | 公共账户 |
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

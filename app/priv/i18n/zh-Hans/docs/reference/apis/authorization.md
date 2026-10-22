%{title: "授权", summary: "权限范围、组织角色和资源级访问检查。", category: "参考", subcategory: "API", order: 2}
---

身份认证确立身份；授权决定该身份可执行的操作。有关登录和令牌流程，请查阅 [身份认证](/docs/reference/apis/authentication)。

## 作用域

作用域控制令牌可执行的操作。它们遵循 `object:action` 模式。

| 作用域 | 描述 |
|-------|-------------|
| `admin:read` | 读取平台管理数据（仅限平台管理员） |
| `admin:write` | 更新平台管理数据（仅限平台管理员） |
| `ops:read` | 读取平台运营数据（仅限平台管理员） |
| `user:read` | 读取用户个人资料 |
| `user:write` | 更新用户个人资料 |
| `account:read` | 列出您拥有的组织账户 |
| `organization:read` | 读取组织详情（并列出您的组织） |
| `organization:write` | 创建或更新组织 |
| `organization:claim` | 认领组织 |
| `organization:delete` | 删除组织 |
| `organization:admin` | 组织管理操作 |
| `members:read` | 读取组织成员及邀请 |
| `members:write` | 管理组织成员及邀请 |
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
| `translation:write` | 写入翻译数据 |
| `api_credentials:read` | 读取访问凭证 |
| `api_credentials:write` | 管理访问凭证 |

认证服务器的 [发现元数据](/docs/reference/apis/authentication#discovery-endpoints) 公布了可供客户端使用的作用域。作用域的可用本身并不单独授予访问权限。

## 授权模型

Glossia 针对 [表述状态转移](https://developer.mozilla.org/en-US/docs/Glossary/REST) 应用编程接口和 [模型上下文协议](https://modelcontextprotocol.io) 服务器强制执行 **两个层级**：

1. **作用域检查**: 访问令牌必须包含所需的 `object:action` 作用域。
2. **资源级别策略**: 当前用户必须通过明确的成员权限或基于角色的策略获得特定资源的授权。

作用域代表令牌的 *最高* 能力。针对特定资源的资源级别检查强制实施 *实际* 权限。

### 角色

| 角色 | 描述 |
|------|-------------|
| `self` | 访问其自身资源的用户 |
| `organization_member` | 拥有该资源的组织的成员 |
| `organization_admin` | 拥有该资源的组织的管理员 |
| `public_account` | 该资源属于公开账户 |

### 成员权限

非管理员组织成员资格可以携带显式权限作用域。新成员以读取访问权限开始，访问账户、组织、项目、语音配置、术语表、讨论和工单。组织管理员可以通过 [成员 → 权限](/docs/how-to/member-permissions) 替换这些作用域。请求的操作必须包含在成员允许的作用域以及使用该令牌时令牌的作用域中。

组织管理员保留其管理员角色。没有显式作用域的现有成员资格在保存权限之前将继续使用下方的基于角色的策略。

### 角色权限

下表显示了没有显式作用域的成员资格的常见基于角色的规则。这不是完整的策略：收集请求、临时访问和平台管理员拥有额外规则。

| 作用域 | 是 | 是 | 是 | 是 |
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

%{title: "授权", summary: "权限范围、组织角色以及资源级访问检查。", category: "参考", subcategory: "API", order: 2}
---
认证建立身份；授权决定该身份可执行的操作。参见 [认证](/docs/reference/apis/authentication) 用于登录和令牌流程。

## 范围

范围控制令牌可执行的操作。它们遵循 `object:action` 模式。

| 范围 | 描述 |
|-------|-------------|
| `admin:read` | 读取平台管理数据（仅限平台管理员）|
| `admin:write` | 更新平台管理数据（仅限平台管理员）|
| `ops:read` | 读取平台运营数据（仅限平台管理员）|
| `user:read` | 读取用户个人资料信息 |
| `user:write` | 更新个人资料 |
| `account:read` | 列出你可访问的组织账户 |
| `organization:read` | 查看组织详情（并列出你的组织） |
| `organization:write` | 创建或更新组织 |
| `organization:claim` | 认领组织 |
| `organization:delete` | 删除组织 |
| `organization:admin` | 组织管理操作 |
| `members:read` | 查看组织成员和邀请 |
| `members:write` | 管理组织成员和邀请 |
| `project:read` | 查看项目 |
| `project:write` | 创建或更新项目 |
| `project:admin` | 管理项目操作 |
| `project:delete` | 删除项目 |
| `voice:read` | 查看语音配置 |
| `voice:write` | 创建或更新语音配置 |
| `voice:admin` | 管理语音操作 |
| `glossary:read` | 查看术语表条目 |
| `glossary:write` | 创建或更新术语表条目 |
| `glossary:admin` | 管理术语表设置 |
| `discussion:read` | 查看讨论 |
| `discussion:write` | 创建或更新讨论 |
| `discussion:admin` | 管理讨论操作 |
| `ticket:read` | 查看工单 |
| `ticket:write` | 创建或更新工单 |
| `ticket:admin` | 管理工单操作 |
| `llm_model:read` | 读取账户语言模型 |
| `llm_model:write` | 管理账户语言模型 |
| `translation:write` | 写入翻译数据 |
| `api_credentials:read` | 读取访问凭证 |
| `api_credentials:write` | 管理访问凭证 |

认证服务器的 [发现元数据](/docs/reference/apis/authentication#discovery-endpoints) 发布客户端可用的范围。范围可用本身不单独授予访问权限。

## 授权模型

Glossia 强制执行 **两层** 针对 [表示性状态转移](https://developer.mozilla.org/en-US/docs/Glossary/REST) 应用程序编程接口 和 [模型上下文协议](https://modelcontextprotocol.io) 服务器：

1. **作用域检查**访问令牌必须包含必需的 `object:action` 作用域。
2. **资源级别策略**：当前用户必须通过显式成员权限或基于角色的策略对特定资源获得授权。

作用域代表 *最大* 令牌的能力。资源级别检查强制执行 *实际* 特定资源的权限。

### 角色

| 角色 | 描述 |
|------|-------------|
| `self` | 访问其自有资源的用户 |
| `organization_member` | 该资源所属组织的成员 |
| `organization_admin` | 该资源所属组织的管理员 |
| `public_account` | 该资源属于公共账户 |

### 成员权限

非管理员组织成员身份具有显式权限范围。新成员默认拥有对账户、组织、项目、语音、术语表、讨论和工单的读取权限。组织管理员可通过 [成员 → 权限](/docs/how-to/member-permissions). 请求的操作必须包含在成员的允许权限范围内以及使用令牌时的令牌范围内。

组织管理员保留其管理员角色。没有显式权限范围的现有成员关系将沿用下方的基于角色的策略，直至权限保存。

### 角色权限

下表显示了无显式权限范围的成员关系常用的基于角色的规则。这不是完整策略：收集请求、临时访问和平台管理员拥有额外规则。

| 范围 | self | organization\_member | organization\_admin | public\_account |
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
%{
  title: "配置组织登录",
  summary: "连接 Google Workspace 或 Okta，验证您的域名，并管理成员权限。",
  category: "教程",
  section: "platform",
  order: 8
}
---

## 连接您的身份提供商

组织管理员可以在 **设置 → 认证** 中连接工作身份提供商。

1. 选择 **Google Workspace** 或 **Okta**，并输入团队的工作邮件域名。
2. 对于 Okta，使用 [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/) 创建 Web 应用。输入其发布端点、客户端标识符和客户端密钥。Glossia 支持标准的 Okta 组织发布端点和 `/oauth2/default` 授权服务器。密钥在静态状态下加密。编辑时留空密钥将保留已保存的值。
3. 对于 Okta，将 Glossia 中显示的重新定向地址注册到您的身份提供商。对于 Google Workspace，Glossia 管理 Google 连接；您无需创建 Google 应用或注册回调地址。
4. 保存设置。通过您的域提供商添加显示的 DNS TXT 记录，然后选择 **验证域名**。更改邮件域名将创建新的验证令牌，并在再次验证前禁用组织登录。
5. 团队成员在登录页输入其工作邮件并选择 **使用您的组织继续**。Google Workspace 成员也可以使用 **使用 Google 登录**。

## 设置 Google Workspace

Glossia 管理 Google 应用凭据。您无需在 Google Cloud 创建 OAuth 应用、在 Google Admin 添加自定义 SAML 应用，或注册重新定向地址。对于现有的 Google Workspace 域名，设置操作在 Glossia 和您的 DNS 提供商处进行：

1. 在 **设置 → 认证** 中，选择 **Google Workspace**，输入工作邮件域名，并选择 **保存认证设置**。
2. 在托管您的 DNS 的提供商处打开域名 DNS 设置，不一定在 Google Workspace 处。添加 **验证域名所有权** 中显示的记录：

   | 字段 | 值 |
   | --- | --- |
   | 类型 | `TXT` |
   | 名称 / 主机 | Glossia 中显示的 **记录名称**，例如 `_glossia-verification.example.com` |
   | 值 / 内容 | Glossia 中显示的 **记录值**，以 `glossia-domain-verification=` |

   某些 DNS 提供商会自动附加您的域名。在这种情况下，仅输入 `_glossia-verification` 作为主机，以免域名包含两次。验证后保持该记录在原位。
3. 返回 Glossia 并选择 **验证域名**。如果验证失败，检查名称和值，并等待 DNS 更改传播后再试。
4. 请团队成员在登录页输入工作邮件并选择 **使用您的组织继续**，或使用 **使用 Google 登录**。

Glossia 检查 Google 的已验证邮件和 [托管域声明](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload)；带有相同邮件后缀的个人 Google 账号不符合条件。

### 如果 Google 阻止登录

通常 Google 端无需配置。如果您的组织限制第三方应用访问，Google Workspace 管理员可能需要批准 Glossia：

1. 使用管理员账号登录 [Google 管理控制台](https://admin.google.com/)。
2. 进入 **安全 → 访问和数据控制 → API 控制 → 管理第三方应用访问**。
3. 在已访问应用列表中找到 Glossia。如果未列出，请使用 **配置新应用** 来按应用名称或 OAuth 客户端 ID 搜索它。OAuth 客户端 ID 属于 Glossia 共用的 Google 连接，而非您需要创建的应用。
4. 审查请求的登录权限，并根据您组织的策略允许相关用户访问。查看 Google 的 [控制哪些第三方和内部应用访问 Google Workspace 数据](https://support.google.com/a/answer/7281227) 指南以了解访问级别和管理员要求。
5. 在策略生效后退试使用工作账号登录。

## 管理注册和权限

具有完全匹配的工作邮件域名的已验证提供商身份会自动加入组织。对于首次连接 Okta 的现有 Glossia 账号，在开始组织登录之前，请先使用现有方法登录。这安全地链接提供商，而不允许 Okta 管理员接管其他 Glossia 账号。通过其他提供商的公开注册仍使用兴趣表。禁用该提供商将停止组织登录，但不会删除现有成员身份。

新成员获得对账号、组织、项目、语音、术语表、讨论和工单的基本读取权限。加入后，请按照 [管理成员权限](/docs/how-to/member-permissions) 授予额外访问权限。

## 访问安全保障

域名所有权验证持续 30 天，并每天自动检查。请保留验证记录。如果记录消失，一旦最后一次成功验证过期，登录即会停止；请恢复记录并重新从认证设置中验证。更改提供商或禁用组织登录将清除验证并移除属于上一个提供商的凭据。未验证的声明不会保留域名。

对于现有账号，请先使用现有方法登录，然后访问 `/auth/login` 并开始工作邮件登录以连接工作身份。Google 也可以使用具有相同提供商主题已链接的 Google 身份。仅匹配电子邮件地址永远不会连接现有账号。

移除成员将阻止自动重新注册。管理员必须显式再次添加或邀请他们以恢复访问权限，即使其工作身份仍然活跃。

成员邀请管理、访问凭据、语言模型编辑和组织删除仍为管理员职责。这些权限不能通过成员范围复选框进行委托。认证配置、域名验证和范围变更会发出审计事件。

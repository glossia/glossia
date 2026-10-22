%{
  title: "配置组织登录",
  summary: "连接 Google Workspace 或 Okta，验证您的域名，并管理成员权限。",
  category: "教程",
  section: "platform",
  order: 8
}
---

## 连接你的身份提供商

组织管理员可以在 **设置 → 身份验证** 中连接到工作身份提供商。

1. 选择 **Google Workspace** 或 **Okta**，并输入团队的工作电子邮箱域。
2. 对于 Okta，使用 [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/) 创建 Web 应用程序。输入其发行商、客户端标识符和客户端密钥。Glossia 支持标准的 Okta 组织发行商和 `/oauth2/default` 授权服务器。密钥在静息状态下加密。编辑时将密钥留空可保留已保存的值。
3. 对于 Okta，在身份提供商处注册 Glossia 中显示的回调地址。对于 Google Workspace，Glossia 管理 Google 连接；您无需创建 Google 应用程序或注册回调地址。
4. 保存设置。通过您的域提供商添加显示的 DNS TXT 记录，然后选择 **验证域名**。更改电子邮件域会创建新的验证令牌，并禁用组织登录，直到再次验证。
5. 团队成员在登录页面输入其工作电子邮件并选择 **使用您的组织继续**。Google Workspace 成员也可以使用 **使用 Google 登录**。

## 设置 Google Workspace

Glossia 管理 Google 应用程序凭据。您无需在 Google Cloud 中创建 OAuth 应用程序，在 Google Admin 中添加自定义 SAML 应用程序，或注册回调地址。对于现有的 Google Workspace 域，设置会在 Glossia 和您的 DNS 提供商处进行：

1. 在 **设置 → 身份验证** 中，选择 **Google Workspace**，输入您的工作电子邮件域，并选择 **保存身份验证设置**。
2. 在为您提供 DNS 托管的服务提供商处打开您的域名 DNS 设置，而不仅仅是 Google Workspace。添加 **验证域名所有权** 中显示的记录：

   | 字段 | 值 |
   | --- | --- |
   | 类型 | `TXT` |
   | 名称 / 主机 | Glossia 中显示的 **记录名称**，例如 `_glossia-verification.example.com` |
   | 值 / 内容 | Glossia 中显示的 **记录值**，以 `glossia-domain-verification=` 开头 |

   某些 DNS 提供商会自动附加您的域名。在这种情况下，仅输入 `_glossia-verification` 作为主机，以确保域名不会重复包含。验证后保留该记录。
3. 返回 Glossia 并选择 **验证域名**。如果验证失败，请检查名称和值，并允许 DNS 变更生效后再试。
4. 请团队成员在登录页面输入其工作电子邮件并选择 **使用您的组织继续**，或使用 **使用 Google 登录**。

Glossia 会检查 Google 的已验证电子邮件和 [托管域声明](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload)；使用相同电子邮件后缀的个人 Google 账户不符合要求。

### 如果 Google 阻止登录

通常不需要 Google 方面的配置。如果您的组织限制第三方应用程序访问，Google Workspace 管理员可能需要批准 Glossia：

1. 使用管理员账户登录 [Google Admin console](https://admin.google.com/)。
2. 进入 **安全 → 访问和数据控制 → API 控制 → 管理第三方应用程序访问**。
3. 在已访问的应用列表中查找 Glossia。如果未列出，请使用 **配置新应用**，根据应用名称或 OAuth 客户端 ID 进行搜索。OAuth 客户端 ID 属于 Glossia 共享的 Google 连接，而不是您需要创建的应用。
4. 审查请求的登录权限，并根据您组织的策略为相关用户允许访问。有关访问级别和管理员要求的信息，请参阅 Google 的 [控制哪些第三方和内部应用可访问 Google Workspace 数据](https://support.google.com/a/answer/7281227) 指南。
5. 策略生效后，使用工作账户重试登录。

## 管理注册和权限

具有精确匹配工作电子邮件域的验证提供商身份会自动加入组织。对于现有 Glossia 账户首次连接 Okta，请在开始组织登录之前使用现有方法登录。这安全地链接了提供商，而不会允许 Okta 管理员接管另一个 Glossia 账户。通过其他提供商的公开注册将继续使用兴趣表。禁用提供者会停止组织登录，而不会删除现有成员关系。

新成员获得账户、组织、项目、语音、术语表、讨论和工单的读访问权限。请遵循 [管理成员权限](/docs/how-to/member-permissions) 以在他们加入后授予额外访问权限。

## 访问安全保障

域名所有权验证持续 30 天，每天自动检查。保留验证记录。如果记录消失，一旦最后一次成功验证过期，登录将停止；请恢复记录并从身份验证设置中再次验证。更改提供商或禁用组织登录会清除验证并删除属于先前提供商的凭据。未经验证的声明不会保留域名。

对于现有账户，首先使用现有方法登录，然后访问 `/auth/login` 并开始工作电子邮件登录以连接工作身份。Google 也可以使用具有相同提供商主体的已关联 Google 身份。仅匹配电子邮件地址绝不会连接现有账户。

移除成员将阻止自动重新注册。即使其工作身份仍然有效，管理员也必须明确添加或邀请他们以恢复访问。

成员邀请管理、访问凭据、语言模型编辑和组织删除仍然是管理员职责。无法通过成员范围复选框委托这些权限。身份验证配置、域名验证和范围变更会产生审计事件。

%{
  title: "配置组织登录",
  summary: "连接 Google Workspace 或 Okta，验证您的域名，并管理成员权限。",
  category: "教程",
  section: "platform",
  order: 8
}
---
## 连接您的身份提供商

组织管理员可以在中连接工作身份提供商 **设置 → 认证**.

1. 选择 **Google Workspace** 或 **Okta** 并输入团队的工作邮箱域名。
2. 对于 Okta，请创建 Web 应用程序使用 [OpenID Connect](https://developer.okta.com/docs/guides/implement-grant-type/authcode/main/)。输入其颁发者、客户端标识及客户端密钥。Glossia 支持标准的 Okta 组织颁发者以及 `/oauth2/default` 授权服务器。密钥在存储时会被加密。编辑时留空该密钥将保留已保存的值。
3. 对于 Okta，请将 Glossia 中显示的回调地址注册到您的身份提供商。对于 Google Workspace，Glossia 管理 Google 连接；您无需创建 Google 应用程序或注册回调地址。
4. 保存设置。通过您的域名提供商添加显示的 DNS TXT 记录，然后选择 **验证域名**。更改电子邮件域名将创建新的验证令牌，并在再次验证前禁用组织登录。
5. ，团队成员在登录页面输入工作邮箱并选择 **使用您的组织继续**。Google Workspace 成员也可以使用 **使用 Google 登录**。

## 设置 Google Workspace

Glossia 管理 Google 应用凭据。您无需在 Google Cloud 创建 OAuth 应用程序、在 Google Admin 添加自定义 SAML 应用程序或注册重定向地址。对于现有的 Google Workspace 域名，设置需在 Glossia 和您的 DNS 服务商处进行：

1. 在 **设置 → 认证**, 选择 **Google Workspace**, 输入您的工作邮箱域名，并选择 **保存认证设置**.

2. 在托管您域名的 DNS 提供商处打开 DNS 设置，不一定是 Google Workspace。添加显示在的记录 **验证域名所有权**:
   
   | 字段 | 值 |
   | --- | --- |
   | 类型 | `TXT` |
   | 名称 / 主机 | 该 **记录名称** 在 Glossia 中显示，例如 `_glossia-verification.example.com` |
   | 值 / 内容 | 该 **记录值** 在 Glossia 中显示，以 `glossia-domain-verification=` |
   
   某些 DNS 提供商会自动附加您的域名。在此情况下，仅输入 `_glossia-verification` 作为主机，以避免域名重复出现。验证后保持记录不变。

3. 返回 Glossia 并选择 **验证域名**。如果验证失败，请检查名称和值，并等待 DNS 更改生效后再试。

4. 请团队成员在登录页面输入其工作邮箱并选择 **使用您的组织继续**，或 **使用 Google 登录**.

Glossia 检查 Google 已验证的电子邮件和 [托管域名声明](https://developers.google.com/identity/openid-connect/openid-connect#an-id-tokens-payload)；具有相同电子邮件后缀的个人 Google 账户不符合资格。

### 如果 Google 阻止登录

通常不需要 Google 端配置。如果您的组织限制第三方应用程序访问，Google Workspace 管理员可能需要批准 Glossia：

1. 登录到 [Google 管理控制台](https://admin.google.com/) 使用管理员账户。
2. 前往 **安全 → 访问及数据控制 → API 控制 → 管理第三方应用访问**。
3. 在已访问应用列表中查找 Glossia。如果未列出，请使用 **配置新应用** 按应用名称或 OAuth 客户端 ID 搜索它。该 OAuth 客户端 ID 属于 Glossia 共享的 Google 连接，而非您需要创建的应用。
4. 检查所需的登录权限，并根据贵组织的策略允许相关用户访问。查看 Google 的 [控制哪些第三方和内部应用访问 Google Workspace 数据](https://support.google.com/a/answer/7281227) 访问级别和管理员要求的指南。
5. 策略生效后，请使用工作账户重试登录。

## 管理注册与权限

具有精确匹配的电子邮件域名的经核验身份提供商会自动加入组织。对于首次连接 Okta 的现有 Glossia 账户，请在开始组织登录之前使用现有方法登录。该操作会安全地链接身份提供商，而不会允许 Okta 管理员接管其他 Glossia 账户。通过其他身份提供商进行的公共注册将继续使用兴趣表单。禁用身份提供商将停止组织登录，而不会删除现有的成员身份。

新成员获得对账户、组织、项目、语音、术语表、讨论和工单的基本读取访问权限。请遵循 [管理成员权限](/docs/how-to/member-permissions)，以便在他们加入后授予额外访问权限。

## 访问安全保障

域名所有权验证期持续 30 天，并且每天都会自动检查。请保留验证记录。如果记录丢失，一旦最后一次成功验证过期，登录将停止；请从身份验证设置中恢复记录并重新验证。更改身份提供商或禁用组织登录会清除验证并移除属于前一个身份提供商的凭证。未经验证的声明不会保留域名。

对于现有账户，请首先使用现有方法登录，然后访问 `/auth/login` 并启动工作电子邮件登录以连接工作身份。Google 也可以利用已关联的具有相同提供商主体的 Google 身份。仅匹配电子邮件地址无法连接现有账户。

移除成员会阻止自动重新注册。即使其工作身份仍然处于活动状态，管理员也必须显式地再次添加或邀请他们以恢复访问权限。

成员邀请管理、访问凭证、语言模型编辑和组织删除仍属于管理员职责范围。这些权限无法通过成员范围复选框进行委托。身份验证配置、域名验证和范围变更会生成审计事件。
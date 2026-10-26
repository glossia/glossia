%{
  title: "原生推送通知",
  summary: "提供商配置、同意设备注册、投递策略和原生载荷。",
  category: "参考",
  section: "platform",
  order: 30
}
---

## 传输和安全凭证

Glossia 直接向 iOS 发送数据至 APNs，向 Android 发送数据至 FCM HTTP v1。PostgreSQL 存储注册信息；Oban 队列管理投递。不需要消息服务或 Firebase iOS SDK。提供方的接受并不代表交付或读取回执。模糊的网络故障可能导致重复警报。

提供者密钥应仅存储在服务器的现有密钥管理系统中。切勿将 APNs 私钥或 Firebase 服务账号 JSON 放入移动构建、仓库文件、日志或与客户端可见的配置中。Firebase 的公开 Android 应用标识符不是服务账号凭据。

| 环境变量 | 含义 |
| --- | --- |
| `GLOSSIA_APNS_TEAM_ID` | 10 位 Apple 团队 ID。 |
| `GLOSSIA_APNS_KEY_ID` | 10 位 Apple 签名密钥 ID。 |
| `GLOSSIA_APNS_PRIVATE_KEY` | PEM 编码的私用 P-256 签名密钥，保留换行符。 |
| `GLOSSIA_APNS_TOPIC` | 已签名 iOS 应用的精确包标识符。客户端无法选择它。 |
| `GLOSSIA_APNS_ENVIRONMENT` | `production`（默认）、`sandbox`, 或明确指定 `both` 以支持两者。 |
| `GLOSSIA_FCM_SERVICE_ACCOUNT_JSON` | 包含 `type`, `project_id`, `client_email` 以及 RSA `private_key` 的 Android Firebase 服务账号 JSON。 |

缺少 APNs 凭据仅禁用 iOS。缺少 FCM 凭据仅禁用 Android。部分或损坏的配置提供者会在配置解析时产生不含密钥的错误。APNs 环境在注册和交付时进行检查；应基于已签名的配置文件派生，而非构建模式假设。APNs 使用专用的 HTTP/2-only Finch 池和 ES256 身份验证。FCM 在 Google 的固定 OAuth 端点交换 RS256 服务账号断言，然后使用其固定的 HTTP v1 端点。已禁用重定向和 HTTP 客户端重试。

## 注册 API

所有路由都需要由原生应用每个安装实例动态注册的公共 PKCE 客户端发出的 Bearer OAuth 访问令牌。其唯一的重定向 URI 必须是 `glossia://oauth/callback`；刷新和撤销必须是公开的，没有客户端密钥身份验证方法。遗留的共享 Expo 客户端、账号令牌、浏览器会话和其他 OAuth 客户端不是安装标识符，无法注册设备。这检查客户端形状，而非设备验证。

`PUT /api/me/push-devices/:installation_id` 仅接受：

```json
{"platform":"ios","token":"<OS device token>","environment":"production"}
```

- `installation_id`: 客户端生成的 UUID。它也是返回和投递的 `registration_id`。
- `platform`: `ios` 或 `android`。
- `environment`: 对 iOS 为 `sandbox` 或 `production`；对 Android 仅为 `production`。
- iOS 令牌：32–512 个十六进制字符，偶数长度，归一化为小写。
- Android 令牌：16–4096 个可打印的非空格 ASCII 字符。
- 成功的 PUT：`{"registered":true,"registration_id":"<installation UUID>"}`。
- 未知字段（包括所有者选择器、主题、主机和提供者 URL）将被拒绝。

`DELETE /api/me/push-devices/:installation_id` 返回 `{"deleted":true}` 且可幂等。未知 ID 变为墓碑，因此延迟 PUT 无法在注销后使安装恢复。不同用户的无关安装永远不会被更改。相同的原生 OAuth 客户端可能在离线注销恢复期间淘汰其前用户的安装，但所有权永不转移。在 `409 installation_retired` 后旋转到新的安装 UUID。

`GET /api/me/push-devices/capabilities` 根据配置的提供者返回 `{"ios":true,"android":false}`；它具有相同的身份验证要求。真正的 iOS 能力不会覆盖 APNs 环境限制。

响应为 `no-store`。变更限制每小时每用户 120 次请求，外加 API 限制。缺失/无效 Bearer 认证返回 401；非原生凭据返回 403；无效设备数据返回 400；已退役/冲突的安装返回 409；不可用的提供者返回 503。提供程序禁用时清理仍可用。

## 投递意图

内部调用方在源事务提交后使用其固定 API：

```elixir
Glossia.Push.notify_user(user_id, "toki_completed", %{
  conversation_id: conversation.id,
  message_id: completed_user_message.id
})

Glossia.Push.notify_user(user_id, "linguistic_input_needed", %{
  translation_session_id: session.id,
  review_id: review.id
})
```

种类也可以是相应的原子。返回为 `{:ok, queued_count}` 或 `{:error, :invalid_notification}`。没有任意受送方的公共发送 API、自定义通知文本、推理重试或隐式选择加入。

`toki_completed` 要求精确的已完成 **用户** 消息及其已完成的助手回复。在私人对话中，接收者必须拥有历史记录；在共享目标对话中，他们必须仍然是合格的受邀流利参与者，并且目标必须处于打开状态。它检查当前的 Toki/项目访问，对于源链接对话，检查当前的翻译读取访问和源存在性。不同的已完成消息或助手消息 ID 不是替代方案。

`linguistic_input_needed` 需要指定翻译会话上已标识的打开的目标和合格的受邀流利参与者。仅会话源出于兼容性目的仍被接受并解决合格的目标。其他会话上的审查无效。所有匹配的授权团队成员加入同一个 Toki 对话；投递独立重新检查当前的流利度、Toki/翻译/项目访问和成员资格。

每个用户最多有十个活动注册。令牌使用现有的 Cloak 保险库加密，并按 SHA-256 摘要索引。令牌移动淘汰旧注册，提供者无效化在清除任何内容之前比较尝试的摘要/环境。APNs 上次无效时间戳不淘汰该时间戳之后刷新的注册。

投递作业仅包含 ID、种类、源 ID 和过期时间。每次尝试都会重新检查注册、所有者、当前持久化的原生 OAuth 刷新授权和范围、源、成员资格和过期时间。获取提供者凭据后、传输前立即再次检查。访问令牌过期本身不会结束仍然有效的刷新会话。撤销、刷新过期、缺失的源访问、注销或已解决的审查会取消投递。

两种类型均在一小时后过期。存在最多五个提供者尝试，包括提供者背压暂停。仅在通知生命周期内遵守 Retry-After。不会将提供者响应体或令牌作为作业错误返回。在前台刷新注册；60 天内未刷新注册的将被淘汰。每小时修剪工人扫描有界循环批次的 1,000 行并移除陈旧或结束会话的令牌。墓碑仅永久保留安装/客户端 ID、平台/环境以及生命周期时间戳以阻挡延迟请求；被淘汰的行不包含用户、令牌或摘要。账户删除切断了用户引用，立即阻止所有投递，修剪工人清除保留的令牌。

提供者凭据使用有界、感知过期时间的 Cachex 缓存。密钥轮换改变缓存身份。APNs JWT 重用了 50 分钟；FCM 凭据有效期比提供者过期时间提前五分钟（最多 50 分钟）。失败不缓存。

## 有效负载版本 1

APNs 包含通用警报 **Glossia / 您在 Glossia 有更新。** FCM 发送仅含数据的消息，包含相同的 `title` 和 `body`，用于本地渲染。两者均不包含私密提示、回复、问题、源代码摘录或项目标题。路由字段为字符串：

```json
{"v":"1","url":"glossia://navigate/org/project/toki/CONVERSATION_UUID?server=https%3A%2F%2Fglossia.ai","registration_id":"INSTALLATION_UUID"}
```

两种通知类型均打开 `/org/project/toki/CONVERSATION_UUID`；语言帮助请求打开其共享目标线程。`server` 是配置的 Phoenix 端点的 HTTPS 源，绝不包括请求头或客户端输入。HTTP 仅端点配置在投递时直接关闭。原生客户端必须拒绝未知版本、不匹配的源/注册和未识别的路由；点击绝不更改服务器或执行变更。获取的目标仍需通过正常的 API 授权。

## 运行时集成

父应用在 Oban 之前启动 `Glossia.Push.Supervisor`，凭据缓存和专用的 APNs Finch 池。运行时配置调用 `Glossia.Push.Config.parse!(System.get_env())`。Oban 的 `push` 队列并发度为五，每小时运行 `Glossia.Push.Prune`。三条注册路由在现有的基于 Bearer 认证的 API 流程中运行。

请求日志清除设备令牌。该端点使用 Phoenix 的参数过滤器扩展了 Sentry 的默认主体清洗器，保留其现有保护：

```elixir
config :phoenix, :filter_parameters, ["password", "passwd", "secret", "token"]

# Endpoint request-body scrubber
plug Sentry.PlugContext, body_scrubber: {__MODULE__, :scrub_request_body}
def scrub_request_body(conn) do
  conn
  |> Sentry.PlugContext.default_body_scrubber()
  |> Phoenix.Logger.filter_values()
end

# Defense in depth: no Phoenix parameter logging for enrollment
put "/me/push-devices/:installation_id", PushDeviceController, :update, log: false
```

不要在自定义遥测或异常报告中保留原始推送请求体。

只有父级 Web/Worker 进程需要推送管理和队列。翻译运行器 Pod 可以在无凭据、APNs 池或新消息服务的情况下入队 ID。通过正常的发布流程进行迁移。确保导出的账户数据不包含提供者令牌。不要将墓碑删除作为常规保留清理。

物理设备检查仍然必要：配置的已签署 iOS/Android 构建、允许的/拒绝的权限、前台/后台/终止状态投递、冷启动点击、提供者令牌轮换、过期凭据、离线注销清理和账户切换。模拟的提供者测试无法建立实时投递。原生构建包括通知生命周期支持和 Android Firebase 依赖项，但此代码不提供凭据、共享基础设施、已签署的配置配置文件或 Firebase 应用标识符。

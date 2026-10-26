%{
  title: "移动端和配套 API",
  summary: "原生外观、个人资料、翻译活动、分析数据和私密的 Toki 对话。",
  category: "参考",
  subcategory: "接口",
  order: 4
}
---

除了公开的本机外观目录外，所有端点都需要 Bearer 令牌。完整的 schema 在 [OpenAPI 规范](/api/openapi.json) 中描述。通过现有的 [OAuth PKCE 流程](/docs/reference/apis/authentication) 获取令牌。切勿在客户端中嵌入推理提供商密钥。

## 授权

| 端点 | 令牌范围 |
|---|---|
| `GET /api/native/themes` | 无（公开外观元数据） |
| `GET /api/me` | `user:read` |
| `GET /api/:handle/projects/:project/translations` | `translation:read` |
| `GET /api/:handle/projects/:project/translations/:id` | `translation:read` |
| `GET /api/:handle/projects/:project/analytics` | `analytics:read` |
| `GET /api/:handle/projects/:project/toki/conversations` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations` | `toki:write` |
| `GET /api/:handle/projects/:project/toki/conversations/:id` | `toki:read` |
| `POST /api/:handle/projects/:project/toki/conversations/:id/messages` | `toki:write` |

令牌范围是上限，而非授予。每个项目端点还会检查用户的“项目读取”权限。第二个 `project:read` **令牌** 范围并非必需，但具有明确权限的组织成员资格必须允许项目读取和请求的能力。新成员资格包括这些移动能力；现有显式成员资格不会自动扩展。

个人项目遵循现有的个人组织成员资格规则。账户可见性控制公开项目读取；拥有所需范围的已认证外部用户可以读取公开项目的翻译活动和分析。Toki 写入需要账户成员资格，因此仅有公开可见性不会产生账户的推理积分。Toki 对话在其项目内对创建用户保持私密，即使是在公开账户上。组织和平台管理员无法读取其他用户的对话。知道对话 UUID 并不能授予访问权限。

## 本机外观

选择的 Glossia 服务器通过 `GET /api/native/themes` 返回实例级外观元数据，无需身份验证或用户/项目数据。响应中包含 `Cache-Control: public, max-age=300`。这不会更改任何项目端点的授权。

响应包含四个必需字段：

| 字段 | 值 |
|---|---|
| `schema_version` | 整数 `1` |
| `revision` | 非空内容修订版，最多 128 个字符 |
| `default_theme_id` | `"glossia"` |
| `themes` | 包含默认 Glossia 主题的数组 |

默认主题包含 `id: "glossia"`、`name: "Glossia"`、一个非空 `description`、`typography: "standard"`、`button_radius: 8`、`card_radius: 12` 以及 `light` 和 `dark` 调色板。半径为数值逻辑像素。每个调色板包含下方所有九个字段，表示为不透明 `#RRGGBB` 颜色：

| 调色板字段 | 亮色 | 深色 |
|---|---|---|
| `background` | `#FAF8F5` | `#1C1917` |
| `surface` | `#FFFFFF` | `#2A2621` |
| `subtle` | `#F2EFE9` | `#2A2621` |
| `text` | `#1C1917` | `#FAF8F5` |
| `secondary_text` | `#5C564E` | `#D1CDC5` |
| `border` | `#E4E0D9` | `#3D3833` |
| `accent` | `#6D3CC4` | `#D0BCFF` |
| `on_accent` | `#FFFFFF` | `#381E72` |
| `tint` | `#6D3CC4` | `#D0BCFF` |

目录从 `app/priv/static/assets/styles.css` 中的规范 `:root` 颜色和半径令牌编译。深色调色板仅使用原生语义令牌，不会改变 Web 渲染。在令牌更改后重新构建会更新目录及其确定性的修订版。修订版涵盖目录内容，而非不相关的样式表编辑。不包含用户特定偏好或运行时主题配置。

## 配置文件

`GET /api/me` 仅返回已认证用户的配置文件：

```json
{
  "user": {
    "id": "30c92fe9-4477-4ba6-ae0a-0d874f9ff650",
    "name": "Alex Chen",
    "email": "alex@example.com",
    "handle": "alex"
  },
  "server_version": "0.1.0"
}
```

`name` 可以是 `null`。句柄属于用户的个人账户，而非选定组织。`server_version` 是正在运行的应用程序版本。

## 分页

翻译和对话列表接受 `page` (默认 `1`，范围 `1–10000`) 和 `page_size` (默认 `20`，范围 `1–50`)。无效值返回 `400`，而非静默调整。元数据使用与其他 Glossia API 列表相同的形状：

```json
{
  "total_count": 23,
  "total_pages": 2,
  "current_page": 1,
  "page_size": 20,
  "has_next_page?": true,
  "has_previous_page?": false
}
```

列表反映当前状态，而非冻结快照。对话排序为最近更新优先，以 UUID 作为确定性平局判定器。

## 翻译活动

通过 `GET /api/:handle/projects/:project/translations?page=1` 返回：

```json
{
  "sessions": [{
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "completed",
    "commit_message": "Update installation guide",
    "source_language": "en",
    "target_languages": ["es", "ja"],
    "translated_content_count": 8,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": "Translated eight documents."
  }],
  "meta": {"total_count": 1, "total_pages": 1, "current_page": 1, "page_size": 20, "has_next_page?": false, "has_previous_page?": false}
}
```

状态为 `pending`、`running`、`completed`、`failed` 或 `cancelled`。提交消息、源语言和摘要在等待工作时或不可用时可设置为 `null`。结果按最新顺序排列，且限制在指定项目。

`GET /api/:handle/projects/:project/translations/:id` 返回 `{session: {...}, progress: {...}}`。`session` 包含完整的列表会话字段，外加可选的 `commit_sha`，保持不变。`progress` 使用与 Web 仪表板相同的 Elixir 进度减函数，从持久事件重新构建。这指向已指定项目中的会话和账户的直接精确 UUID 查找，与分页或会话年龄无关。格式错误、缺失和外部项目 ID 将返回 `404` 并包含 `error: "not_found"`；身份验证和项目授权首先运行 (`401`/`403`)。打开此资源永远不会创建对话、发送消息或启动推理。它提供 **会话摘要级溯源** 和每文件进度，不提供翻译片段文本或翻译输出审查。

### 本机实时进度

在 `/native/socket/websocket?vsn=2.0.0` 处打开持久的 Phoenix WebSocket（在 HTTPS 服务器上为 `wss`）。长轮询已禁用。仅通过 WebSocket 子协议标头发送访问令牌，切勿通过查询参数：

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

服务器协商 `phoenix`。加入主题 `translation:<session UUID>` 时附带 `{"organization":"account-handle","project":"project-handle"}`。组织值与 HTTP API 使用的账户句柄相同，包括个人账户。加入回复和每个 `snapshot` 事件携带与 HTTP 详情相同的完整投影：

```json
{
  "session": {
    "id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf",
    "status": "running",
    "commit_message": "Update installation guide",
    "commit_sha": "abc123",
    "source_language": "en",
    "target_languages": ["es"],
    "translated_content_count": 0,
    "inserted_at": "2026-10-25T10:00:00Z",
    "summary": null
  },
  "progress": {
    "seq": 3,
    "summary": {
      "total": 2, "checked": 2, "needs_translation": 2, "assessed?": true,
      "skipped": 0, "done": 0, "failed": 0, "cancelled": 0, "running": 1, "queued": 1,
      "glossary": {"applied_ids": [], "shadowed_ids": [], "files_with_applied": 0, "files_with_shadowed": 0}
    },
    "items": [
      {"index": 0, "output_path": "es/guide.md", "locale": "es", "status": "running", "turns": 1, "file_ref": null},
      {"index": 1, "output_path": "es/faq.md", "locale": "es", "status": "queued", "turns": 0, "file_ref": null}
    ],
    "omitted_items": 0
  }
}
```

`seq` 是持久进度序列，**不是** 唯一快照版本。会话状态/发布更改和实时模型调用次数可能产生与同一序列相关的新快照；即使 `seq` 不变，也替换之前的投影。每文件状态为 `queued`、`running`、`done`、`failed` 和 `cancelled`。在已知之前，路径、区域设置和文件引用可以为 `null`。未触及的会话具有序列零、空项目项和零计数。摘要涵盖 **所有** 文件，即使项目项被省略。摘要的术语表标识符/计数是 Web 减函数器聚合，而非提供商元数据。

计划索引顺序中最多包含 500 个项目，编码项目预算总量为 512,000 字节。无法容纳的项目被省略，`omitted_items` 计算每个被任一限制排除的行。实时翻译输出、流式文本、思考、私有提供商有效负载和原始故障详情从未包含。实时公共模型调用次数可能在重新连接或协调后重置；最终持久计数和文件状态被重建。完整本机快照限制为 1,000,000 个编码 JSON 字节。如果未变会话元数据或完整摘要单独超过该限制，加入将失败并带有 `{"reason":"payload_too_large"}`，或现有通道接收该原因及 `error` 并关闭，而不是发送超大帧或静默截断溯源。

服务器订阅现有的跨节点会话 PubSub，在 **之前** 读取持久前缀，折叠实时尾部并进行序列去重，同时合并进度/状态/发布通知形成约 100 毫秒的完整快照。无需针对每个客户端进行 HTTP 轮询或运行器本地状态。每五秒更新授权并重建持久状态以修复错过的通知。在前台化或传输中断后，请重新连接并重新加入；加入投影无需重放增量。连接期间遵循正常的 Phoenix 心跳生命周期，不再查看主题时离开。

当前持久令牌授予、到期/撤销、用户、`translation:read` 令牌作用域、策略权限、项目可见性及精确账户/项目/会话关联在加入和每次快照前进行检查。缺失作用域或策略权限返回 `{"reason":"forbidden"}`；资源缺失返回 `{"reason":"not_found"}`；过期/撤销的认证返回 `{"reason":"sign_in_required"}`。加入成功后，拒绝返回 `access_revoked` 及该原因并立即关闭通道（无后续快照）。更新也检测空闲通道的撤销。在 `sign_in_required` 时，刷新/重新认证并创建新连接；对于其他拒绝，停止显示受保护详情。WebSocket 是前景实时更新机制，而非移动应用挂起时交付的保证。

## 分析

`GET /api/:handle/projects/:project/analytics?days=30` 返回汇总指标、多达十页顶级页面和流量时间序列。空项目返回：

```json
{
  "summary": {
    "pageviews": 0,
    "unique_visitors": 0,
    "locale_gap_visits": 0,
    "top_country": "",
    "top_browser_language": ""
  },
  "top_pages": [],
  "traffic": {"granularity": "day", "points": []},
  "days": 30
}
```

`days` 默认为 `30`，且必须是从 `1` 到 `365` 的整数。滚动 UTC 报告窗口在请求时结束。这些是相同的基于项目的 ClickHouse 聚合指标，与仪表板相同，包括其每日旋转的访客标识符。存储故障返回 `503` 并携带 `error: "analytics_unavailable"`，绝不分篇捏造零计数。

`traffic.granularity` 在小于两天窗口为 `"hour"`，在九十日内窗口为 `"day"`，其他情况为 `"month"`。`traffic.points` 按时间顺序排列。每个点包含 UTC 桶起始时间戳和非负整数计数：

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

计数仅包含请求报告窗口内的事件，因此第一个和最后一个桶可能是不完整的。当存在事件时，该窗口内的安静桶包含零计数被包括。当没有事件时，`points` 为空而非合成平坦趋势。`unique_visitors` 统计每个桶 **内的** 不同标识符；累加这些值并不能给出周期内的不同访客数量。使用 `summary.unique_visitors` 来获取该总数。客户端应原样绘制返回的桶，而非从汇总指标中重构趋势。

## Toki 对话

### 创建和列出

`POST /api/:handle/projects/:project/toki/conversations` 接受客户端生成的 UUID：

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

它返回 `201` 及 `{conversation, messages: []}`。空对话标题为 `New conversation` 状态为 `completed`（空闲，未生成）。重放同一的发言者、项目和起源 UUID 返回现有详情，不创建另一个对话。对另一个发言者、项目或起源重用则返回 `409` 及 `error: "id_conflict"`。

`GET /api/:handle/projects/:project/toki/conversations` 返回 `{conversations: [...], meta: {...}}`。对话包含 `id`、`title`、`status`、`updated_at`、可选 `error` 和可选 `translation_session_id`。标题源自第一条用户消息，而非第二条模型调用。

### 翻译起源

创建可选接受来自同一项目的翻译会话 UUID：

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

起源不可变；省略和 `null` 均表示无起源。重试必须提供相同起源，包括发送消息后。无法稍后附加起源或通过重试移除。格式错误的起源返回 `422`；缺少或非本机项目源返回 `404`。源关联创建还需 `translation:read` 令牌作用域和当前策略权限，连同 `toki:write` 及项目读取权限。客户端提供的源摘要、元数据、角色和所有权被忽略。仅持久化 UUID；服务器在回复时解析授权上下文。

**来源关联对话拒绝访问**，而非仅遮盖 UUID：没有当前 `translation:read` 作用域或策略权限，详情、匹配起源创建重放、消息发送和消息重放返回 `403`。不匹配起源仍返回 `409` 且不返回历史或源元数据。列表省略整个源关联对话，包括标题和分页计数贡献。这保护可能提及源的早期助手消息。缺失作用域包含正常 `WWW-Authenticate` 挑战。未关联对话保留其现有的仅 Toki 授权行为。

删除或移动的源也拒绝连接：源关联详情、发送及匹配创建重试返回 `404`，列表省略对话。不可变 UUID 在源删除后仍保留存储，因此重试不会静默变为未关联。引用无级联外键；每次使用均检查当前源存在及其精确项目/账户。源引用不授予访问或修改声音、术语表或共享上下文。

创建或打开源关联对话 **不会** 发送消息或加载推理。原生导航应首先获取翻译详情；仅明确的用户操作应创建对话，且单独的明确消息提交开启回合。不提供提案发布、共享讨论审查或代理编写工具。

### 发送和轮询

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` 接受独立的客户端生成 **消息** UUID：

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

请求在一个数据库事务中持久化用户消息和 Oban 作业。它不调用模型。它返回 `202` 并带有消息轮次状态 `queued` 和当前消息。轮询 `GET /api/:handle/projects/:project/toki/conversations/:id` 直到状态为 `queued` 或 `running`；在 `completed` 或 `failed` 时停止。

详情响应的形状为：

```json
{
  "conversation": {
    "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
    "translation_session_id": null,
    "title": "Which translations have completed?",
    "status": "queued",
    "updated_at": "2026-10-25T10:00:00Z",
    "error": null
  },
  "messages": [{
    "id": "17c3b189-80f0-4382-b7bb-1305b1db70ad",
    "role": "user",
    "content": "Which translations have completed?",
    "inserted_at": "2026-10-25T10:00:00Z"
  }]
}
```

消息角色为 `user` 或 `assistant` 且按时间顺序。对话最多持 100 条消息，因此详情端点返回其整个受限历史，无需额外分页请求。

重放与内容完全相同的消息 UUID 从不会加载另一个推理，包括在完成后或失败时。已确认的重放返回 `200`；待处理的重放返回 `202`。复用不同内容的 UUID 或在另一个对话中复用返回 `409`。回合处于活跃状态时提交的另一个消息返回 `409` 并带有 `error: "conversation_busy"`。

### 模型行为与限制

- 每个用户消息均为非空文本，最多 8,000 个字符和 32,000 个 UTF-8 字节。无效的 UUID、类型或内容返回 `422`。
- 每个用户每个项目最多可维持 100 个对话，跨项目最多五个排队/运行中的对话。多于五个待处理回合返回 `429`；对话/历史限制返回 `422`。
- 新消息每小时每服务器每用户最多 30 条，外加正常的 API 速率限制。重放不消耗推理配额。
- 专用 Oban 队列每个服务器最多并发运行两个作业。每个回合最多进行一个提供者 HTTP 请求：ReqLLM 准备提供者请求，然后 Oban 工作器同步执行该请求，在提供者附加后禁用 HTTP 重试和重定向。不涉及 Condukt 会话、分离的推理任务、工具、子代理或文件系统指令加载。提供者接收 2,048 个输出令牌上限；助手回复同样限制为 8,000 个字符和 32,000 个字节。
- HTTP 连接和池等待限制为五秒，套接字接收等待限制为六十秒。Oban 工作器有九十秒的硬时钟截止时间，包括流式响应。工作器终止也会终止其本地推理执行。断开连接无法保证已接受计算被远程提供者取消，因此模糊失败永远不会自动重试。
- 当令牌和当前成员身份均允许 `translation:read` 时，模型接收受限项目元数据和最多三个最近的翻译摘要。最后十段对话摘录独立于存储进行限制。该模型没有写入能力或通用仓库访问权限，也没有为模型提供任何分析。
- 对于来源关联对话，模型额外接收精确持久化的源，即使它不是最新的：UUID、状态、提交元数据、语言、计数，以及最多 1,000 个摘要字符。上下文标记为 `provenance: "session_summary"`，提示要求报告此摘要级别限制。不加载段文本、仓库文件或客户端提供的源上下文。
- 凭据通过账户现有的生成模型和服务器推理配置解决。交互式 CLI/OAuth 会话不用于 Toki。缺失或无效凭据产生状态 `failed` 并带有 `error: "provider_unavailable"`。
- 提供者失败产生 `inference_failed`；空或输出过大产生 `invalid_provider_response`。不返回原始提供者错误和密钥。失败时不插入合成助手回复。
- 账户/项目访问权限和源存在性、项目/账户关联以及翻译授权在推理前后再次检查。撤销的访问或不足的排队作用域导致回合以 `not_authorized` 失败；已删除或移动的源导致以 `source_unavailable` 失败。任一失败均不持久化助手响应。
- 恢复作业每分钟运行一次，将运行超过两分钟或排队超过十五分钟的工作标记为 `failed`，带有 `inference_interrupted`。这将结算超时、终止和孤儿作业，无需重试推理。延迟作业无法认领已过期消息或覆盖更新的回合。失败后，用户可能故意发送一个新的 **新** 消息 UUID。

## 错误

`401` 表示认证失败。`403` 表示作用域或资源策略禁止访问；缺失作用域包含 `WWW-Authenticate` 挑战。未知项目和外部/私有对话 UUID 返回 `404`。验证使用 `422`，分页使用 `400`，UUID/繁忙冲突使用 `409`，配额耗尽使用 `429`。

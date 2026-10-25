%{
  title: "移动及配套 API",
  summary: "原生外观、个人资料、翻译活动、分析及私密 Toki 对话。",
  category: "参考",
  subcategory: "API",
  order: 4
}
---

除了公共原生外观目录外，所有端点都需要 Bearer 令牌。[OpenAPI 规范](/api/openapi.json) 描述了完整的架构。通过现有的 [OAuth PKCE 流程](/docs/reference/apis/authentication) 获取令牌。切勿在客户端中嵌入推理提供商密钥。

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

令牌范围是一个上限，而非授予权限。每个项目端点还会检查用户的“项目读取”权限。第二个 `project:read` **令牌** 范围并非必需，但具有显式权限的组织成员资格必须同时允许项目读取和所需的权限。新成员资格包括这些移动能力；现有的显式成员资格不会自动扩展。

个人项目遵循现有的个人 - 组织成员资格规则。账户可见性控制公开项目读取；已认证的访客具备所需范围时可以读取公开项目的翻译活动和统计数据。Toki 写入需要账户成员资格，仅凭公开可见性不会消耗账户的推理额度。Toki 会话在其项目内保持创建者的私有，即使是在公共账户上。组织和平台管理员无法读取其他用户会话。知晓会话 UUID 并不能提供访问权限。

## 原生外观

`GET /api/native/themes` 返回所选 Glossia 服务器的实例级外观元数据，无需身份验证或用户/项目数据。响应中包含 `Cache-Control: public, max-age=300`。这不会更改任何项目端点的授权。

该响应包含四个必需字段：

| 字段 | 值 |
|---|---|
| `schema_version` | 整数 `1` |
| `revision` | 非空白内容修订版本，最多 128 个字符 |
| `default_theme_id` | `"glossia"` |
| `themes` | 包含默认 Glossia 主题的属性 |

默认主题包含 `id: "glossia"`、`name: "Glossia"`，一个非空白的 `description`、`typography: "standard"`、`button_radius: 8`、`card_radius: 12` 以及 `light` 和 `dark` 调色板。半径是数字逻辑像素。每个调色板包含以下所有九个字段，表示为不透明的 `#RRGGBB` 颜色：

| 调色板字段 | 浅色 | 深色 |
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

目录由标准 `:root` 颜色和半径令牌中的规范 `app/priv/static/assets/styles.css` 编译而成。深色调色板仅使用原生语义令牌且不改变网页渲染。在令牌更改后重新构建会更新目录及其确定性修订版本。修订版本涵盖目录内容，而非无关的样式表编辑。不包含每用户偏好或运行时主题配置。

## 个人资料

`GET /api/me` 仅返回已认证用户的个人资料：

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

`name` 可为 `null`。用户名属于用户的个人账户，而非所选的组织。`server_version` 是运行中应用程序的版本。

## 分页

翻译和会话列表接受 `page`（默认 `1`，范围 `1–10000`）和 `page_size`（默认 `20`，范围 `1–50`）。无效值返回 `400` 而不是静默钳制。元数据使用与其他 Glossia API 列表相同的形状：

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

列表反映当前状态，而非冻结快照。会话排序以最近更新为先，使用 UUID 作为确定性决胜项。

## 翻译活动

`GET /api/:handle/projects/:project/translations?page=1` 返回：

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

状态为 `pending`、`running`、`completed`、`failed` 或 `cancelled`。提交消息、源语言和摘要可以是 `null`，而在待定或不可用时。结果按最新顺序排列并限制于对应的项目。

`GET /api/:handle/projects/:project/translations/:id` 返回 `{session: {...}, progress: {...}}`。`session` 具有与列表会话字段完全相同的形态，外加可为空的 `commit_sha`，保持不变。`progress` 使用与 Web 仪表板相同的 Elixir 进度缩减器从持久事件重建。这是针对所述项目内的直接、精确 UUID 查找，独立于分页或会话的年龄。格式错误、丢失和异项项目 ID 返回 `404` 带有 `error: "not_found"`；身份验证和项目授权首先运行（`401`/`403`）。打开此资源绝不会创建会话、发送消息或启动推理。它提供 **会话摘要级别的溯源** 和每文件进度，而非翻译片段文本或翻译的输出审查。

### 原生实时进度

在 `/native/socket/websocket?vsn=2.0.0` 处打开持久的 Phoenix WebSocket (`wss` 在 HTTPS 服务器上)。取消长轮询。仅通过 WebSocket 子协议头发送访问令牌，切勿通过查询参数发送。

```text
Sec-WebSocket-Protocol: phoenix,base64url.bearer.phx.<base64url-no-padding-of-access-token>
```

服务器协商 `phoenix`。加入主题 `translation:<session UUID>`，使用 `{"organization":"account-handle","project":"project-handle"}`。组织值与 HTTP API 使用的账户句柄相同，包括个人账户。加入回复和每个 `snapshot` 事件携带与 HTTP 详情相同的完整投影：

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

`seq` 是持久进度序列，**不是** 唯一快照版本。会话状态/发布更改和实时模型调用次数可能会产生具有相同序列的新快照；即使 `seq` 未更改，也替换之前的投影。每文件状态为 `queued`、`running`、`done`、`failed` 和 `cancelled`。路径、区域和文件引用在已知之前可以是 `null`。未受触碰的会话具有零序列、空项和零计数。摘要涵盖 **所有** 文件，即使项被省略。摘要的词典标识符/计数是 Web 缩减器的聚合，而非提供商元数据。

最多包含按计划索引顺序排列的 500 项，具有 512,000 字节的编码项预算。无法适配的项会被省略，`omitted_items` 统计任一限制排除的每行。原始翻译输出、流式文本、思考、私有提供商负载和原始故障详情绝不会被包含。实时公开模型调用次数在重新连接或结算后可能会重置；持久最终计数和文件状态被重建。完整原生快照限制为 1,000,000 个编码 JSON 字节。如果未更改的会话元数据或完整摘要本身超过该限制，加入将失败并返回 `{"reason":"payload_too_large"}`，或现有通道接收 `error` 并因此关闭，而非发送过大帧或静默截断溯源。

服务器订阅已存在的跨节点会话 PubSub **之前** 读取持久前缀，折叠实时尾部与序列去重，并将进度/状态/发布通知合并到大约 100 毫秒的完整快照中。不需要每个客户端的 HTTP 轮询或运行时本地状态。每五秒它更新授权并重建持久状态以修复丢失的通知。在置顶或传输中断后重新连接并重新加入；加入投影足以无需重放差异。连接期间遵循正常的 Phoenix 心跳生命周期，并且不再查看它时离开主题。

当前已持久化的令牌授权、过期/撤销、用户、`translation:read` 令牌范围、策略许可、项目可见性、以及精确的账户/项目/会话关联在加入和每个快照之前都会被检查。缺失的范围或策略许可返回 `{"reason":"forbidden"}`；缺失的资源返回 `{"reason":"not_found"}`；过期/撤销的认证返回 `{"reason":"sign_in_required"}`。加入成功后，拒绝会发出 `access_revoked` 并带有该原因，并立即关闭通道而不生成另一个快照。更新也会检测空闲通道上的撤销。在 `sign_in_required` 上，刷新/重新认证并创建新的连接；在其他拒绝的情况下，停止显示受保护的详细信息。WebSocket 是前台实时更新机制，而不是移动应用程序挂起时交付的保证。

## 分析

`GET /api/:handle/projects/:project/analytics?days=30` 返回摘要指标、最高十个站点页面和流量时间序列。空项目返回：

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

`days` 默认值为 `30`，必须是 `1` 至 `365` 之间的整数。报告窗口以请求时间为结束时间。这些是仪表板插入到请求级别的 ClickHouse 聚合，包括其按天旋转的用户标识符。存储故障返回 `503`，带有 `error: "analytics_unavailable"`，绝不虚构零指标。

`traffic.granularity` 为不超过两天的窗口是 `"hour"`，为不超过九十天的窗口是 `"day"`，其他情况为 `"month"`。`traffic.points` 按时间顺序排列。每个点包含一个 UTC 桶开始时间戳和非负整数计数：

```json
{"bucket": "2026-10-25T00:00:00Z", "pageviews": 420, "unique_visitors": 280}
```

计数仅包含请求报告窗口内的事件，因此第一个和最后一个桶可能部分。当有事件时，该窗口内的安静桶以零计数包含。当没有事件时，`points` 为空而不是合成平坦趋势。`unique_visitors` 计数每个桶 **内** 的不同标识符；对这些值求和不会给出该时段的不同访客计数。使用 `summary.unique_visitors` 获取该总数。客户端应以不变的返回桶进行绘图，而不是从摘要指标重构趋势。

## Toki 对话

### 创建和列表

`POST /api/:handle/projects/:project/toki/conversations` 接受客户端生成的 UUID：

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

它返回 `201`，包含 `{conversation, messages: []}`。空对话的标题为 `New conversation`，状态为 `completed`（空闲，未生成）。重放相同操作符、项目和源的项目产生相同的 UUID 返回现有关键而不创建另一个对话。重用同一项目内其他操作符、项目或源的项目产生 `409`，带有 `error: "id_conflict"`。

`GET /api/:handle/projects/:project/toki/conversations` 返回 `{conversations: [...], meta: {...}}`。对话包含 `id`、`title`、`status`、`updated_at`、可选 `error` 和 可选 `translation_session_id`。标题源自第一个用户消息，而非来自第二个模型调用。

### 翻译来源

创建可选地接受来自同一项目的翻译会话 UUID：

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

来源不可变；省略和 `null` 都意味着没有来源。重试必须提供相同的来源，包括在发送消息后。无法在后来附加来源或用重试移除一个来源。格式不良的来源返回 `422`；缺失或外来项目的来源返回 `404`。来源关联创建还需要 `translation:read` 令牌范围和当前策略许可，与 `toki:write` 和项目读取权限并排。客户端提供的来源摘要、元数据、角色和所有权被忽略。仅 UUID 被持久存储；服务器在回复时解决其授权上下文。

**来源关联对话以关闭方式失败**，而非仅红注 UUID：没有当前 `translation:read` 范围或策略权限，详细、匹配来源创建重放、消息发送和消息重放返回 `403`。不匹配来源仍然返回 `409` 而不返回历史记录或来源元数据。列表省略了整个来源关联对话，包括其标题和对分页计数的贡献。这保护更早可能提及来源的助手消息。缺失范围包括正常 `WWW-Authenticate` 挑战。未链接对话保留其现有 Toki 唯一授权行为。

删除或移动来源也以关闭方式失败：来源关联详细、发送和匹配创建重试返回 `404`，列表省略对话。不可变 UUID 在来源删除后保持存储，以便重试无法静默变为未链接。引用没有级联外键；每次使用检查当前来源是否存在及其确切项目/账户。无来源授予访问或更改声音、词典或共享上下文。

创建或打开来源关联对话 **不** 发送消息或排队推理。原生导航应先获取翻译详细；仅明确的操作用户应创建对话，且独立的明确消息提交启动一轮。不提供建议出版、共享讨论审查或代理写工具。

### 发送和轮询

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` 接受单独的客户端生成 **消息** UUID：

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

请求将用户消息和 Oban 任务在一个数据库事务中持久化。它不调用模型。它返回 `202`，带有对话状态 `queued` 和当前消息。在状态为 `queued` 或 `running` 时轮询 `GET /api/:handle/projects/:project/toki/conversations/:id`；停止在 `completed` 或 `failed`。

详细响应格式如下：

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

消息具有角色 `user` 或 `assistant` 且按时间顺序排列。对话最多结构 100 条消息，因此详细端点返回其整个有界历史记录而无需额外的页面请求。

重复具有相同内容的消息 UUID 不会安排另一次推理，即使在处理完成或失败后也是如此。已确定的重复返回 `200`；待处理的重复返回 `202`。使用不同内容或在其他对话中重用 UUID 返回 `409`。在一轮活动期间提交的另一条消息返回 `409`，并带有 `error: "conversation_busy"`。

### 模型行为与限制

- 每条用户消息为非空文本，最多 8,000 个字符和 32,000 个 UTF-8 字节。无效的 UUID、类型或内容返回 `422`。
- 每台用户每项目最多可持有 100 个对话，跨项目最多五个排队/运行中的对话。超过五个待处理轮次返回 `429`；对话/历史限制返回 `422`。
- 新消息限制为每台服务器每小时每位用户 30 条，另加常规 API 速率限制。重复不消耗推理配额。
- 专用 Oban 队列在每台服务器上并发运行两个任务。每个轮次最多执行一次提供商 HTTP 请求：ReqLLM 准备提供商请求，随后 Oban 工作线程同步执行该请求，在附加提供商后 HTTP 重试和重定向被禁用。不涉及 Condukt 会话、分离的推理任务、工具、子代理或文件系统指令加载。提供商接收 2,048 个输出令牌上限；助手回复同样限制为 8,000 个字符和 32,000 个字节。
- HTTP 连接和池等待限制为五秒，套接字接收等待限制为六十秒。Oban 工作线程具有九十秒的硬性墙钟期限，包括流量响应。工作线程终止也会终止其本地推理执行。断开连接无法保证取消已接受于远程提供商的运算，因此不明确故障永远不会自动重试。
- 当令牌和当前成员资格均允许 `translation:read` 时，模型接收有边界的项目元数据以及最多三个最近的翻译摘要。最后十句对话摘录独立于存储进行限制。模型没有写入能力或通用仓库访问权限，也不会向模型提供任何分析数据。
- 对于来源关联对话，模型额外接收确切的持久化来源，即使它不是最近的：UUID、状态、提交元数据、语言、计数以及最多 1,000 个摘要字符。上下文标记为 `provenance: "session_summary"`，提示要求报告此摘要级限制。不加载文段文本、仓库文件或客户端提供的来源上下文。
- 凭据通过账户现有的生成模型和服务器推理配置解析。交互式 CLI/OAuth 会话不用于 Toki。缺失或不受支持的凭据生成状态 `failed` 并带有 `error: "provider_unavailable"`。
- 提供商故障生成 `inference_failed`；空或过大的输出生成 `invalid_provider_response`。不返回原始提供商错误和密钥。失败时不插入合成助手回复。
- 账户/项目访问和来源存在性、项目/账户关联以及翻译授权在推理前后再次进行检查。撤销访问或队列范围不足导致轮次以 `not_authorized` 失败；删除或移动的来源以 `source_unavailable` 失败。两种故障情况下助手响应均不持久化。
- 恢复任务每分钟运行一次，并将运行超过两分钟或排队超过十五分钟的工作标记为 `failed` 与 `inference_interrupted`。此功能解决超时、终止和孤儿任务，而无需重试推理。延迟任务无法获取过期消息或覆盖更新的轮次。用户可以在失败后故意发送 **新** 消息 UUID。

## 错误

`401` 表示身份验证失败。`403` 表示范围或资源策略拒绝访问；缺失范围包括 `WWW-Authenticate` 挑战。未知项目和外部/私有对话 UUID 返回 `404`。验证使用 `422`，分页使用 `400`，UUID/忙冲突使用 `409`，配额耗尽使用 `429`。

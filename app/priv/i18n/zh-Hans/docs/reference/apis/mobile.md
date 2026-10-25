%{
  title: "移动与伴侣 API",
  summary: "原生外观、个人资料、翻译活动、数据分析及私密的 Toki 对话。",
  category: "参考",
  subcategory: "API",
  order: 4
}
---

所有端点（除公开的原生外观目录外）都需要 Bearer 令牌。该 [OpenAPI 规范](/api/openapi.json) 描述了完整的架构。通过现有的 [OAuth PKCE 流程](/docs/reference/apis/authentication) 获取令牌。切勿在客户端中嵌入推理提供程序密钥。

## 授权

| 端点 | 令牌作用域 |
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

令牌作用域是上限，而非授予权限。每个项目端点也会检查用户的账户 - 项目读取权限。第二个 `project:read` **令牌** 范围并非必需，但具有显式权限的组织成员资格必须允许项目读取和所需功能。新成员资格包含这些移动功能；现有显式成员资格不会自动扩大。

个人项目遵循现有的个人组织成员规则。账户可见性控制公开项目读取；具有必要范围的经过身份验证的外部用户可以读取公开项目的翻译活动和数据分析。Toki 写入需要账户成员资格，因此仅公开可见性不会消耗账户的推理额度。Toki 对话保持在其项目中的创建用户私有，即使是在公开账户上。组织和平台管理员无法读取其他用户的对话。知道对话 UUID 不会授予访问权限。

## 原生外观

该 `GET /api/native/themes` 返回来自所选 Glossia 服务器的跨实例外观元数据，不包含身份验证或用户/项目数据。响应包含 `Cache-Control: public, max-age=300`。这不会改变任何项目端点的授权。

响应包含四个必填字段：

| 字段 | 值 |
|---|---|
| `schema_version` | 整数 `1` |
| `revision` | 非空白内容修订版，最多 128 个字符 |
| `default_theme_id` | `"glossia"` |
| `themes` | 包含默认 Glossia 主题的数组 |

默认主题具有 `id: "glossia"`, `name: "Glossia"`, 一个非空白 `description`, `typography: "standard"`, `button_radius: 8`, `card_radius: 12` 和 `light` 以及 `dark` 调色板。半径为数值逻辑像素。每个调色板包含以下所有九个字段，以不透明 `#RRGGBB` 颜色表示：

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

目录由 `app/priv/static/assets/styles.css` 中的规范 `:root` 颜色和半径标记编译而成。暗色调色板使用仅原生的语义标记，不更改网络渲染。令牌更改后的重建会更新目录及其确定性修订。修订版涵盖目录内容，并非 unrelated stylesheet 编辑。不包含任何按用户的偏好或运行时主题配置。

## 个人资料

该 `GET /api/me` 仅返回经过身份验证的用户资料：

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

`name` 可为 `null`。句柄属于用户的个人账户，而非选定的组织。`server_version` 是当前应用版本。

## 分页

翻译和对话列表接受 `page`（默认 `1`，范围 `1–10000`）和 `page_size`（默认 `20`，范围 `1–50`）。无效值将返回 `400` 而不是静默钳制。元数据与其他 Glossia API 列表的形状相同：

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

列表反映当前状态，而非静止快照。对话排序按最近更新时间优先，UUID 作为确定性打破平局的依据。

## 翻译活动

该 `GET /api/:handle/projects/:project/translations?page=1` 返回：

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

状态为 `pending`、`running`、`completed`、`failed` 或 `cancelled`。提交消息、源语言和摘要在等待期间或不可用时可以为 `null`。结果按最新顺序排列，并限制在选定项目中。

该 `GET /api/:handle/projects/:project/translations/:id` 返回 `{session: {...}}`，包含与列表会话字段完全相同的精确字段，外加可空 `commit_sha`。这是针对选定项目和账户的直接、精确 UUID 查找，独立于分页或会话的年龄。格式错误、缺失和跨项目 ID 将返回 `404` 并带有 `error: "not_found"`；身份验证和项目授权仍首先运行（`401`/`403`）。打开此资源永远不会创建对话、发送消息或启动推理。它提供 **会话摘要级溯源**，而非翻译片段文本或对翻译输出的审查。

## 分析

该 `GET /api/:handle/projects/:project/analytics?days=30` 返回：

```json
{
  "summary": {
    "pageviews": 1350,
    "unique_visitors": 900,
    "locale_gap_visits": 180,
    "top_country": "DE",
    "top_browser_language": "de"
  },
  "top_pages": [{"pathname": "/docs", "pageviews": 420}],
  "days": 30
}
```

该 `days` 默认为 `30`，且必须为 `1` 到 `365` 之间的整数。滚动 UTC 报告窗口在请求时结束。这与仪表板相同的项目范围 ClickHouse 聚合，包括其每日轮转的访问者标识符。主要页面列表最多包含十个条目。空数据集返回零计数、空顶级值字符串和空页面列表。存储失败返回 `503` 并带有 `error: "analytics_unavailable"`，绝不会虚构零指标。

## Toki 对话

### 创建与列表

该 `POST /api/:handle/projects/:project/toki/conversations` 接受客户端生成的 UUID：

```json
{"id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b"}
```

它返回 `201` 并包含 `{conversation, messages: []}`。空对话的标题为 `New conversation`，状态为 `completed`（空闲，未生成）。对相同的操作者、项目和源重复相同的 UUID 将返回现有详情，而无需创建另一对话。在另一个操作者、项目或源上重复使用它将返回 `409` 并带有 `error: "id_conflict"`。

该 `GET /api/:handle/projects/:project/toki/conversations` 返回 `{conversations: [...], meta: {...}}`。对话包含 `id`、`title`、`status`、`updated_at`、可空 `error` 和可空 `translation_session_id`。标题由第一个用户消息推导而来，而非第二个模型调用。

### 翻译来源

创建过程可选地接受来自同一项目的翻译会话 UUID：

```json
{
  "id": "52a3b55c-c2db-4b3f-a83f-d7d3542ae46b",
  "translation_session_id": "e4183cef-2b43-42a8-a60f-78b4fbb02bbf"
}
```

起源是不可变的；省略和 `null` 都意味着没有起源。重试必须提供相同的起源，包括在发送消息之后。您不能稍后附加起源，也不能通过重试移除起源。格式错误的起源返回 `422`；缺失或非项目的来源返回 `404`。来源关联创建还需要 `translation:read` 标记作用域和当前策略权限，以及 `toki:write` 和项目读取权限。客户端提供的来源摘要、元数据、角色和所有权将被忽略。仅 UUID 会被持久化；服务器将在回复时解析其授权上下文。

**来源关联对话拒绝访问**，而非仅仅遮盖 UUID：如果没有当前 `translation:read` 作用域或策略权限，详情、匹配起源创建重放、消息发送和消息重放将返回 `403`。不匹配的起源返回 `409`，且不返回历史记录或来源元数据。列表省略整个来源关联对话，包括其标题和对分页计数的贡献。这保护了可能提到来源的先前的助手消息。缺失的范围包括正常的 `WWW-Authenticate` 认证挑战。未链接对话保留其现有的仅 Toki 授权行为。

已删除或移动的源也会拒绝访问：来源关联详情、发送和匹配创建重试返回 `404`，且列表省略对话。不可变的 UUID 在源删除后仍然存储，因此重试无法无声地变成未链接。引用没有级联外键；每次使用都检查源的当前存在性及其确切的项目/账户。无源授权赋予访问权限或更改声音、词典或共享上下文。

创建或打开来源关联对话不 **不会** 发送消息或排队推理。原生导航应首先获取翻译详情；只有显式用户行为才应创建对话，而单独的显式消息提交则开始一个回合。不提供提案发布、共享讨论审查或代理写入工具。

### 发送和轮询

`POST /api/:handle/projects/:project/toki/conversations/:id/messages` 接受单独的客户端生成的 **消息** UUID：

```json
{"id": "17c3b189-80f0-4382-b7bb-1305b1db70ad", "content": "Which translations have completed?"}
```

请求将用户消息和一个 Oban 作业在一个数据库事务中持久化。它不调用模型。它返回 `202`，对话状态为 `queued`，以及当前消息。查询 `GET /api/:handle/projects/:project/toki/conversations/:id` 直到状态是 `queued` 或 `running`；在 `completed` 或 `failed` 时停止。

详情回复具有以下格式：

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

消息的角色为 `user` 或 `assistant`，并按时间顺序排列。一个对话最多容纳 100 条消息，因此详情端点返回其完整的有界历史记录，无需额外页面请求。

重播具有相同内容的消息 UUID 永远不会排队另一个推理，包括在完成后或失败后。已确定的重播放回返回 `200`；正在进行的重播放回返回 `202`。重用具有不同内容或在其他对话中的 UUID 返回 `409`。在回合活动期间提交的另一条消息返回 `409`，并带有 `error: "conversation_busy"`。

### 模型行为与限制

- 每个用户消息均为非空白文本，最多 8,000 个字符和 32,000 个 UTF-8 字节。无效的 UUID、类型或内容返回 `422`。
- 每个用户最多可在每个项目中保持 100 个对话，在跨项目中保持 5 个排队/运行中的对话。超过五次待处理回合返回 `429`；对话/历史记录限制返回 `422`。
- 每条新消息限制为每小时每台服务器每个用户 30 条，外加正常的 API 速率限制。重播不消耗推理配额。
- 专用 Oban 队列在每台服务器上并发运行两个作业。每个回合最多制作一个提供程序 HTTP 请求：ReqLLM 准备提供程序请求，然后 Oban 作业器同步执行它，并在提供程序附加后禁用 HTTP 重试和重定向。不参与 Condukt 会话、分离推理任务、工具、子代理或文件系统指令加载。提供程序接收 2,048 个输出令牌上限，助手回复也限制为 8,000 个字符和 32,000 个字节。
- HTTP 连接和池等待限制为五秒，套接字接收等待为六十秒。Oban 作业器有九十秒的硬性实时期限，包括滴流响应。作业终止也会终止其本地推理执行。断开连接无法保证取消已被远程提供程序接受的处理，因此模糊失败永远不会自动重试。
- 当令牌和当前成员资格都允许 `translation:read` 时，模型接收有界的项目元数据和最多最近三个翻译摘要。最后十个对话摘录独立于存储进行有界。它没有写入能力或一般仓库访问权限，也没有向模型提供任何分析数据。
- 对于来源关联对话，模型除了接收确切的持久化源之外（即使它不最近）：UUID、状态、提交元数据、语言、计数，以及最多 1,000 个摘要字符。上下文标记为 `provenance: "session_summary"`，并且提示需要报告此摘要级限制。不加载片段文本、仓库文件或客户端提供的源上下文。
- 凭证通过账户现有的生成模型和服务器推理配置解析。交互式 CLI/OAuth 会话不用于 Toki。缺失或不受支持的凭证产生状态 `failed` 并带有 `error: "provider_unavailable"`。
- 提供程序失败产生 `inference_failed`；空或过大输出产生 `invalid_provider_response`。原始提供程序错误和机密不会被返回。失败时不插入合成助手回复。
- 账户/项目访问权限和源存在性、项目/账户关联和翻译授权在推断前后再次检查。撤销访问或队列线索不足导致回合失败，返回 `not_authorized`；删除或移动的源失败，返回 `source_unavailable`。任何失败不持久化助手响应。
- 恢复作业每分钟运行一次，将运行时间超过两分钟或排队时间超过十五分钟的工作标记为 `failed` 并带有 `inference_interrupted`。此操作解决了超时、终止和孤立作业，而无需重试推理。延迟作业无法声称过期消息或覆盖更新的回合。用户可在失败后故意发送 **new** 消息 UUID。

## 错误

`401` 表示身份验证失败。`403` 表示范围策略或资源策略拒绝访问；缺失范围包括 `WWW-Authenticate` 挑战。`404` 表示未知项目和 foreign/private 对话 UUID 返回错误。验证使用 `422`，分页使用 `400`，UUID/繁忙冲突使用 `409`，配额耗尽使用 `429`。

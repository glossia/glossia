%{
  title: "语言审查",
  summary: "基于源文的人类决策、翻译延续及经审核的仓库指引。",
  category: "参考",
  section: "translation",
  order: 31
}
---

## 升级

仓库翻译运行（配备配置的决策模型）可以为缺失的源含义或领域上下文、冲突的指引、或由此产生的文化适配请求语言输入。低置信度本身不会触发提问。可从现有上下文中纠正的错误使用普通修正预算；该预算处理失败后剩余的质量问题也可请求输入。若无决策模型，自动语言升级将被禁用。

受影响的文件/区域设置将停止。其未批准的候选版本不会被发布。独立文件将完成并能正常发布。发布完成后，会话将进入 `awaiting_input` 状态并释放其执行器。当人类正在回答时，它不会占用工作者。

每次升级都会开启一个与翻译会话关联的 **具有明确语言目标的共享 Toki 对话**。参与者讨论含义，提出后续问题，并完善提议的决定。单纯的讨论永远不会批准翻译或写入仓库上下文。普通 Toki 对话仅对所有者可见，即便是管理员也无法查看。

所有当前已授权且声明精通语言与目标区域匹配的团队成员将被邀请加入同一对话。精通状态独立于显示语言，并不赋予项目访问权限或批准决定的权限。宽泛语言（如 `es`）匹配区域性变体（如 `es-MX`）；不兼容的明确脚本不会匹配。区域性声明（如 `zh-TW`）使用其惯用的 CLDR 脚本，而宽泛的 `zh` 不受脚本限制。

符合资格的参与者仅在同意接收通知时才会收到通用的移动推送通知；发送时会重新检查当前的精通状态、成员资格、项目访问权限和开放目标。通知将打开共享对话。对话和批准可以从本机应用程序和 Web 仪表板访问。有关提供商配置和推送策略的说明，请参阅 [原生推送通知](/docs/reference/native-push-notifications)。

## 精通语言档案

`GET /api/me` 包含 `user.fluent_languages`。`PUT /api/me/fluent-languages` 需要 `user:write` 且仅接受 `{"fluent_languages": ["es", "ar", "zh-Hant"]}`。它将替换认证用户的列表并返回档案包装器。支持的 CLDR BCP47 标签保留明确的区域/脚本特定性，并使用标准大小写；重复项将合并。空数组将清除精通状态。无效标签、无关字段或提交超过 50 个条目将返回 422。这永远不会更改 UI 区域设置。

## 评审 API

`GET /api/:handle/projects/:project/translations/:id/reviews` 需要 `translation:read` 和项目访问权限。它返回 `{"reviews": [...]}`，首先显示开放问题，然后按最旧顺序，限制 500 条。回答后刷新以揭示剩余问题；已答记录绝不会隐藏开放问题超出限制。

每项审查包含 `id`、`translation_session_id`、`conversation_id`、`participants`（`id` 和可空 `name`）、`status`、`source_path`、`output_path`、`locale`、`question`、受限制的 `source_excerpt` 和 `translation_excerpt`、`answer`、`guidance`、`context_path`、`resolution_message_id`、`resumed_session_id` 和 `inserted_at`。状态为 `open`、`answered` 或 `stale`。

使用现有的项目 Toki 对话和消息端点进行讨论。共享目标对话显示在用户私有对话旁边（Toki 历史中）。共享历史记录需要当前的 Toki 读写策略许可和翻译读取权限；普通历史记录仅所有者可见。人类消息包含作者身份，回复包含 `status` 和 `reply_to_id`。Toki 接收受限制的源/候选摘录和目标，而非仓库写入权限。

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` 需要同时 `translation:read` 和 `translation:write`，以及项目访问权限：

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` 必须识别目标对话中最新的已完成助手 **回复**，而非其开篇问题。`answer` 是人类批准的决定，必须非空。`guidance` 和 `context_scope` 为可选；范围默认为 `locale`，也可以是 `project`。回答和指引各自允许最多 8,000 个字符和 32,000 个 UTF-8 字节。指引不能包含 Glossia 预留的评审标记注释。服务器选择仓库路径；客户端提供的路径永远不会被使用。

成功的响应是 `{"review": {...}}`。重复相同决定的决议消息、指引和范围是幂等的。繁忙的对话返回 `409 conversation_busy`；更新的消息或无效的决议引用返回 `409 resolution_outdated`。在再次批准前重新加载并审查当前讨论。对已解决目标的不同决定返回 `409 already_answered`；批准已取消或已过时的目标返回 `409 stale`。无效文本或不可用的范围返回 422。丢失和外国项目 ID 返回 404。正常的身份验证和项目授权适用于每次请求，包括重复操作。已关闭的目标会拒绝新的讨论消息，返回 `409 goal_closed`。

## 延续和过期上下文

决定可以在独立工作仍在运行时批准。它们当时绝不会启动第二个执行器。一旦执行器被释放且该运行中的每个目标均已解决，Glossia 原子性地排队一个延续会话。`resumed_session_id` 标识它；原始会话保持为历史 `awaiting_input`。仪表板和原生对话均链接到延续会话。

延续具有新的执行身份，并保留翻译发布分支和验证过的输出。每个答案仅适用于相同的源和解析的翻译上下文指纹。更改源、配音、词汇表、模型或仓库指令会阻止重用答案。更新后的默认分支提交会取代等待会话并标记开放问题过期。取消也会标记开放问题过期。

## 可重用的仓库指引

可复用指引是单独的、显式的人类编辑。答案本身不会成为仓库上下文，私人聊天脚本永远不会自动复制。

`locale` 针对适用的区域覆盖层，例如 `L10N/es.md`；`project` 针对适用的 `L10N.md`。现有的作用域上下文文件将被尊重。缺失的区域覆盖层将获得其区域 front matter。保留现有的 front matter 和正文，并将每个决定与其审查 UUID 一起附加，以供溯源和幂等。

指引在常规翻译拉取请求中提出，而非静默写入默认分支。仓库仍需匹配录制的上下文摘要；存在冲突的编辑会导致发布失败，而不是覆盖。路径必须是仓库相对的本地化文档，不包含目录遍历或符号链接。每个上下文文档限制为 1 MiB。合并拉取请求后，该指引成为往后运行的普通版本化本地化上下文。

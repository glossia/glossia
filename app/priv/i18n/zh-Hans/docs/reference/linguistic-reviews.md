%{
  title: "语言审核",
  summary: "基于源文本的人工决策、翻译延续及经审阅的仓库指导。",
  category: "参考",
  section: "translation",
  order: 31
}
---

## 升级

配置了决策模型的仓库翻译运行可以请求缺失源语含义或领域上下文等的语言输入。置信度低本身不会触发疑问。从现有上下文可纠正的错误使用普通纠错配额；超出该配额后剩余的失败也可以请求输入。没有决策模型时，自动语言升级功能被禁用。

仅受影响的文件/语言会停止。未经批准的建议不会被发布。独立文件可以正常完成和发布。发布完成后，会话变为 `awaiting_input` 并释放其执行器。人类作答期间，它不消耗工作线程。

每次升级开启一个与翻译会话关联的 **具有明确语言学目标的共享 Toki 对话**。参与者讨论含义、提出跟进问题并完善拟议的决策。仅讨论本身绝不会批准翻译或写入仓库上下文。普通 Toki 对话仅对所有者私有，包括管理员。

所有声明的流利语言与目标语言匹配的已授权团队成员都会被邀请加入同一个对话。流利度独立于显示语言，不授予项目访问权或批准决策的权限。像 `es` 这样宽泛的语言会匹配 `es-MX` 这样的区域变体；不兼容的显式脚本不会匹配。区域声明如 `zh-TW` 使用其惯用的 CLDR 脚本，而宽泛的 `zh` 不受脚本限制。

符合条件的参与者仅在订阅后才会收到通用移动推送通知；推送会重新检查当前的流利度、成员资格、项目访问权及开放目标。通知会打开共享对话。对话和批准可通过原生应用和网页仪表板获取。查看 [原生推送通知](/docs/reference/native-push-notifications) 以了解提供者配置和交付策略。

## 流利语言配置文件

`GET /api/me` 包含 `user.fluent_languages`。 `PUT /api/me/fluent-languages` 需要 `user:write` 并仅接受 `{"fluent_languages": ["es", "ar", "zh-Hant"]}`。它替换认证用户的列表并返回配置文件信封。支持的 CLDR BCP47 标签保留显式的区域/脚本特定性并使用规范大小写；重复项合并。空数组清除流利度。无效标签、无关字段或提交的超过 50 条条目返回 422。这绝不会更改 UI 区域设置。

## 审查 API

`GET /api/:handle/projects/:project/translations/:id/reviews` 需要 `translation:read` 和项目访问权限。它返回 `{"reviews": [...]}`，优先返回未回答问题，随后是最早的条目，限制为 500 条。回答后刷新以揭示任何剩余问题；已回答的历史记录绝不会在限制后方隐藏未回答问题。

每次审查包含 `id`, `translation_session_id`, `conversation_id`, `participants` (即 `id` 和可为 null 的 `name`)、`status`, `source_path`, `output_path`, `locale`, `question`, 受限于 `source_excerpt` 和 `translation_excerpt`, `answer`, `guidance`, `context_path`, `resolution_message_id`, `resumed_session_id`, 和 `inserted_at`。状态为 `open`, `answered`, 或 `stale`。

`answered_by` 标识批准决策的人，显示为 `{"id": "<user UUID>", "name": "<current display name>"}`；`name` 可为 null。字段在批准前或批准者可不可用时为 null。它不含邮箱或其他私人配置文件字段，重放批准不会更改批准人。该字段也包含在共享 Toki 对话上的嵌套 `linguistic_review` 中。不公开批准时间戳；`inserted_at` 是评论的创建时间，而非审批时间。

使用现有的项目 Toki 对话和消息端点进行讨论。共享目标对话与用户私人对话一同出现在 Toki 历史中。共享历史记录需要当前 Toki 读写策略权限和翻译读取权限；普通历史仅保留所有者。人类消息包含其作者身份，回复包含 `status` 和 `reply_to_id`。Toki 接收受限的源/候选片段和目标，而非仓库写入权限。

`POST /api/:handle/projects/:project/translations/:id/reviews/:review_id/answer` 需要同时具备 `translation:read` 和 `translation:write`，以及项目访问权限。

```json
{
  "resolution_message_id": "019a1c6d-4321-7000-8000-123456789abc",
  "answer": "Branch means a source-control release branch.",
  "guidance": "Use the source-control meaning of branch in release documentation.",
  "context_scope": "locale"
}
```

`resolution_message_id` 必须标识目标对话中最新的已完成助手 **回复**，而非其开放问题。 `answer` 是人类批准的决策，必须填写且不能为空。 `guidance` 和 `context_scope` 为可选；范围默认值为 `locale`，也可为 `project`。回答和指导各允许最多 8,000 个字符和 32,000 个 UTF-8 字节。指导中不能包含 Glossia 的保留审查标记注释。服务器选择仓库路径；客户端提供路径永远不被使用。

成功响应返回 `{"review": {...}}`。重放相同的决策、解决消息、指导和范围是幂等的。会话繁忙时返回 `409 conversation_busy`；新消息或无效解决引用返回 `409 resolution_outdated`。重新加载并查看当前讨论后再批准。针对已解决目标的不同决策返回 `409 already_answered`；批准已取消或过时目标返回 `409 stale`。无效文本或范围不可用时返回 422。丢失或外部项目 ID 返回 404。所有请求（包括重放）均应用正常的身份验证和项目授权。已关闭的目标以 `409 goal_closed` 拒绝新的讨论消息。

## 续用与过时上下文

一旦执行器释放且该运行中每个目标均已解决，Glossia 会原子性地排队一个续用会话。`resumed_session_id` 标识它；原始会话保持历史 `awaiting_input` 状态。仪表板和原生对话均链接到该续用会话。

续用会话拥有新的执行身份，并保留翻译发布分支和验证输出。每个回答仅适用于相同的源和已解析的翻译上下文指纹。更改源、语音、词汇表、模型或仓库指令将阻止回答重用。新的默认分支提交将覆盖等待会话并标记未回答问题过时。取消也会标记未回答问题过时。

## 可复用的仓库指导

可复用指导是一项独立的人工编辑。仅凭答案不会变成仓库上下文，且私人对话记录永远不会被自动复制。

`locale` 指向适用的区域覆盖层，例如 `L10N/es.md`；`project` 指向适用的 `L10N.md`。现有的范围化上下文文件受到保留。缺少的区域覆盖层会收到其区域前元数据。现有的前元数据和正文被保留，且每个决策都会追加其审查 UUID 以用于溯源和幂等性。

指导在正常的翻译拉取请求中提出，而不是静默写入默认分支。仓库必须仍匹配记录的上下文摘要；冲突的编辑会导致发布失败，而不是覆盖它。路径必须是仓库本地化文档，不包含遍历或符号链接。每个上下文文档限制为 1 MiB。合并拉取请求将使指导变为用于后续运行的普通版本化本地化上下文。

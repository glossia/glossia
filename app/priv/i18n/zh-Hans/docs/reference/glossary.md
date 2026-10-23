%{
  title: "术语表",
  summary: "L10N.md 及每种语言覆盖文件中术语字段的参考。",
  category: "参考",
  section: "translation",
  order: 2
}
---

仓库词汇表分布在两个文件中。Glossia 将其与账户的账户词汇表合并用于翻译的每个文件。参见 [词汇表](/docs/explanation/glossary) 以了解两者的结合方式。

| 文件 | `glossary` 包含 | 示例 |
|---|---|---|
| `L10N.md` | 包含 **术语** 的列表，对所有语言均相同。 | `- source: commit` |
| `L10N/<locale>.md` | 从术语到其在该语言中的 **翻译** 的映射。 | `commit: commit` |

## L10N.md 中的术语

```yaml
---
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
  - id: vcs-branch
    source: branch
    definition: A line of development in version control.
---
```

| 字段 | 类型 | 必要 | 描述 |
|---|---|---|---|
| `source` | string | 是 | 术语在源文本中的出现形式。 |
| `definition` | string | 否 | 模型读取并据此判断匹配是否确为对应概念的简短指导说明。 |
| `case_sensitive` | boolean | 否 | 当 `true` 时，术语仅在原始大小写形式下匹配。默认为 `false`。用于名称和缩写，例如 `API` 或 `SDK`。 |
| `id` | string | 否 | 稳定标识符。省略时从 `source` 派生。`Version Control` 变为 `version-control`, `C++` 变为 `cplusplus`。设置它以便按 ID 进行关键翻译，重命名 `source` 的同时保留术语身份，或覆盖父级 `L10N.md` 中的术语。 |

术语不包含翻译。包含 `targets` 字段的术语将被拒绝：翻译应放在语言文件中。

## L10N/<locale>.md 中的翻译

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
  vcs-branch: rama
  pull request: pull request
---
```

每个键是术语的 `id` 或其 `source`，每个值是该语言的批准翻译。

- 在 `L10N.md` 中不匹配任何术语的键仅声明了本语言的术语。
- 没有翻译的术语会回退到该语言的账户词汇表。
- 要保持名称不翻译，将其映射为自身，例如 `Glossia: Glossia`。

## 嵌套文件

每个文件都使用其目录链的词汇表进行翻译：

- 嵌套的 `L10N.md` 会将其添加到继承项中的术语。具有相同 `id`的术语，或在未设置 `id` 时具有相同 `source` 的术语，将替换该子树中的继承项。
- 嵌套的 `L10N/<locale>.md` 会将其添加的翻译添加到继承项中，对于双方都声明的术语，它的翻译胜出。

## 验证

如果词汇表无效，Glossia 仅使用账户词汇表翻译受影响的文件，因此拼写错误永远不会阻止翻译。常见原因：

- **缺少`source`。** 每个术语都需要一个非空值。
- **重复`id`。** 每个术语必须解析为唯一标识符，无论是显式设置还是从 `source` 派生。
- **L10N.md 中的翻译。** 带有 `targets` 的术语。将翻译移至 `L10N/<locale>.md`。
- **空翻译。** 映射到空字符串的术语。相反，将其省略。
- **形状或类型错误。** `glossary` 在 `L10N.md` 中必须是列表，在 `L10N/<locale>.md` 中必须是映射。翻译、`id` 和 `definition` 必须是字符串；`case_sensitive` 必须是 `true` 或 `false`。

## Glossia 记录的内容

每个翻译文件的锁文件记录塑造它的词汇表条目：

```json
{
  "server_context": {
    "glossary": {
      "applied": ["repo:commit", "account:repository"],
      "shadowed": ["account:commit"]
    }
  }
}
```

- `applied` 列出匹配该文件的条目。存储库条目显示为 `repo:<id>`, 账户条目显示为 `account:<id>`。
- `shadowed` 列出该文件中被存储库条目替换的账户条目。

编辑术语或翻译只会重新翻译使用它的文件。

## 参见

- [定义词汇表](/docs/how-to/define-a-glossary)：逐步指南。
- [词汇表](/docs/explanation/glossary)：存储库和账户词汇表如何合并。
- [L10N.md 参考](/docs/reference/l10n-md)：其他 frontmatter 字段。

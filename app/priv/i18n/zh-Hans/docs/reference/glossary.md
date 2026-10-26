%{
  title: "术语表",
  summary: "L10N.md 和每种语言覆盖文件中术语表字段的参考。",
  category: "参考",
  section: "translation",
  order: 2
}
---

仓库词典分成两个文件。Glossia 在翻译每个文件时将其与账户词典合并。参见 [Glossary](/docs/explanation/glossary) 了解两者如何合并。

| 文件 | `glossary` 包含 | 示例 |
|---|---|---|
| `L10N.md` | 一份 **terms** 列表，对所有语言都相同。 | `- source: commit` |
| `L10N/<locale>.md` | 从术语到该语言中其 **translation** 的映射。 | `commit: commit` |

## Terms in L10N.md

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

| Field | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | 源文本中出现的术语。 |
| `definition` | string | no | 模型用来判断匹配是否真为该概念的简短说明。 |
| `case_sensitive` | boolean | no | 当 `true` 为真时，术语仅匹配原文的确切大小写。默认为 `false`。适用于名称和缩写，如 `API` 或 `SDK`。 |
| `id` | string | no | 稳定标识符。省略 `source` 时从源推导（`Version Control` 变为 `version-control`，`C++` 变为 `cplusplus`）。通过 id 设置关键翻译，或直接重命名 `source` 而不丢失术语身份，或覆盖父级 `L10N.md` 中的术语。 |

术语不包含翻译。带有 `targets` 字段的术语会被拒绝：翻译应放在语言文件中。

## Translations in L10N/<locale>.md

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

- 与 `L10N.md` 中任何术语均不匹配的键仅声明此语言的术语。
- 语言中无翻译的术语会回退到该语言的账户词典。
- 要保持名称不翻译，将其映射到自身，例如 `Glossia: Glossia`。

## Nested files

每个文件使用其目录链的词典进行翻译：

- 嵌套的 `L10N.md` 添加了其继承的术语项。具有相同 `id` 的术语，或没有设置 `id` 时 `source` 相同，则该项会替换该子树中的继承项。
- 嵌套的 `L10N/<locale>.md` 添加了其继承的翻译，其翻译对两者均声明的术语具有优先权。

## Validation

如果词典无效，Glossia 仅用账户词典翻译受影响的文件，因此拼写错误永远不会阻止翻译。常见原因：

- **Missing `source`.** 每个术语都需要一个非空的。
- **Duplicate `id`.** 每个术语必须解析为唯一标识符，无论是显式设置还是从 `source` 推导。
- **Translations in L10N.md.** 带有 `targets` 的术语。将翻译移到 `L10N/<locale>.md`。
- **Empty translation.** 映射到空字符串的术语。应将其排除。
- **Wrong shapes or types.** `glossary` 在 `L10N.md` 中必须是列表，在 `L10N/<locale>.md` 中必须是映射。翻译、`id` 和 `definition` 必须是字符串；`case_sensitive` 必须是 `true` 或 `false`。

## Glossia 记录的内容

每个翻译文件的锁文件都会记录塑造它的词典条目：

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

- `applied` 列出了匹配该文件的条目。仓库条目显示为 `repo:<id>`, 账户条目显示为 `account:<id>`。
- `shadowed` 列出了仓库条目为该文件替换的账户条目。

编辑术语或翻译后，仅会重新翻译使用它的那些文件。

## 另见

- [定义词汇表](/docs/how-to/define-a-glossary): 分步指南。
- [词汇表](/docs/explanation/glossary): 仓库与账户词汇表如何结合。
- [L10N.md 参考](/docs/reference/l10n-md): 其他前置元数据字段。

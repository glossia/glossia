%{
  title: "术语表",
  summary: "术语表字段在 L10N.md 及每个语言的覆盖文件中的参考。",
  category: "参考",
  section: "translation",
  order: 2
}
---
仓库词汇表被拆分到两个文件中。Glossia 会将其与该账户的账户词汇表合并，针对其翻译的每一个文件。详见 [词汇表](/docs/explanation/glossary) 了解两者如何结合。

| 文件 | `glossary` 包含 | 示例 |
|---|---|---|
| `L10N.md` | 一个列表的 **术语**, 每种语言均相同。| `- source: commit` |
| `L10N/<locale>.md` | 一个将术语映射为其 **翻译** 在对应语言中的。 | `commit: commit` |

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

| 字段 | 类型 | 必填 | 描述 |
|---|---|---|---|
| `source` | string | yes | 源文本中出现的术语。|
| `definition` | string | no | 模型读取的简短指导，用于判断匹配是否确实为此概念。|
| `case_sensitive` | boolean | no | 当 `true`, 该术语仅在确切大小写书写时匹配。默认设置为 `false`. 用于名称和首字母缩略词，例如 `API` 或 `SDK`. |
" `id` | string | no | 稳定标识符。源自 `source` 当省略时(`Version Control` 变为 `version-control`, `C++` 变为 `cplusplus`). 将其通过 id 设置为键翻译，以便重命名 `source` 且不失去该术语的身份，或覆盖来自父级的术语 `L10N.md`. |

术语本身不携带翻译。带有一个 `targets` 字段会被拒绝：翻译属于语言文件。

## L10N/中的翻译<locale>.md

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

每个键都是术语的 `id` 或其 `source`，且每个值均为该语言的批准译文。

- 一个不匹配任何术语的键 `L10N.md` 仅声明此语言的术语。
- 若术语在特定语言中无翻译，则回退到该语言的账户术语表。
- 若要保留名称不翻译，请将其映射为自身，例如 `Glossia: Glossia`.

## 嵌套文件

每个文件都使用其目录链中的词典进行翻译：

- 嵌套 `L10N.md` 向其继承的术语添加术语。名称相同的 `id`，或相同的 `source` 当无 `id` 已被设置，将替换该子树中继承的那个值。
- 一个嵌套的 `L10N/<locale>.md` 在其继承的翻译上增加翻译，若对同一术语两者都有声明，则其翻译优先。

## 验证

如果词典无效，Glossia 将仅使用账户词典翻译受影响的文件，因此拼写错误永远不会阻碍翻译。常见原因：

- **缺失 `source`.** 每个术语都需要一个非空值。
- **重复 `id`。** 每个术语必须解析为唯一的标识符，无论是显式设置还是派生自 `source`。
- **L10N.md 中的翻译。** 一个术语的 `targets`。移动翻译到 `L10N/<locale>.md`。
- **空翻译。** 映射为空字符串的术语。建议省略。
- **形状或类型错误。** `glossary` ...中必须是列表 `L10N.md` 以及在...中是一个映射 `L10N/<locale>.md`. 翻译， `id`,以及 `definition` 必须是字符串； `case_sensitive` 必须为 `true` 或 `false`。

## Glossia 记录的内容

每个已翻译文件的锁文件记录了塑造它的术语表条目：

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

- `applied` 列出匹配该文件的条目。仓库条目显示为 `repo:<id>`，账户条目显示为 `account:<id>`。
- `shadowed` 列出此文件中已被仓库条目替换的账户条目。

编辑术语或翻译仅会重新翻译使用该项的文件。

## 另请参阅

- [定义术语表](/docs/how-to/define-a-glossary): 分步指南。
- [术语表](/docs/explanation/glossary): 仓库和账户术语表的组合方式。
- [L10N.md 参考](/docs/reference/l10n-md): 其他前置元数据字段。
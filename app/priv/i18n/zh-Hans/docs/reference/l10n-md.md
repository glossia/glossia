%{title: "L10N.md", summary: "仓库翻译设置和上下文的参考", category: "参考", section: "translation", order: 1}
---
`L10N.md` 告诉 Glossia 要翻译哪些文件、翻译后的文件归哪里、要投放哪些语言、以及应该用什么上下文来指导结果。存储库可以有根文件和子目录中的范围文件。

## 结构

每个文件有两个部分：

1. [YAML Ain't Markup Language](https://yaml.org/) 首后面的注释行，位于 `---` 标记之间。
2. 主内容中的 Markdown，包含产品、受众、声音或领域上下文。

<!-- end list -->

```yaml
---
source_language: en
model: translation-default
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
validation:
  - ./scripts/validate-docs.sh
  - --strict
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Write for software developers. Keep product names and code samples unchanged.
```

 提供商凭据应保存在账户设置中，永远不要保存在 `L10N.md`。可选 `model` 值是账户模型句柄。

## 首字段

| 字段 | 类型 | 必需 | 描述 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 该作用域的来源语言。默认为 `en`。 |
| `model` | 字符串 | 否 | 账户模型句柄。如果不省略，Glossia 将使用账户默认值并在显式句柄不存在时报告错误。 |
| `sources` | 映射或列表 | 顶层规则 | 源文件模式。映射值可以定义输出模板。 |
| `targets` | 映射或列表 | 当配置了源时 | 目标语言代码。映射可以将语言代码与语言名称关联。 |
| `output` | 字符串 | 当没有源映射或 `target_path` 提供目标时 | 输出文件模板。 |
| `target_path` | 字符串 | 当没有源映射或 `output` 提供目标时 | 翻译文件的基础目录模板。 |
| `translate` | 列表 | 否 | 多个翻译规则，每个规则都有自己的源和可选的覆盖项。 |
| `exclude` | 列表 | 否 | 要跳过的文件模式。 |
| `preserve` | 列表 | 否 | 必须保持不变的内容类型，例如占位符或统一资源标识符。 |
| `frontmatter` | 字符串 | 否 | `preserve` 默认值，或 `translate`。 |
| `prompt` | 字符串 | 否 | 该作用域或规则的额外指导。 |
| `validation` | 列表 | 针对没有内置适配器文件扩展名 | 验证命令及其参数。命令在文件实际目标路径处接收候选文件，当文件无效时必须返回非零状态。 |
| `check_cmd` | 字符串 | 否 | 翻译工作流程可用的检查命令。 |
| `check_cmds` | 映射 | 否 | 翻译工作流程可用的命名检查命令。 |
| `retries` | 整数 | 否 | 检查失败后的重试尝试次数。默认为 `2`。 |
| `locale` | 字符串 | 否 | 附加到特定语言上下文文件的语言。 |
| `glossary` | 列表或映射 | 否 | `L10N.md`中，术语列表。在 `L10N/<locale>.md`中，从术语到该语言翻译的映射。嵌套文件添加到覆盖继承的条目。查看 [术语表参考](/docs/reference/glossary)。 |

未知首字段将被忽略。

## 文件格式

对于 Markdown、JavaScript 对象表示法、YAML Ain't Markup Language、便携对象和纯文本文件，Glossia 具有内置处理。其他文件扩展名在 `L10N.md`声明 `validation` 命令之前会失败以满足规划要求。这避免将专有结构化格式无声地处理为不受约束的文本。

在 Markdown 中，仅翻译正文：段落、标题、列表项、表格单元格、`title`、`details`、`alt`、`label`、`description`、`summary`、`placeholder`、`aria-label` 以及 `caption` 组件和 HTML 的属性，以及 HTML `<summary>`\` 文本。所有其他字节，包括代码、链接目标、组件、警报和显式标题锚点，都保留与源相同。参见 [翻译恢复](/docs/explanation/translation-recovery) 了解其工作原理。

验证命令在将候选文件临时写入其真实目标路径后运行。它可以调用仓库的原生解析器、编译器或构建命令。Glossia 会在每次验证尝试后恢复之前的目标文件，并且仅在候选文件被接受后才写入。

## 源映射

最清晰的映射形式将每个源模式映射到一个输出模板：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

源列表也是有效的，但需要 `output` 或 `target_path` 来定义目的地：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 目标语言

列表使用每个区域代码作为其语言标识符：

```yaml
targets:
  - es
  - ja
```

映射可以通过可读语言名称添加描述：

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 输出变量

| 变量 | 值 |
|---|---|
| `{locale}` 或 `{lang}` | 目标区域代码。 |
| `{relpath}` | 相对于匹配模式的源路径。 |
| `{basename}` | 不包含扩展名的源文件名。 |
| `{ext}` | 不包含前导点号的源文件扩展名。 |

## 多重规则

当不同内容组需要不同的目的地或检查时，请使用 `translate`：

```yaml
---
source_language: en
targets:
  - es
translate:
  - sources:
      - "docs/**/*.md"
    output: "docs/i18n/{locale}/{relpath}"
  - source: "messages/*.json"
    output: "messages/{locale}/{basename}.{ext}"
---
```

规则值会覆盖从周围文件继承的值。

## 作用域上下文

Glossia 从仓库根目录向源文件读取 `L10N.md` 文件：

- 父级设置提供默认值。
- 更深层的文件会覆盖其目录的字段。
- Markdown 上下文从父级到子级累积。
- 特定区域的指导内容和特定区域的模型句柄可以存在于 `L10N/<locale>.md` 中。

这使得仓库可以在根目录保持广泛的语气指导，同时将在它所影响的内容附近放置产品区域或特定语言的指导。
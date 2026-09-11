%{title: "L10N.md", summary: "仓库翻译设置和上下文的参考", category: "参考", order: 1}
---
`L10N.md` 告诉 Glossia 要翻译哪些文件、翻译后的文件属于何处、要翻译哪些语言，以及什么上下文应指导结果。存储库可以有一个根文件以及在子目录中的额外分组文件。

## 结构

每个文件有两个部分：

1. [YAML 不是标记语言](https://yaml.org/) 前导头部之间 `---` 标记。
2. 前导头部下方的 Markdown，包含产品、受众、声音或领域上下文。

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

Provider credentials belong in account settings, never in `L10N.md`。可选的 `model` 值是一个账户模型句柄。

## 前导头部字段

| 字段 | 类型 | 必需 | 描述 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此作用域的源语言。默认为 `en`。|
| `model` | 字符串 | 否 | 账户模型句柄。如果省略，Glossia 使用账户默认值，如果显式句柄不存在则报告错误。|
| `sources` | 映射或列表 | 仅顶层规则 | 源文件模式。映射值可以定义输出模板。|
| `targets` | 映射或列表 | 当配置了源时 | 目标语言代码。映射可以将语言代码与语言名称关联。|
| `output` | 字符串 | 当没有源映射或 `target_path` 提供目的地时 | 输出文件模板。|
| `target_path` | 字符串 | 当没有源映射或 `output` 提供目的地时 | 翻译文件的基础目录模板。|
| `translate` | 列表 | 否 | 多个翻译规则，每个规则都有自己的源和可选的覆盖。|
| `exclude` | 列表 | 否 | 要跳过的文件模式。|
| `preserve` | 列表 | 否 | 必须保持不变的內容类型，例如占位符或统一资源标识符。|
| `frontmatter` | 字符串 | 否 | `preserve`（默认值）或 `translate`。|
| `prompt` | 字符串 | 否 | 此范围或规则的额外指导。|
| `validation` | 列表 | 针对没有内置适配器的文件扩展名 | 验证命令及其参数。该命令将接收候选项在其真实目标路径，并且在文件无效时必须返回非零状态。|
| `check_cmd` | 字符串 | 否 | 翻译工作流可用的检查命令。|
| `check_cmds` | 映射 | 否 | 翻译工作流可用的命名检查命令。|
| `retries` | 整数 | 否 | 检查失败后的重试次数。默认为 `2`。|
| `locale` | 字符串 | 否 | 附加到特定语言上下文文件的语言环境。|

未知的前导头部字段将被忽略。

## 文件格式

Glossia 内置支持 Markdown、JavaScript 对象表示法、YAML 不是标记语言、可移植对象以及纯文本文件。其他文件扩展名除非适用的 `L10N.md` 声明了 `validation` 命令，否则将失败。这避免了静默地将专有结构化格式视为无约束文本。

验证命令在候选项临时写入其真实目标路径后运行。它可以调用存储库的原生解析器、编译器或构建命令。Glossia 在每次验证尝试后还原先前的目标，仅在验证后才写入接受的候选项。

## 源映射

最清晰的形式是将每个源模式映射到输出模板：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

源列表也是有效的，但它需要 `output` 或 `target_path` 来定义目的地：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 目标语言

列表使用每个区域（locale）代码作为其语言标识符：

```yaml
targets:
  - es
  - ja
```

映射可以为语言添加可读名称：

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## 输出变量

| 变量 | 变量值 |
|---|---|
| `{locale}` 或 `{lang}` | 目标区域（locale）代码。 |
| `{relpath}` | 相对于匹配模式的路径。 |
| `{basename}` | 不带扩展名的源文件名。 |
| `{ext}` | 不带前导点的源文件扩展名。 |

## 多条规则

当不同的内容组需要不同的目的地或检查时使用 `translate`：

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

Glossia 从仓库根目录读取直至源文件的 `L10N.md` 文件：

- 父级设置提供默认值。
- 更深层的文件会覆盖其目录的字段。
- Markdown 上下文从父级累积到子级。
- 特定语言的指导和特定语言的模型处理器可以存在于 `L10N/<locale>.md` 中。

这使得仓库可以在根目录保持广泛的语调指导，同时将对影响其内容的相关产品领域或特定语言的指导放置在附近。
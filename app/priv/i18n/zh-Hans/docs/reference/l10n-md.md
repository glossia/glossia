%{title: "L10N.md", summary: "仓库翻译设置与上下文参考。", category: "参考", order: 1}
---
`L10N.md` 告诉 Glossia 要翻译哪些文件、翻译后的文件存放在何处、目标语言是什么，以及什么上下文应指导结果。仓库可以有一个根文件和子目录中的额外范围文件。

## 结构

每个文件包含两个部分：

1. [YAML](https://yaml.org/) 中的 `---` 标记之间的前置元数据。
2. 前置元数据下方的 Markdown，其中包含产品、受众、语气或领域上下文。

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

提供商凭据属于账户设置，绝不能在 `L10N.md` 中。可选的 `model` 值为一个账户模型句柄。

## 前置元信息字段

| 字段 | 类型 | 必需 | 描述 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此作用域的区域设置 (源)。默认为 `en`。 |
| `model` | 字符串 | 否 | 账户模型句柄。Glossia 在省略时会使用账户默认值，当显式句柄不存在时会报告错误。 |
| `sources` | 映射或列表 | 适用于顶层规则 | 源文件模式。映射值可以定义输出模板。 |
| `targets` | 映射或列表 | 当配置了源时 | 目标区域设置代码。映射可以将区域设置代码与语言名称关联。 |
| `output` | 字符串 | 当没有源映射或 `target_path` 提供目的地时 | 输出文件模板。 |
| `target_path` | 字符串 | 当没有源映射或 `output` 提供目的地时 | 翻译文件的基目录模板。 |
| `translate` | 列表 | 否 | 多个翻译规则，每个都有各自的源和可选的覆盖值。 |
| `exclude` | 列表 | 否 | 要跳过的文件模式。 |
| `preserve` | 列表 | 否 | 必须保留不变的内容类型，例如占位符或统一资源定位符。 |
| `frontmatter` | 字符串 | 否 | 默认为 `preserve` 或 `translate`。 |
| `prompt` | 字符串 | 否 | 此作用域或规则的额外指导。 |
| `validation` | 列表 | 当文件扩展名没有内置适配器时 | 验证命令及其参数。命令会在其真实目标路径处接收到候选文件，如果文件无效则必须返回非零状态。 |
| `check_cmd` | 字符串 | 否 | 翻译工作流可用的检查命令。 |
| `check_cmds` | 映射 | 否 | 翻译工作流可用的命名检查命令。 |
| `retries` | 整数 | 否 | 检查失败后的重试尝试次数。默认为 `2`。 |
| `locale` | 字符串 | 否 | 附加到特定语言上下文文件的区域设置。 |

未知的前置元信息字段将被忽略。

## 文件格式

Glossia 为 Markdown、JavaScript 对象标记、YAML、便携式对象和纯文本文件提供内置支持。除非适用的 `L10N.md` 声明了 `validation` 命令，否则其他文件扩展名将无法规划。这避免了将专有结构化格式静默视为无约束文本。

验证命令在候选文件临时写入其真实目标路径后运行。它可以调用仓库的原生解析器、编译器或构建命令。Glossia 会在每次验证尝试后恢复之前的目标，仅随后写入被接受的候选文件。

## 源映射

最清晰的形式将每个源模式映射到输出模板：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

源列表同样有效，但需要 `output` 或 `target_path` 来定义目的地：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 目标语言

列表将每个区域代码用作其语言标识符：

```yaml
targets:
  - es
  - ja
```

映射可以添加可读的语言名称：

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
| `{basename}` | 不带扩展名的源文件名。 |
| `{ext}` | 不带前导点的源文件扩展名。 |

## 多重规则

当需要为不同的内容组指定不同的目的地或检查时，使用 `translate`：

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
- Markdown 上下文从父级向子级累积。
- 特定区域的指南和特定区域的处理程序可以存储在 `L10N/<locale>.md` 中。

这使得仓库可以在根目录保留广泛的语气指南，同时将适用于特定产品区域或特定语言的内容指南放置在靠近受影响内容的位置。
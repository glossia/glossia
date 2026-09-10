%{title: "L10N.md", summary: "仓库翻译设置和上下文参考。", category: "参考", order: 1}
---
`L10N.md` 告诉 Glossia 要翻译哪些文件、翻译文件的归属位置、要面向哪些语言以及什么上下文应指导结果。存储库可以有一个根文件和子目录中的附加限定范围文件。

## 结构

每个文件有两个部分：

1. [YAML Ain't Markup Language](https://yaml.org/) 的前置元数据，位于 `---` 标记之间。
2. 前置元数据下方的 Markdown，包含产品、受众、语气或领域上下文。

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

提供商凭证应放在账户设置中，绝不能放在 `L10N.md` 中。可选的 `model` 值是账户模型句柄。

## 前置元数据字段

| 字段 | 类型 | 必填 | 描述 |
|---|---|---|---|
| `source_language` | string | 否 | 此范围的源区域。默认为 `en`。 |
| `model` | string | 否 | 账户模型句柄。省略时 Glossia 使用账户默认值，当显式句柄不存在时报告错误。 |
| `sources` | 映射或列表 | 针对顶级规则 | 源文件模式。映射值可定义输出模板。 |
| `targets` | 映射或列表 | 当配置源时 | 目标区域代码。映射可以将区域代码与语言名称关联。 |
| `output` | string | 当没有源映射或 `target_path` 未提供目的地时 | 输出文件模板。 |
| `target_path` | string | 当没有源映射或 `output` 未提供目的地时 | 翻译文件的基础目录模板。 |
| `translate` | 列表 | 否 | 多个翻译规则，每个规则有其自己的源和可选的重置。 |
| `exclude` | 列表 | 否 | 要跳过的文件模式。 |
| `preserve` | 列表 | 否 | 必须保持不变的内容类型，例如占位符或统一资源定位器。 |
| `frontmatter` | string | 否 | `preserve` 默认，或 `translate`。 |
| `prompt` | string | 否 | 对此范围或规则的额外指导。 |
| `validation` | 列表 | 针对没有内置适配器的文件扩展名 | 验证命令及其参数。命令会通过传递给候选者的实际目标路径接收候选者，并且必须在文件无效时返回非零状态。 |
| `check_cmd` | string | 否 | 翻译流程可用的检查命令。 |
| `check_cmds` | 映射 | 否 | 翻译流程可用的命名检查命令。 |
| `retries` | integer | 否 | 检查失败后的重试次数。默认为 `2`。 |
| `locale` | string | 否 | 附加于特定区域上下文文件的区域。 |

未知的前置元数据字段将被忽略。

## 文件格式

Glossia 内置支持处理 Markdown、JavaScript 对象表示法、YAML Ain't Markup Language、可移植对象和纯文本文件。除非适用的 `L10N.md` 声明了一个 `validation` 命令，否则其他文件扩展名会在规划阶段失败。这避免了将专有结构化格式静默视为不受约束的文本。

验证命令在候选者被临时写入其实际目标路径后运行。它可以调用存储库的原生解析器、编译器或构建命令。Glossia 在每次验证尝试后都会恢复之前的目标路径，并且仅在此后写入接受的候选者。

## 源映射

最清晰的模式是将每个源模式映射到一个输出模板：

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
| `{relpath}` | 匹配模式中的源路径（相对路径）。 |
| `{basename}` | 不带扩展名的源文件名。 |
| `{ext}` | 不带前导点的源文件扩展名。 |

## 多条规则

当不同的内容组需要不同的目的地或检查时，使用 `translate`：

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

Glossia 从存储库根目录向源文件读取 `L10N.md` 文件：

- 父级设置提供默认值。
- 更深层的文件会覆盖其目录的字段。
- Markdown 上下文从父级向子级累积。
- 特定区域的指南和特定区域的模型处理器可以存在于 `L10N/<locale>.md` 中。

这让存储库能够在根目录保留广泛的语调指南，同时将产品区域或特定语言相关的指南放置在受其影响的内容附近。
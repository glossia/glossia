%{title: "L10N.md", summary: "仓库翻译设置和上下文的参考。", category: "参考", order: 1}
---
`L10N.md` 告诉 Glossia 要翻译哪些文件、翻译后的文件属于何处、目标语言是什么，以及什么背景应该指导结果。仓库可以有一个根文件和子目录中的附加范围文件。

## 结构

每个文件由两部分组成：

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter 位于 `---` 标记之间。
2. 位于 frontmatter 下方的 Markdown，包含产品、受众、语气或领域背景。

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

提供者凭证应放在账户设置中，绝不要放在 `L10N.md` 中。可选的 `model` 值是账户模型句柄。

## Frontmatter 字段

| 字段 | 类型 | 必需 | 说明 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此作用域的源语言区域标识符。默认为 `en`。 |
| `model` | 字符串 | 否 | 账户模型句柄。如果省略，Glossia 使用账户默认设置；如果没有显式句柄存在，则报告错误。 |
| `sources` | 映射或列表 | 顶层规则 | 源文件模式。映射值可以定义输出模板。 |
| `targets` | 映射或列表 | 当配置源时 | 目标语言标识符。映射可以将语言代码与语言名称关联。 |
| `output` | 字符串 | 当没有源映射或 `target_path` 提供目的地时 | 输出文件模板。 |
| `target_path` | 字符串 | 当没有源映射或 `output` 提供目的地时 | 翻译文件的基本目录模板。 |
| `translate` | 列表 | 否 | 多个翻译规则，每个都有自己的源和可选覆盖。 |
| `exclude` | 列表 | 否 | 要跳过的文件模式。 |
| `preserve` | 列表 | 否 | 必须保持不变的内容类型，如占位符或统一资源定位符。 |
| `frontmatter` | 字符串 | 否 | 默认为 `preserve`，或 `translate`。 |
| `prompt` | 字符串 | 否 | 此作用域或规则的额外指导。 |
| `validation` | 列表 | 对于没有内置适配器的文件扩展名 | 验证命令及其参数。当文件无效时，该命令必须返回非零状态。 |
| `check_cmd` | 字符串 | 否 | 翻译工作流可用的检查命令。 |
| `check_cmds` | 映射 | 否 | 翻译工作流可用的命名检查命令。 |
| `retries` | 整数 | 否 | 检查失败后的重试尝试次数。默认为 `2`。 |
| `locale` | 字符串 | 否 | 附加到特定语言上下文文件的语言区域标识符。 |

未知的 frontmatter 字段将被忽略。

## 文件格式

Glossia 内置支持 Markdown、JavaScript 对象表示法、YAML Ain't Markup Language、便携式对象和纯文本文件。除非适用的 `L10N.md` 声明了 `validation` 命令，否则其他文件扩展名将导致规划失败。这避免了静默地将专有结构化格式视为不受约束的文本。

验证命令在候选文件被临时写入其真实目标路径后运行。它可以调用存储库的原生解析器、编译器或构建命令。每次验证尝试后，Glossia 都会恢复之前的目标，并仅在此后写入被接受的候选文件。

## 源映射

最直接的形式是将每个源模式映射到输出模板：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

源列表也是有意义的，但它需要 `output` 或 `target_path` 来定义目的地：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 目标语言

列表使用每个区域代码作为语言标识符：

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

| Variable | Value |
|---|---|
| `{locale}` 或 `{lang}` | 目标区域代码。 |
| `{relpath}` | 相对于匹配模式的源路径。 |
| `{basename}` | 不包含其扩展名的源文件名。 |
| `{ext}` | 不带前导句点的源文件扩展名。 |

## 多重规则

使用 `translate` 当不同的内容组需要不同的目标位置或检查时：

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
- 更深层级的文件会覆盖其目录下的字段。
- Markdown 上下文从父级累积到子级。
- 特定区域的指导以及特定区域的模型处理器可以存储在 `L10N/<locale>.md` 中。

这使得仓库能够在根目录保持广泛的语调指导，同时将产品区域或特定语言的指导放置在受影响的最近内容旁边。
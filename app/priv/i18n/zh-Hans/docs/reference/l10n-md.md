%{title: "L10N.md", summary: "仓库翻译设置及上下文参考。", category: "参考", section: "translation", order: 1}
---

`L10N.md` 告诉 Glossia 哪些文件需要翻译、翻译后的文件存放位置、目标语言是什么以及什么上下文应该引导结果。仓库可以包含一个根文件及子目录中的附加范围文件。

## 结构

每个文件包含两个部分：

1. [YAML 并非标记语言](https://yaml.org/) 前置文档位于 `---` 标记之间。
2. 前置文档下方的 Markdown 包含产品、受众、语调或领域上下文。

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

提供者凭证应属于账户设置，绝不出现在 `L10N.md` 中。可选的 `model` 值是一个账户模型句柄。

## 前置文档字段

| 字段 | 类型 | 必填 | 描述 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此范围的源语言代码。默认为 `en`。 |
| `model` | 字符串 | 否 | 账户模型句柄。若省略，Glossia 会使用账户默认值；若显式句柄不存在，则报告错误。 |
| `sources` | 映射或列表 | 针对顶级规则 | 源文件模式。映射值可以定义输出模板。 |
| `targets` | 映射或列表 | 当配置了源时 | 目标语言代码。映射可以将语言代码与语言名称关联。 |
| `output` | 字符串 | 当没有源映射或 `target_path` 提供目的地时 | 输出文件模板。 |
| `target_path` | 字符串 | 当没有源映射或 `output` 提供目的地时 | 翻译文件的根目录模板。 |
| `translate` | 列表 | 否 | 多个翻译规则，每个规则拥有自己的源文件和可选覆盖。 |
| `exclude` | 列表 | 否 | 要跳过的文件模式。 |
| `preserve` | 列表 | 否 | 必须保持不变的内容类型，例如占位符或统一资源定位符。 |
| `frontmatter` | 字符串 | 否 | `preserve` 默认，或 `translate`。 |
| `prompt` | 字符串 | 否 | 此范围或规则的附加指导。 |
| `validation` | 列表 | 针对没有内置适配器的文件扩展名 | 一个验证命令后跟其参数。命令将在候选对象于真实目标路径处接收，当文件无效时必须返回非零状态。 |
| `check_cmd` | 字符串 | 否 | 翻译工作流程可用的检查命令。 |
| `check_cmds` | 映射 | 否 | 翻译工作流程可用的命名检查命令。 |
| `retries` | 整数 | 否 | 检查失败后的重试尝试次数。默认为 `2`。 |
| `locale` | 字符串 | 否 | 附加到特定于区域上下文的文件的区域代码。 |
| `glossary` | 列表或映射 | 否 | 在 `L10N.md` 中，是术语表术语列表。在 `L10N/<locale>.md` 中，是从每个术语到该语言翻译的映射。嵌套文件会累加并覆盖继承的条目。参见 [术语表参考](/docs/reference/glossary)。 |

未知的前置文档字段将被忽略。

## 文件格式

Glossia 对 Markdown、JavaScript 对象记法、YAML 并非标记语言、便携对象和纯文本文件提供内置处理。其他文件扩展名除非适用的 `L10N.md` 声明了 `validation` 命令，否则无法规划。这避免了将专有结构化格式静默地视为不受约束的文本。

在 Markdown 中，仅翻译正文：段落、标题、列表项、表格单元格、组件和 HTML 的 `title`、`details`、`alt`、`label`、`description`、`summary`、`placeholder`、`aria-label` 以及 `caption` 属性，以及 HTML `<summary>` 的文本。其余所有字节，包括代码、链接目标、组件、警报和明确的标题锚点，都完全保持与源一致。请查看 [翻译恢复](/docs/explanation/translation-recovery) 了解其工作原理。

验证命令在候选内容临时写入其真实目标路径后运行。它可以调用仓库的原生解析器、编译器或构建命令。Glossia 会在每次验证尝试后恢复之前的目标，并仅随后写入接受后的候选内容。

## 源映射

最清晰的形式将所有源模式映射到输出模板：

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

列表使用每个区域代码作为其语言标识符：

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

规则的值会覆盖从周围文件继承的值。

## 作用域上下文

Glossia 从存储库根目录向源文件读取 `L10N.md` 文件：

- 父级设置提供默认值。
- 更深级的文件覆盖其目录的字段。
- Markdown 上下文从父级到子级累加。
- 特定于区域的指南和特定于区域的模型句柄可以存在于 `L10N/<locale>.md` 中。

这让存储库能够在根目录保持广泛的语气指南，同时将针对产品领域或语言的指南放置在其影响的内容附近。

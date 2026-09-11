%{title: "L10N.md", summary: "仓库翻译设置与上下文参考", category: "参考", order: 1}
---
`L10N.md` 指定 Glossia 要翻译哪些文件、翻译后的文件位置、目标语言以及指导结果的上下文。仓库可以有一个根文件和子目录中的额外范围文件。

## 结构

每个文件包含两部分：

1. [YAML Ain't Markup Language](https://yaml.org/) 前端数据 between `---` 标记。
2.  前端数据下方的 Markdown，包含产品、受众、语音或领域上下文。

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

 提供商凭证应存放在账户设置中，绝不存放在 `L10N.md` 中。可选的 `model` 值是账户模型句柄。

## 前置数据字段

| 字段 | 类型 | 必需 | 描述 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此范围的源地区语言代码。默认为 `en`。 |
| `model` | 字符串 | 否 | 账户模型句柄。Glossia 在省略此项时使用账户默认值，当显式句柄不存在时报错。 |
| `sources` | 映射或列表 | 顶层规则 | 源文件模式。映射值可以定义输出模板。 |
| `targets` | 映射或列表 | 配置来源时 | 目标地区语言代码。映射可以将地区代码关联到语言名称。 |
| `output` | 字符串 | 无来源映射或 `target_path` 提供目标时 | 输出文件模板。 |
| `target_path` | 字符串 | 无来源映射或 `output` 提供目标时 | 翻译文件的基础目录模板。 |
| `translate` | 列表 | 否 | 多个翻译规则，每个规则都有自己的来源和可选的覆盖设置。 |
| `exclude` | 列表 | 否 | 要跳过的文件模式。 |
| `preserve` | 列表 | 否 | 必须保持不变的內容类型，例如占位符或统一资源定位符。 |
| `frontmatter` | 字符串 | 否 | `preserve` 默认，或 `translate`。 |
| `prompt` | 字符串 | 否 | 此范围或规则的额外指导。 |
| `validation` | 列表 | 没有内置适配器的文件格式时 | 验证命令及其参数。该命令在真实目标路径处接收候选文件，并在文件无效时返回非零状态代码。 |
| `check_cmd` | 字符串 | 否 | 翻译工作流可用的检查命令。 |
| `check_cmds` | 映射 | 否 | 翻译工作流可用的命名检查命令。 |
| `retries` | 整数 | 否 | 检查失败后的重试尝试次数。默认为 `2`。 |
| `locale` | 字符串 | 否 | 附加到特定区域语言上下文文件的区域语言代码。 |

未知的前置数据字段将被忽略。

## 文件格式

Glossia 内置支持 Markdown、JavaScript 对象表示法、YAML Ain't Markup Language、便携式对象和纯文本文件。除非适用的 `L10N.md` 声明了一个 `validation` 命令，否则其他文件扩展名将导致计划失败。这避免了将专有的结构化格式静默地视为不受约束的文本。

验证命令在候选文件临时写入其真实目标路径后运行。它可以调用仓库的原生解析器、编译器或构建命令。Glossia 在每次验证尝试后恢复之前的目标，并且仅在随后写入通过验证的候选文件。

## 来源映射

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
| `{basename}` | 源文件名但不包括扩展名。 |
| `{ext}` | 源文件扩展名，不包括前导点。 |

## 多重规则

使用 `translate`，当不同的内容组需要不同的目标位置或检查：

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

Glossia 从仓库根目录向外读取 `L10N.md` 文件直到源文件：

- 父级设置提供默认值。
- 更深层的文件会覆盖其目录对应的字段。
- Markdown 上下文从父级向子级累积。
- 特定区域的指南和特定区域的模型处理程序可以位于 `L10N/<locale>.md`.

这使得仓库可以在根目录保留广泛的指南，同时将特定功能区域或特定语言的指南放置在受影响内容的位置。
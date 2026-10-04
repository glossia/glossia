%{title: "L10N.md", summary: "仓库翻译设置和上下文的参考。", category: "参考", section: "translation", order: 1}
---
`L10N.md` 告诉 Glossia 要翻译哪些文件、生成的文件存放位置、目标语言以及应该遵循的上下文内容。仓库可以有一个根文件，以及子目录中的其他限定作用域文件。

##  结构 

每个文件包含两部分：

1. [YAML Ain't Markup Language](https://yaml.org/) 位于 `---` 标记之间的前置头部。
2. 位于前置头部下方、包含产品、受众、语气或领域上下文的 Markdown

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

 提供商凭据属于账户设置，绝不`L10N.md`中的内容。`model`的可选值是一个账户模型句柄。

## 前端头部字段

| 字段 | 类型 | 必填 | 描述 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此作用域的来源语言环境。默认为 `en`。 |
| `model` | 字符串 | 否 | 账户模型句柄（handle）。Glossia 在省略时会使用账户默认值，当存在未存在的显式句柄时会报错。 |
| `sources` | 映射或列表 | 用于顶级规则 | 源文件模式。映射值可以定义输出模板。 |
| `targets` | 映射或列表 | 当 sources 配置时 | 目标语言环境代码。映射可以将语言环境代码与语言名称关联。 |
| `output` | 字符串 | 当无源映射或 `target_path`指定目标时 | 输出文件模板。 |
| `target_path` | 字符串 | 当无源映射或 `output`指定目标时 | 已翻译文件的基础目录模板。 |
| `translate` | 列表 | 否 | 多个翻译规则，每个都有独立的源和可选覆盖。 |
| `exclude` | 列表 | 否 | 跳过的文件模式。 |
| `preserve` | 列表 | 否 | 内容类型，必须保持不变，例如占位符或统一资源标识符。 |
| `frontmatter` | 字符串 | 否 | `preserve`默认，或 `translate`。 |
| `prompt` | 字符串 | 否 | 为此作用域或规则提供的额外指导。 |
| `validation` | 列表 | 对于没有内置适配器的文件扩展名 | 验证命令及其参数。该命令在真实目标路径接收候选文件，当文件无效时必须返回非零状态。 |
| `check_cmd` | 字符串 | 否 | 翻译工作流可用的检查命令。 |
| `check_cmds` | 映射 | 否 | 翻译工作流可用的命名检查命令。 |
| `retries` | 整数 | 否 | 检查失败后的重试次数。默认为 `2`。 |
| `locale` | 字符串 | 否 | 附加到特定语言环境上下文文件的语言环境。 |
| `glossary` | 列表或映射 | 否 | 在 `L10N.md`中，术语列表。在 `L10N/<locale>.md`中，将每个术语映射到该语言中的翻译。嵌套文件会添加并覆盖继承的条目。参见 [术语表参考](/docs/reference/glossary)。 |

未知的头部字段将被忽略。

## 文件格式

Glossia 内置地处理 Markdown、JavaScript 对象表示法、YAML Ain't Markup Language、可移植对象和纯文本文件。除非 `L10N.md`中声明了 `validation`命令，否则其他文件扩展名会导致规划失败。这避免了静默地将专有结构化格式视为无约束文本。

验证命令在候选文件临时写入到真实目标路径后运行。它可以调用存储库的原生解析器、编译器或构建命令。每次验证尝试后，Glossia 都会恢复之前的目标，随后只写入已接受的候选文件。

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

列表使用每个区域语言代码作为其语言标识符：

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

如果不同内容组需要不同目的地或检查，请使用时使用 `translate`：

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
- 深层文件覆盖其目录的字段。
- Markdown 上下文从父级到子级累积。
- 区域语言具体指导和区域语言模型处理器可以存在于 `L10N/<locale>.md` 中。

这使得存储库可以在根目录保留广泛的声音指导，同时将产品区域或语言具体指导放置在靠近受影响的文档的位置。
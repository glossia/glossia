%{title: "GLOSSIA.md", summary: "仓库翻译设置与上下文的参考。", category: "参考", order: 1}
---
`GLOSSIA.md` 告诉 Glossia 要翻译哪些文件、翻译后的文件存放位置、目标语言以及结果应受何种上下文指导。仓库可以有一个根文件和子目录中的附加范围文件。

## 结构

每个文件包含两部分：

1. [YAML 不是标记语言](https://yaml.org/) 前导元数据位于 `---` 标记符。
2. 前导元数据下方的 Markdown 内容及其产品、受众、语气或领域上下文。

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

提供商凭证应位于账户设置中，绝不能置于 `GLOSSIA.md`. 可选的 `model` 值是账户模型句柄。

## 前导元数据字段

| 字段 | 类型 | 必需 | 描述 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此作用域的源语言。默认为 `en`. |
| `model` | 字符串 | 否 | 账户模型句柄。Glossia 在省略时使用账户默认值，当显式句柄不存在时报告错误。 |
| `sources` | 映射或列表 | 用于顶级规则 | 源文件模式。映射值可以定义输出模板。 |
| `targets` | 映射或列表 | 当配置源时 | 目标语言代码。映射可以将语言代码与语言名称关联。 |
| `output` | 字符串 | 当没有源映射或 `target_path` 提供目标 | 输出文件模板。|
| `target_path` | string | 当无源映射或 `output` 提供目标 | 翻译文件的基础目录模板。|
| `translate` | list | no | 多个翻译规则，每个带有各自的源及可选的覆盖。|
| `exclude` | list | no | 需跳过的文件模式。|
| `preserve` | list | no | 必须保持不变的内容类型，如占位符或统一资源定位符。|
| `frontmatter` | string | no | `preserve` 默认情况下，或 `translate`. |
| `prompt` | 字符串 | 否 | 此范围或规则的附加指南。 |
| `validation` | 列表 | 针对没有内置适配器的文件扩展名 | 验证命令及其参数。该命令在文件的真实目标路径接收候选项，当文件无效时必须返回非零状态。 |
| `check_cmd` | 字符串 | 否 | 可用于翻译工作流程的检查命令。 |
| `check_cmds` | 映射 | 否 | 可用于翻译工作流程的命名检查命令。 |
| `retries` | 整数 | 否 | 检查失败后的重试次数。默认为 `2`. |
| `locale` | 字符串 | 否 | 与该特定于区域的上下文文件关联的区域设置。 |

未知头部字段将被忽略。

## 文件格式

Glossia 对 Markdown、JavaScript 对象表示法、YAML 非标记语言、可移植对象和纯文本文件提供内置支持。其他文件扩展名无法规划，除非适用的 `GLOSSIA.md` 声明一个 `validation` 命令。这避免静默地将专有结构化格式视为不受约束的文本。

验证命令在将候选项临时写入其真实目标路径后运行。它可以调用存储库的原生解析器、编译器或构建命令。Glossia 在每次验证尝试后恢复之前的目标，并仅在随后写入被接受的候选项。

## 源映射

最清晰的形式将每个源模式映射到输出模板：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

源列表也是有效的，但它需要 `output` 或 `target_path` 用于定义目标：

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

映射可以为语言名称添加可读性：

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

规则值会覆盖从周围文件中继承的值。

## 作用域上下文

Glossia 从仓库根目录向源文件读取 `GLOSSIA.md` 文件：

- 父级设置提供默认值。
- 更深层的文件会覆盖其目录中的字段。
- Markdown 上下文从父级累积到子级。
- 特定区域的指导语言特定区域的模型处理器可以存储在 `GLOSSIA/<locale>.md` 中。

这允许仓库在根目录保留广泛的语气指导，同时将其产品区域或特定语言指导放置在其影响的内容附近。
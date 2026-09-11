%{title: "L10N.md", summary: "仓库翻译设置及上下文参考。", category: "参考", order: 1}
---
`L10N.md` 告诉 Glossia 需要翻译哪些文件、翻译后的文件存放位置、目标语言有哪些以及何种上下文应指导翻译结果。仓库可以包含一个根文件和子目录中的额外限定范围文件。

## 结构

每个文件包含两部分：

1. [YAML Ain't Markup Language](https://yaml.org/) 前置元数据，位于 `---` 标记之间。
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

提供商凭据应位于账户设置中，绝不要放在 `L10N.md` 中。可选的 `model` 值是账户模型句柄。

## 前置元数据字段

| 字段 | 类型 | 必填 | 描述 |
|---|---|---|---|
| `source_language` | string | no | 此范围的源区域。默认为 `en`。 |
| `model` | string | no | 账户模型句柄。如果不省略，Glossia 会报错当明确的句柄不存在时使用账户默认值，省略时使用账户默认值。 |
| `sources` | map 或 list | 顶层规则要求时 | 源文件模式。Map 值可以定义输出模板。 |
| `targets` | map 或 list | 当配置了 sources 时 | 目标区域代码。Map 可以将区域代码与语言名称关联。 |
| `output` | string | 当没有源映射或 `target_path` 有目的地时 | 输出文件模板。 |
| `target_path` | string | 当没有源映射或 `output` 有目的地时 | 翻译文件的基础目录模板。 |
| `translate` | list | no | 多个翻译规则，每个规则都有自己的源和可选的重置。 |
| `exclude` | list | no | 要跳过的文件模式。 |
| `preserve` | list | no | 必须保持不变的内容类型，例如占位符或统一资源定位器。 |
| `frontmatter` | string | no | 默认 `preserve` 或 `translate`。 |
| `prompt` | string | no | 此范围或规则的附加指导。 |
| `validation` | list | 对于没有内置适配器的文件扩展名 | 验证命令及其参数。命令在真实目标路径接收候选文件，条件不满足时返回非零状态。 |
| `check_cmd` | string | no | 可供翻译工作流使用的检查命令。 |
| `check_cmds` | map | no | 可供翻译工作流使用的命名检查命令。 |
| `retries` | integer | no | 失败检查后的重试次数。默认为 `2`。 |
| `locale` | string | no | 附加到特定区域上下文文件的区域。 |

未知的前置元数据字段将被忽略。

## 文件格式

Glossia 内置了对 Markdown、JavaScript 对象表示法、YAML Ain't Markup Language、可移植对象和纯文本文件的支持。除非适用的 `L10N.md` 声明了一个 `validation` 命令，否则其他文件扩展名将在计划时失败。这避免了静默地将专有结构化格式视为不受约束的文本。

验证命令会在候选文件暂时写入真实目标路径后运行。它可以调用仓库的原生解析器、编译器或构建命令。Glossia 会在每次验证尝试后恢复以前的目标，并在之后仅写入经认可的候选文件。

## 源映射

最清晰的形式是将每个源模式映射到输出模板：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

源列表也是有效的，但它需要 `output` 或 `target_path` 来定义目标：

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

映射可以添加可读语言名称：

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

规则值覆盖从周围文件继承的值。

## 范围上下文

Glossia 从仓库根目录向源文件读取 `L10N.md` 文件：

- 父级设置提供默认值。
- 更深层的文件覆盖其目录的字段。
- Markdown 上下文从父级到子级累积。
- 特定区域的指导和特定区域的模型处理器可以存在于 `L10N/<locale>.md` 中。

这使得仓库可以在根目录保留广泛的语调指导，同时将特定于产品领域或语言的指导置于接近受影响内容的位置。
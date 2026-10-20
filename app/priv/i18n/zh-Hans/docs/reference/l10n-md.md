%{title: "L10N.md", summary: "仓库翻译设置和上下文的参考", category: "参考", section: "translation", order: 1}
---

`L10N.md` 告诉 Glossia 哪些文件需要翻译，翻译后的文件存放位置，目标语言以及什么上下文应指导生成的结果。仓库可以有一个根文件以及在子目录中的额外限定范围文件。

## 结构

每个文件有两个部分：

1. [YAML Ain't Markup Language](https://yaml.org/) 前脚标位于 `---` 标记之间。
2. 前脚标下方的 Markdown 包含产品、受众、声音或领域上下文。

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

提供程序凭据应存放在账户设置中，绝不能存放在 `L10N.md` 中。可选的 `model` 值是账户模型句柄。

## 前脚标字段

| 字段 | 类型 | 必需 | 描述 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此范围的基础语言。默认值为 `en`。 |
| `model` | 字符串 | 否 | 账户模型句柄。Glossia 在省略时使用账户默认值，当显式句柄不存在时会报告错误。 |
| `sources` | 映射或列表 | 用于顶级规则 | 源文件模式。映射值可以定义输出模板。 |
| `targets` | 映射或列表 | 当源已配置时 | 目标区域代码。映射可以将区域代码与语言名称关联。 |
| `output` | 字符串 | 当没有源映射或 `target_path` 提供目的地 | 输出文件模板。 |
| `target_path` | 字符串 | 当没有源映射或 `output` 提供目的地 | 翻译文件的基目录模板。 |
| `translate` | 列表 | 否 | 多个翻译规则，每个都有自己的源和可选覆盖范围。 |
| `exclude` | 列表 | 否 | 要跳过的文件模式。 |
| `preserve` | 列表 | 否 | 必须保持不变的内容类型，如占位符或统一资源定位符。 |
| `frontmatter` | 字符串 | 否 | `preserve` 保持默认，或 `translate`。 |
| `prompt` | 字符串 | 否 | 对此范围或规则的额外指导。 |
| `validation` | 列表 | 适用于没有内置适配器的文件扩展名。 | 验证命令后跟随其参数。该命令在真实目标路径接收候选文件，且当文件无效时必须返回非零状态。 |
| `check_cmd` | 字符串 | 否 | 翻译工作流可用的检查命令。 |
| `check_cmds` | 映射 | 否 | 翻译工作流中可用的命名检查命令。 |
| `retries` | 整数 | 否 | 检查失败后的重试次数。默认为 `2`。 |
| `locale` | 字符串 | 否 | 附加到特定区域上下文文件的区域代码。 |
| `glossary` | 列表或映射 | 否 | 在 `L10N.md` 中，术语列表。在 `L10N/<locale>.md` 中，从每个术语到其在该语言的翻译的映射。嵌套文件会添加并覆盖继承的条目。请参见 [术语表参考](/docs/reference/glossary)。 |

未知的前脚标字段将被忽略。

## 文件格式

Glossia 内置支持 Markdown、JavaScript 对象表示法、YAML Ain't Markup Language、可移植对象和纯文本文件。除非适用的 `L10N.md` 声明了 `validation` 命令，否则其他文件扩展名将无法通过规划。这避免了将专有结构化格式静默地视为不受约束的文本。

在 Markdown 中，仅翻译正文：段落、标题、列表项、表格单元格、组件和 HTML 的 `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, 和 `caption` 属性，以及 HTML `<summary>` 的文本。包括代码、链接目标、组件、警告和显式标题锚点在内的所有其他字节都保持与源文件完全相同。有关此工作原理，请查阅 [翻译恢复](/docs/explanation/translation-recovery)。

验证命令在候选文件被临时写入真实目标路径后运行。它可以调用仓库的原生解析器、编译器或构建命令。Glossia 在每次验证尝试后会恢复先前的目标，仅随后写入被接受的候选文件。

## 源映射

最清晰的形式将每个源模式映射到输出模板：

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

列表会将每个区域代码作为其语言标识符：

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
| `{basename}` | 不包含扩展名的源文件名。 |
| `{ext}` | 不含前导点（.）的源文件扩展名。 |

## 多条规则

使用 `translate` 处理不同内容组需要不同目的地或检查的情况：

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

规则值会覆盖继承自周围文件的值。

## 作用域上下文

Glossia 从仓库根目录向源文件方向读取 `L10N.md` 文件：

- 父级设置提供默认值。
- 更深层的文件会覆盖其所在目录的字段设置。
- Markdown 上下文从父级累积到子级。
- 区域特定指南和区域特定模型令牌可以存在于 `L10N/<locale>.md` 中。

这使仓库能够在根目录保持广泛的语音指南，同时将产品区域或语言特定指南放置在受其影响的靠近内容处。

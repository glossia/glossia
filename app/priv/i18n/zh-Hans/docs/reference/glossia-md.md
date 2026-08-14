%{
  title: "GLOSSIA.md",
  summary: "仓库翻译设置和上下文参考。",
  category: "reference",
  order: 1
}
---
`GLOSSIA.md` 用于告知 Glossia 要翻译哪些文件、翻译后的文件应存放在哪里、目标语言有哪些，以及应使用哪些上下文指导翻译。仓库可以包含一个根文件，并可在子目录中包含其他限定作用域的文件。

## 结构

每个文件由两部分组成：

1. 位于 `---` 标记之间的 [YAML Ain't Markup Language](https://yaml.org/) 前置元数据。
2. 前置元数据下方以 Markdown 编写的产品、受众、表达风格或领域上下文。

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

提供商凭据应存放在账户设置中，绝不能存放在 `GLOSSIA.md` 中。可选的 `model` 值是账户模型句柄。

## 前置元数据字段

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此作用域的源语言区域。默认为 `en`。 |
| `model` | 字符串 | 否 | 账户模型句柄。省略时，Glossia 使用账户默认模型；如果显式指定的句柄不存在，则会报告错误。 |
| `sources` | 映射或列表 | 顶层规则必填 | 源文件模式。映射值可以定义输出模板。 |
| `targets` | 映射或列表 | 配置源文件时必填 | 目标语言区域代码。映射可以将语言区域代码与语言名称关联。 |
| `output` | 字符串 | 没有源文件映射或 `target_path` 未提供目标位置时必填 | 输出文件模板。 |
| `target_path` | 字符串 | 没有源文件映射或 `output` 未提供目标位置时必填 | 翻译文件的基础目录模板。 |
| `translate` | 列表 | 否 | 多条翻译规则，每条规则都有自己的源文件和可选覆盖项。 |
| `exclude` | 列表 | 否 | 要跳过的文件模式。 |
| `preserve` | 列表 | 否 | 必须保持不变的内容类型，例如占位符或统一资源定位符。 |
| `frontmatter` | 字符串 | 否 | 默认为 `preserve`，也可以是 `translate`。 |
| `prompt` | 字符串 | 否 | 此作用域或规则的额外指导。 |
| `validation` | 列表 | 没有内置适配器的文件扩展名必填 | 验证命令及其参数。命令会接收位于实际目标路径的候选文件，并且必须在文件无效时返回非零状态。 |
| `check_cmd` | 字符串 | 否 | 可供翻译工作流使用的检查命令。 |
| `check_cmds` | 映射 | 否 | 可供翻译工作流使用的具名检查命令。 |
| `retries` | 整数 | 否 | 检查失败后的重试次数。默认为 `2`。 |
| `locale` | 字符串 | 否 | 与特定语言区域上下文文件关联的语言区域。 |

未知的前置元数据字段会被忽略。

## 文件格式

Glossia 内置支持 Markdown、JavaScript Object Notation、YAML Ain't Markup Language、可移植对象和纯文本文件。对于其他文件扩展名，如果适用的 `GLOSSIA.md` 未声明 `validation` 命令，规划将会失败。这样可以避免将专有结构化格式悄然作为不受约束的文本处理。

候选文件暂时写入其实际目标路径后，验证命令会运行。该命令可以调用仓库的原生解析器、编译器或构建命令。Glossia 会在每次验证尝试后恢复此前的目标文件，并且仅在候选文件通过验证后才将其写入。

## 源文件映射

最清晰的形式是将每个源文件模式映射到一个输出模板：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

源列表同样有效，但需要使用 `output` 或 `target_path` 定义目标位置：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 目标语言

列表使用各语言区域代码作为其语言标识符：

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
| `{locale}` 或 `{lang}` | 目标语言区域代码。 |
| `{relpath}` | 相对于匹配模式的源路径。 |
| `{basename}` | 不含扩展名的源文件名。 |
| `{ext}` | 不含前导点的源文件扩展名。 |

## 多条规则

当不同内容组需要不同的目标位置或检查时，请使用 `translate`：

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

规则值会覆盖从外围文件继承的值。

## 作用域上下文

Glossia 从仓库根目录开始，沿路径向源文件读取 `GLOSSIA.md` 文件：

- 父级设置提供默认值。
- 更深层级的文件会覆盖其所在目录的字段。
- Markdown 上下文从父级到子级逐层累积。
- 特定语言区域的指南和模型标识符可以放在 `GLOSSIA/<locale>.md` 中。

这样，仓库可以在根目录保留通用的语调指南，同时将特定产品领域或语言的指南放在靠近其所影响内容的位置。
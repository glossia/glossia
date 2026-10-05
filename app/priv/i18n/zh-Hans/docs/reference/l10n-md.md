%{title: "L10N.md", summary: "仓库翻译设置和上下文的参考。", category: "参考", section: "translation", order: 1}
---
`L10N.md` 告诉 Glossia 需要翻译哪些文件、翻译后的文件存放何处、目标语言是什么，以及什么上下文应指导结果。存储库可以有一个根文件，以及子目录中的额外范围化文件。

## 结构

每个文件包含两部分：

1. [YAML 并非标记语言](https://yaml.org/) 首信息介于 `---` 标记符。
2. 首信息下方的 Markdown 包含产品、受众、声音或领域上下文。

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

提供商凭证应存放在账户设置中，切勿在 `L10N.md`. 可选的 `model` 值为账户模型句柄。

## 元数据字段

| 字段 | 类型 | 必需 | 描述 |
|---|---|---|---|
| `source_language` | 字符串 | 否 | 此作用域的源语言。默认为 `en`. |
| `model` | string | 无 | 账户模型句柄。Glossia 在省略时使用账户默认值，当显式句柄不存在时报告错误。|
| `sources` | map or list | 顶层规则时 | 源文件模式。Map 值可定义输出模板。|
| `targets` | string | 配置源时 | 目标语言代码。映射可将语言代码与语言名称关联。|
| `output` | string | 当无源映射或 `target_path` 指定目标 | 输出文件模板。 |
| `target_path` | 字符串 | 当没有源映射或 `output` 指定目标 | 翻译文件的基目录模板。 |
| `translate` | 列表 | 无 | 多个翻译规则，每个拥有自己的源和可选的覆盖选项。 |
| `exclude` | 列表 | 无 | 需要跳过的文件模式。 |
| `preserve` | list | 否 | 必须保持不变的内容种类，例如占位符或统一资源定位符。 |
| `frontmatter` | string | 否 | `preserve` 默认情况下，或 `translate`。 |
| `prompt` | string | 否 | 此范围或规则的附加指导。 |
| `validation` | 列表 | 用于没有内置适配器的文件扩展名 | 验证命令及其参数。命令在真实目标路径中接收候选项，当文件无效时必须返回非零状态。 |
| `check_cmd` | 字符串 | 否 | 翻译工作流可用的检查命令。 |
| `check_cmds` | 映射 | 否 | 翻译工作流可用的命名检查命令。 |
| `retries` | 整数 | 否 | 失败检查后的重试次数。默认为 `2`. |
| `locale` | 字符串 | 否 | 附加到特定区域上下文的区域。 |
| `glossary` | 列表或映射 | 否 | 在 `L10N.md`, 术语列表。在 `L10N/<locale>.md`, 来自每个术语到该语言翻译的映射。嵌套文件将添加并覆盖继承的条目。请参见 [术语表参考](/docs/reference/glossary). |

忽略未知的前置元数据字段。

## 文件格式

Glossia 内置了对 Markdown、JavaScript 对象表示法、YAML Ain't Markup Language、便携式对象和纯文本文件的处理能力。其他文件扩展名无法规划，除非适用的 `L10N.md` 声明一个 `validation` 命令。这避免了将专有的结构化格式默认为无约束的文本。

验证命令会在候选内容被临时写入其实际目标路径后运行。它可以调用仓库的原生解析器、编译器或构建命令。每次验证尝试后，Glossia 都会恢复之前的目标，随后才写入被接受的候选内容。

## 源映射

最清晰的形式将每个源模式映射到输出模板：

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

源列表也是有效的，但它需要`output`或`target_path`来定义目标：

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## 目标语言

列表使用每个区域代码作为语言标识：

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
|`{locale}`或`{lang}` | 目标区域代码。
|`{relpath}` | 源文件相对于匹配模式的相对路径。
|`{basename}` | 不包含扩展名的源文件名。
|`{ext}` | 不带前导点的源文件扩展名。

## 多条规则

使用`translate`当不同内容组需要不同的目的地或检查时：

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

## 作用域上下文

Glossia 读取`L10N.md`文件，从存储库根目录向源文件方向读取：

- 父设置提供默认值。
- 更深层的文件覆盖其目录的字段。
- Markdown 上下文从父级累积到子级。
- 特定区域的指导信息和该区域特定的模型处理器可以位于`L10N/<locale>.md`.

这让存储库能够在根目录保留广泛的语气指导，同时将特定产品区域或特定语言指导靠近受影响的代码放置。
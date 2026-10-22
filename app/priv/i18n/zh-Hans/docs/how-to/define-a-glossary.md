%{
  title: "定义术语表",
  summary: "在 L10N.md 中声明术语，并在各语言的覆盖文件中声明其经批准的译文。",
  category: "教程",
  section: "translation",
  order: 6
}
---

您的团队已经有了必须以特定方式翻译的术语：以英文保留的产品名称、有首选呈现方式的技术术语、承载特定语气风格的品牌词汇。在您的仓库中声明它们，Glossia 就会将它们应用到所有未来的翻译中。

术语表和两种类型的文件 연관在一起。

- `L10N.md` 声明 **terms**：单词是什么以及它的含义。这对于每种语言都是一样的。
- `L10N/<locale>.md` 声明 **translations** 给一种语言。每种语言的审阅者拥有自己的文件。

如果您的账户在 Glossia 中也有术语表时，两个在翻译时合并。查看 [Glossary](/docs/explanation/glossary) 了解规则以及与 [when to use which](/docs/explanation/glossary#when-to-use-which)。

## 1. 在 L10N.md 中声明术语

在根 `L10N.md` 的 frontmatter 中添加一个 `glossary` list：

```yaml
---
source_language: en
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
---

Write for software developers.
```

每个术语需要一个 `source`，您文本中出现的单词。一个 `definition` 帮助模型决定是否匹配确实是您要的概念。`case_sensitive: true` 使 `API` 匹配而不匹配文字中的 "api"。

## 2. 在每种语言的文件中翻译

创建或打开 `L10N/<locale>.md` 在您的 `L10N.md` 旁边，并将每个术语映射到其批准的翻译：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
---
```

```yaml
# L10N/ja.md
---
locale: ja
glossary:
  commit: コミット
  API: API
---
```

键是术语的 `source`。没有术语翻译的语言会回退到账户术语表，或让模型选择。

## 3. 添加一个只有某个语言需要的术语

语言文件可以翻译 `L10N.md` 未声明的单词。然后该规则只适用于该语言：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. 给术语一个稳定的 id

当相同单词需要精确含义，或您想稍后重命名术语的 `source`，给它一个 `id` 并通过该 id 键其翻译：

```yaml
# L10N.md
glossary:
  - id: vcs-branch
    source: branch
    definition: A line of development in version control, not a company branch office.
```

```yaml
# L10N/es.md
glossary:
  vcs-branch: rama
```

## 5. 为仓库部分细化术语表

嵌套 `L10N.md` 或 `L10N/<locale>.md` 从父目录继承并可以为它的子树添加或覆盖条目：

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

在 `marketing/` 下的西班牙语文件将 "commit" 翻译为 `compromiso`；仓库的其他部分保留 `commit`。

## 6. 提交并推送

提交更改并推送。在下一次翻译运行时，Glossia 仅重新翻译使用您添加或更改术语的文件，在翻译发生变化的语言中。不包含这些术语的文件保留其现有翻译。

如果术语表有错误，Glossia 会忽略受影响文件中的仓库术语表，仅使用账户术语表，因此当术语似乎不适用时，检查 [validation rules](/docs/reference/glossary#validation)。

## See also

- [Glossary reference](/docs/reference/glossary)：每个字段和验证规则。
- [Glossary](/docs/explanation/glossary)：仓库和账户术语表如何合并。
- [L10N.md reference](/docs/reference/l10n-md)：其他 frontmatter 字段。

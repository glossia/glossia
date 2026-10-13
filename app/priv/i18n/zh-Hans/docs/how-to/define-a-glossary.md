%{
  title: "定义术语表",
  summary: "在 L10N.md 中声明术语，并在每种语言的覆盖文件中声明其已批准的翻译。",
  category: "教程",
  section: "translation",
  order: 6
}
---

你的团队已经有了必须按特定方式翻译的术语：保留英文的产品名称、有首选短语的技术术语、传递特定基调的品牌词汇。在仓库中声明它们，Glossia 会将其应用于所有未来的翻译。

词汇表存在于两种你已使用的文件中：

- `L10N.md` 声明了 **术语**：这个词是什么以及它的含义。这对每一种语言都相同。
- `L10N/<locale>.md` 声明了 **翻译**，用于一种语言。每种语言审查人员拥有自己的文件。

如果你的账户在 Glossia 中也拥有词汇表，两者在翻译时会合并。参见 [词汇表](/docs/explanation/glossary) 了解规则，以及 [何时使用哪个](/docs/explanation/glossary#when-to-use-which)。

## 1. 在 L10N.md 中声明术语

在你的根 `L10N.md` 的 frontmatter 中添加一个 `glossary` 列表：

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

每个术语需要一个 `source`，即文本中出现的单词。一个 `definition` 帮助模型决定匹配是否真的是你想要的概念。`case_sensitive: true` 使 `API` 匹配而不匹配叙述中的 "api"。

## 2. 在每种语言的文件中翻译它们

创建或打开 `L10N/<locale>.md` 放在你的 `L10N.md` 旁边，并将每个术语映射到其批准的翻译：

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

键是术语的 `source`。对于某个术语没有翻译的语言，将回退到账户词汇表，或让模型选择。

## 3. 添加仅一种语言需要的术语

语言文件可以翻译 `L10N.md` 未声明的单词。此时规则仅适用于该语言：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. 为术语赋予稳定的 id

当同一个单词需要确切含义，或你想稍后重命名术语的 `source` 时，给它一个 `id` 并以其为键来索引其翻译：

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

## 5. 为仓库部分细化词汇表

嵌套的 `L10N.md` 或 `L10N/<locale>.md` 继承自其父目录，并可以为其子树添加或覆盖条目：

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

位于 `marketing/` 下的西班牙语文件将 "commit" 翻译为 `compromiso`；仓库其余部分保留 `commit`。

## 6. 提交并推送

提交更改并推送。在下一次翻译运行时，Glossia 仅重新翻译使用了你添加或更改的术语的文件（在翻译发生更改的语言中）。不包含这些术语的文件保留其现有翻译。

如果词汇表有错误，Glossia 会忽略受影响文件的仓库词汇表，仅使用账户词汇表，因此当一个术语似乎不适用时，请检查 [验证规则](/docs/reference/glossary#validation)。

## 另请参阅

- [词汇表参考](/docs/reference/glossary)：每个字段和验证规则。
- [词汇表](/docs/explanation/glossary)：仓库和账户词汇表如何合并。
- [L10N.md 参考](/docs/reference/l10n-md)：其他 frontmatter 字段。

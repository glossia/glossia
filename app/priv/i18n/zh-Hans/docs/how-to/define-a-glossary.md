%{
  title: "定义术语表",
  summary: "在 L10N.md 中声明术语，并在每种语言的覆盖文件中声明其经批准的翻译。",
  category: "教程",
  section: "translation",
  order: 6
}
---

您的团队已存在一些必须以特定方式翻译的术语：保持在英语中的产品名称、有首选渲染方式的技术术语、以及带有特定语气的品牌用语。在您的仓库中声明它们，Glossia 将它们应用于所有未来的翻译。

A glossary lives in two kinds of files you already use:

- `L10N.md` 声明 **术语**：单词是什么以及它的含义。这对每一种语言都是一样的。
- `L10N/<locale>.md` 声明某一种语言的 **翻译**。每种语言的审阅者拥有他们自己的文件。

如果您的账户在 Glossia 中也有一个词汇表，这两个词汇表将在翻译时合并。请参阅 [词汇表](/docs/explanation/glossary) 了解规则，以及 [何时使用哪一个](/docs/explanation/glossary#when-to-use-which)。

## 1. 在 L10N.md 中声明术语

在根 `L10N.md` 的前言中添加一个 `glossary` 列表：

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

每个术语需要一个 `source`，即您在文本中看到的单词。一个 `definition` 帮助模型判断匹配是否确实是您所指的概念。`case_sensitive: true` 使 `API` 匹配而不匹配正文中的 "api"。

## 2. 在每种语言的文件中翻译它们

在您的 `L10N.md` 旁边创建或打开 `L10N/<locale>.md`，并将每个术语映射到其批准的翻译：

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

键是该术语的 `source`。没有术语翻译的语言会回退到账户词汇表，或由模型选择。

## 3. 添加仅一种语言需要的术语

语言文件可以翻译 `L10N.md` 未声明的单词。则该规则仅适用于该语言：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. 给术语分配一个稳定的 id

当同一个词需要精确含义，或者稍后想重命名术语的 `source`，给它一个 `id`，并按该 id 键入其翻译：

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

## 5. 针对仓库的部分内容细化词汇表

嵌套的 `L10N.md` 或 `L10N/<locale>.md` 继承自其父目录，并可以为子树添加或覆盖条目：

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

提交更改并推送。在下一次翻译运行中，Glossia 仅重新翻译那些使用您添加或更改的术语的文件，仅限于翻译发生更改的语言。不包含那些术语的文件保留其现有翻译。

如果词汇表有错误，Glossia 将忽略受影响文件的仓库词汇表，仅使用账户词汇表，因此当某个术语似乎不适用时，请检查 [验证规则](/docs/reference/glossary#validation)。

## 另请参阅

- [词汇表参考](/docs/reference/glossary)：所有字段和验证规则。
- [词汇表](/docs/explanation/glossary)：仓库和账户词汇表如何结合。
- [L10N.md 参考](/docs/reference/l10n-md)：其他 frontmatter 字段。

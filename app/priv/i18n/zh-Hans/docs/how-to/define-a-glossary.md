%{
  title: "定义术语表",
  summary: "在 L10N.md 中声明术语，并在各语言覆盖文件中声明其经批准的译文。",
  category: "教程",
  section: "translation",
  order: 6
}
---
您的团队已有一些必须按特定方式翻译的术语：保留英文的产品名称、具有首选呈现方式的技术术语，以及传达特定基调的品牌词汇。请在仓库中声明这些术语，Glossia 会将它们应用于所有后续翻译。

术语库存在于两种您已使用的文件格式中：

- `L10N.md` 声明 **术语**：即该词是什么以及含义为何。这对每种语言都适用。
- `L10N/<locale>.md` 声明 **翻译** 对应一种语言。每种语言的审查员都拥有各自的文件。

如果您的账户也在 Glossia 中有术语表，两者会在翻译时合并。请参阅 [术语表](/docs/explanation/glossary) 了解规则以及 [何时使用哪一个](/docs/explanation/glossary#when-to-use-which)。

## 1\. 在 L10N.md 中声明术语

添加一个 `glossary` 列表到您的根目录的前置元数据中 `L10N.md`:

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

每个术语需要一个 `source`，即您的文本中出现的单词。A `definition` 有助于模型判断匹配是否真的是您所指的概念。 `case_sensitive: true` 使 `API` 在不匹配"api"的情况下进行匹配。

## 2\. 在每种语言的文件中翻译它们

创建或打开 `L10N/<locale>.md` 就在你的 `L10N.md` 并将每个术语映射到其批准的翻译：

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

键是术语的 `source`。若某语言没有该术语的翻译，则回退到账户词典，或由模型选择。

## 3\. 添加仅需一种语言的术语

语言文件可以翻译一个单词，其 `L10N.md` 未声明。该规则仅适用于该语言：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. 为术语分配一个稳定的标识

当同一词汇需要确切含义，或你想重命名术语的 `source` 之后，为其指定一个 `id` 并依据该 ID 为其翻译设定键值：

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

## 5\. 为仓库的一部分细化术语表

一个嵌套的 `L10N.md` 或 `L10N/<locale>.md` 继承自其父目录并可为其子树添加或覆盖条目：

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

其下的西班牙语文件 `marketing/` 将 "commit" 翻译为 `compromiso`；仓库其余部分保持 `commit`。

## 6\. 提交并推送

提交更改并推送。在下一次翻译运行时，Glossia 仅会重新翻译使用了您添加或更改术语的文件，仅限于翻译已更改的语言。未包含这些术语的文件将保留现有翻译。

如果术语表有误，Glossia 将忽略受影响文件的仓库术语表，仅使用账户术语表，因此请检查 [验证规则](/docs/reference/glossary#validation) 当术语似乎不适用时。

## 另请参阅

- [术语表参考](/docs/reference/glossary)：每个字段和验证规则。
- [术语表](/docs/explanation/glossary)：仓库和账户术语表如何结合。
- [L10N.md 参考](/docs/reference/l10n-md)：其他 frontmatter 字段。
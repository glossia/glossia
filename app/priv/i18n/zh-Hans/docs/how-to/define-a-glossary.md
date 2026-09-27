%{
  title: "定义术语表",
  summary: "在 L10N.md 中声明术语，并在各语言的覆盖文件中注明其已批准的翻译。",
  category: "指南",
  section: "翻译",
  order: 6
}
---
您的团队已有一些需要按特定方式翻译的术语：保留英文的产品名称、具有首选呈现形式的技术术语、以及带有特定品牌调性的词汇。请在您的仓库中声明它们，Glossia 会将它们应用到所有未来的翻译中。

术语表存在于您已使用的两种文件类型中：

- `L10N.md` 声明 **术语**：该词指代什么及其含义。这对每种语言都相同。
- `L10N/<locale>.md` 声明 **翻译** 对应一种语言。每种语言的审核人员都拥有各自的文件。

如果您的账户在服务器上也有术语表，两者将在翻译时合并。参见 [术语表](/docs/explanation/glossary) 的规则以及 [何时使用哪个](/docs/explanation/glossary#when-to-use-which).

## 1\. 在 L10N.md 中声明术语

添加一个 `glossary` 列表到根目录的头部元数据中 `L10N.md`：

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

每个术语需要一个 `source`, 您在文本中出现的该词。它 `definition` 有助于模型判断匹配项是否确实为您所指的概念。 `case_sensitive: true` 使 `API` 匹配时不匹配文段中的 "api"。

## 2\. 在每种语言的文件中翻译它们

创建或打开 `L10N/<locale>.md` 位于你的 `L10N.md` 并映射每个术语到其批准译文：

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

键是术语的 `source`。对于缺少术语翻译的语言，系统将回退至服务器术语表，或由模型选择。

## 3\. 添加仅有一种语言需要的术语

语言文件可以翻译一个单词 `L10N.md` 未声明。该规则仅适用于该语言：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. 为术语分配一个稳定的 ID

当同一词汇需要精确含义，或想要重命名某个术语的 `source` 稍后，为其指定一个 `id` 并以该 id 作为其翻译的键：

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

一个嵌套的 `L10N.md` 或 `L10N/<locale>.md` 可继承自其父目录，并可为其子树中的条目添加或覆盖：

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

下方的西班牙语文件 `marketing/` 将 "commit" 翻译为 `compromiso`；仓库的其余部分保留 `commit`.

## 6\. 提交并推送

提交更改并推送。在下一次翻译运行时，Glossia 仅会重新翻译使用了您添加或更改的术语的文件，且仅限于翻译发生变化的语言。未包含这些术语的文件保留其现有的翻译。

如果词汇表有误，Glossia 将忽略受影响文件的仓库词汇表，仅使用服务器词汇表，请检查 [验证规则](/docs/reference/glossary#validation) 当术语似乎不适用时。

## 另请参阅

- [术语表参考](/docs/reference/glossary): 每个字段及其验证规则。
- [术语表](/docs/explanation/glossary): 仓库和服务器术语表如何结合。
- [L10N.md 参考](/docs/reference/l10n-md): 其他头部信息字段。
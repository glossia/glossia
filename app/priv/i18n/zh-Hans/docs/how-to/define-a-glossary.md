%{
  title: "定义术语表",
  summary: "在 L10N.md 中声明术语，并在各语言覆盖文件中声明其经批准的译文。",
  category: "教程",
  section: "translation",
  order: 6
}
---
您的团队已有必须按特定方式处理的术语：保留英文的产品名称、带有指定呈现形式的技术术语、以及带有特定基调的品牌词汇。在您的仓库中声明它们，Glossia 会将其应用于每一次未来的翻译。

词汇表存在于您已使用的两种类型的文件中：

- `L10N.md` 声明 **术语**：该词是什么及其含义。这对每种语言都是一样的。
- `L10N/<locale>.md` 声明 **译文** 用于一种语言。每种语言的审核者负责各自的文件。

如果您的账户在 Glossia 中也包含术语表，这两者会在翻译时合并。参见 [术语表](/docs/explanation/glossary) 关于规则以及 [何时使用哪种](/docs/explanation/glossary#when-to-use-which)。

## 1\. 在 L10N.md 中声明术语

添加一个 `glossary` 为根的 frontmatter 添加一个列表 `L10N.md`：

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

每个词条需要一个 `source`，文本中出现的该单词。该 `definition` 有助于模型判定匹配是否确实为你所指的概念。 `case_sensitive: true` 使 `API` 匹配时忽略正文中的 "api"。

## 2\. 在每种语言的文件中翻译它们

创建或打开 `L10N/<locale>.md` 紧邻你的 `L10N.md` 并将每个术语映射到其批准的翻译：

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

键是术语的 `source`. 如果某种语言未对术语提供翻译，则回退至账户词典，或交由模型选择。

## 3\. 添加仅需一种语言的术语

语言文件可以翻译一个词 `L10N.md` 未声明。该规则则仅适用于该语言：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. 给术语分配一个稳定 id

当同一单词需要精确含义，或您想重命名术语的 `source` 之后，给它一个 `id` 并根据该 id 为其翻译设键：

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

## 5\. 为仓库的一部分优化术语表

嵌套的 `L10N.md` 或 `L10N/<locale>.md` 从父目录继承，并可为其子树添加或覆盖条目：

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

下的西班牙语文件 `marketing/` 将 "commit" 译为 `compromiso`; 仓库其余部分保持 `commit`。

## 6\. 提交并推送

提交更改并推送。在下一次翻译运行时，Glossia 仅重新翻译使用了您添加或更改的术语的文件，针对翻译已发生变化的语言。不包含这些术语的文件将保留其现有翻译。

如果术语表有误，Glossia 将忽略受影响文件的仓库术语表，仅使用账户术语表，因此请检查 [验证规则](/docs/reference/glossary#validation) 当术语似乎不适用时。

## 另请参阅

- [词汇表参考](/docs/reference/glossary): 每个字段和验证规则。
- [词汇表](/docs/explanation/glossary): 仓库和账户词汇表如何合并。
- [L10N.md 参考](/docs/reference/l10n-md): 其他 frontmatter 字段。
%{
  title: "定义术语表",
  summary: "在 L10N.md 中声明术语，并在各语言覆盖文件中声明其经批准的译文。",
  category: "教程",
  section: "translation",
  order: 6
}
---
您的团队已经存在一些必须以特定方式翻译的术语：保留英文的产品名称、有首选渲染方式的技术术语、以及带有特定基调的品牌词。在您的存储库中声明它们，Glossia 会将这些规则应用到每一次后续的翻译中。

术语表存在于两种您已经使用的文件类型中：

- `L10N.md` 声明 **术语**：词语是什么以及它是什么意思。这对于每种语言都相同。
- `L10N/<locale>.md` 声明针对一种语言的 **翻译**。每种语言的审核人员负责自己的文件。

如果您的账户在 Glossia 中也包含术语表，翻译时会将两者合并。参见 [术语表](/docs/explanation/glossary) 了解规则，以及 [何时使用哪个](/docs/explanation/glossary#when-to-use-which)。

## 在 L10N.md 中声明术语

在您的根 `glossary` 添加到 `L10N.md` 的头部。

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

每个术语需要 `source`，即它在您的文本中显示的字词。 `definition` 帮助模型判断匹配项是否是您所指的概念。 `case_sensitive: true` 使 `API` 匹配，而不会匹配正文中 "api"。

## 在每种语言的文件中翻译 

创建或打开 `L10N/<locale>.md`，放在 `L10N.md` 旁边，并映射每个术语到其批准的翻译：

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

键是术语的 `source`。如果某种语言没有某项术语的翻译，则回退到账户术语表，或让模型选择。

## 添加只有特定语言需要的术语 

语言文件可以翻译 `L10N.md` 未声明的词汇。此时该规则仅适用于该语言：

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 为术语分配稳定 ID 

当同一个词需要精确含义，或者您想以后重命名术语的 `source` 时，给它一个 `id` 并通过该 id 为其翻译键值：

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

## 针对存储库部分细化术语表 

嵌套 `L10N.md` 或 `L10N/<locale>.md` 从父目录继承，可以为子树添加或覆盖条目：

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

administrator 目录下的 `marketing/` 中的西班牙语文件将 "commit" 翻译为 `compromiso`；存储库的其余部分保持 `commit`。

## 提交并推送 

提交更改并推送。在下一次翻译运行时，Glossia 仅会翻译使用了您添加或修改的术语的文件，且仅限于翻译发生变化的语言。不包含这些术语的文件将保留其现有翻译。

如果术语表有错误，Glossia 将仅使用账户术语表而忽略受影响的存储库术语表，因此当某个术语似乎不适用时，请检查 [验证规则](/docs/reference/glossary#validation)。

## 参见 

- [术语表参考](/docs/reference/glossary)：每个字段和验证规则。
- [术语表](/docs/explanation/glossary)：存储库术语表和账户术语表如何组合。
- [L10N.md 参考 ](/docs/reference/l10n-md)：其他 frontmatter 字段。
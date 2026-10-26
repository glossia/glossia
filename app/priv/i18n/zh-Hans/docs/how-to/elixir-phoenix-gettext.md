%{
  title: "Elixir 和 Phoenix (Gettext)",
  summary: "配置 Gettext 翻译，保留目录元数据，并减少合并冲突。",
  category: "教程",
  section: "ecosystems",
  order: 1
}
---

使用本指南通过 [Gettext](https://hexdocs.pm/gettext/) 将现有的 Elixir 或 Phoenix 应用程序连接到 Glossia，并保持其目录便于合并。从包含 `mix.exs` 的目录运行 Mix 命令。

## 1. 配置确定性提取

将这些选项添加到您在 `project/0` 中的现有 `mix.exs` 配置：

```elixir
def project do
  [
    # Keep the application's other project options here.
    gettext: [
      write_reference_line_numbers: false,
      sort_by_msgid: :case_sensitive
    ]
  ]
end
```

保留您已使用的其他 Gettext 选项。`sort_by_msgid: :case_sensitive` 由 Glossia 使用的 Gettext 版本支持；将此应用于其他项目时，请检查您的依赖项的 [提取选项](https://hexdocs.pm/gettext/Mix.Tasks.Gettext.Extract.html)。

重新生成模板和本地化文件：

```sh
mix gettext.extract --merge
```

将该一次性归一化与措辞更改分开审查并提交。消息排序应更改，而非现有翻译。将此归一化与开放的拉取请求协调，以便它们的目录可以更新为相同的顺序。

排序将独立的新消息放置在其标准位置，而不是将每次添加都追加到文件末尾。省略引用行号可避免代码移动时产生无关的差异；源文件引用保留。这些选项减少了冲突，但无法消除同一消息的冲突，也无法保证每对插入都能自动合并。

## 2. 翻译模板，而非应用程序源代码

在 `mix.exs` 旁创建 `L10N.md`，或将其以下映射添加到您的现有配置：

```yaml
---
source_language: en
sources:
  "priv/gettext/default.pot": "priv/gettext/{locale}/LC_MESSAGES"
  "priv/gettext/errors.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
---

Translate user-facing messages naturally and preserve all Gettext metadata.
Keep interpolation placeholders unchanged, including their names and syntax.
```

仅包含应用程序中存在的域。为每个额外域添加映射，例如 `dashboard_projects.pot`。目标是一个目录：可移植对象处理程序将 `default.po`、`errors.po` 和其他匹配的域文件名写入该处。

使用 `.pot` 模板作为来源，将本地化 `.po` 文件作为输出。不要使用一个已翻译的本地化作为其他本地化的来源。查看 [L10N.md 参考](/docs/reference/l10n-md) 以了解嵌套配置，并通过 [入门教程](/docs/tutorials/getting-started) 将仓库连接到 Glossia。

## 3. 发布源更改前提取

当拉取请求更改 `gettext`，`dgettext` 或 `ngettext` 调用时：

1. 更新应用程序代码。
2. 运行 `mix gettext.extract --merge`。
3. 连同代码更改一起审查模板和本地化差异。
4. 在合并拉取请求之前提交生成的更改。

源更改合并后，Glossia 翻译更新的模板，并通过翻译拉取请求发布本地化更改。通过仓库的正常流程审查这些翻译。

保持 `msgid` 和 `msgctxt` 作为源标识符。翻译 `msgstr` 值，包括所需的复数变体。保留内插占位符、复数形式标题、源引用、翻译者注释和标志。一个 `fuzzy` 条目需要审查：仅为了使检查通过而不要移除标志，也不要假设其之前的翻译对更改后的消息是正确的。

## 4. 在 CI 中验证目录更动

运行：

```sh
mix gettext.extract --merge --check-up-to-date
mix compile --warnings-as-errors
```

提取检查可捕获不再与应用程序源匹配的模板或本地化文件。编译检查 Gettext 是否可以编译目录。这两个命令都不验证语言质量或证明每条消息都有经过审查的翻译。

如果提取报告过时文件，请在本地重新生成，审查差异并提交。不要绕过检查或在翻译工作员中重复重写模板以掩盖源不匹配。

## 5. 通过消息标识解决目录冲突

当从默认分支更新分支时：

1. 首先解决应用程序源冲突，保留预期的 UI 文本。
2. 使用上下文和源消息标识（包括存在的复数标识）调和来自两个分支的目录条目。保留现有翻译、注释、标志和复数形式；在运行解析器之前，移除冲突标记和重复条目。
3. 针对解析后的源运行 `mix gettext.extract --merge`。
4. 运行上述 CI 检查并审查生成的目录差异。

不要通过盲目接受整个侧面、启用文本并集合并驱动程序或连接目录来解决目录冲突。这些方法可能会导致失去有效的翻译、重复标识符或留下无效文件。对于频繁发生的冲突，添加回归测试，该测试在具有不同新消息的两个分支上生成目录，并验证 Git 合并了模板和翻译目录而没有丢失条目。

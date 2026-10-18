# Glossia：为团队提供的语言操作系统

Glossia 将语气、术语、翻译、修订历史和本地化分析整合到单一系统中。它帮助开发人员、语言学家和产品团队无需将内容移出 Git 就在跨语言间保持一致地沟通。

## 问题

在另一种语言中发布不仅仅是替换词汇。团队需要保留含义，使用正确的术语，根据受众调整语气，并在产品变更时保持翻译的时效性。分散在电子表格、提示词和翻译工具中的上下文会导致写作不一致和重复的手动工作。

LLM 可以起草翻译，但仅凭草稿无法提供版本历史、验证、选择性更新或对后续更改的反馈循环。

## Glossia 的角色

- **语言记忆:** 共享的语气指导和词汇表条目帮助人员和代理使用一致的语言。
- **仓库本地化:** 连接仓库，在配置中描述源文件和目标区域，并通过拉取请求审查更改。
- **逐步优化:** 内容哈希帮助避免翻译未更改的内容。验证和恢复使错误变得可见且可操作。
- **内容修订:** 保留语言决策和更改的历史记录，而不是将每次生成视为孤立的提示。
- **本地化分析:** 注重隐私的网页分析帮助团队了解受众，以及值得投资本地化的地方。
- **代理集成:** 经过 OAuth 认证的 MCP 服务器和 REST 接口使语言上下文可用于现有工作流。

Glossia 并不替代编辑判断。它提供上下文、自动化和评审工作流，使团队能够反复应用该判断。

## 探索

- [入门](/docs/tutorials/getting-started.md)：连接仓库并运行第一个本地化工作流。
- [为什么选择 Glossia](/docs/explanation/why-glossia.md)：语言操作系统旨在解决这些问题。
- [功能](/features.md)：产品能力和应用场景。
- [文档](/docs.md)：教程、操作指南、参考资料和说明。
- [博客](/blog.md)：关于本地化和语言系统的写作。
- [更新日志](/changelog.md)：产品变更。
- [源代码](https://github.com/glossia/glossia)：检查实现并进行贡献。

## 对比

- [Glossia 与 Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia 与 Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia 与 Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia 与 Weblate](/docs/explanation/glossia-vs-weblate.md)

## 供爬虫和代理

已发布页面可通过在 URL 后追加 `.md` 获取 Markdown 格式，或通过向 HTML URL 请求 `Accept: text/markdown` 访问。主页的 Markdown URL 为 `/index.md`。翻译内容使用与 HTML 相同的区域前缀，若无翻译则回退至英语。

使用 [/llms.txt](/llms.txt) 进行发现，使用 [/llms-full.txt](/llms-full.txt) 完成文档合并导出，使用 [/sitemap.xml](/sitemap.xml) 获取标准 HTML URL。账户仪表板是应用界面，而非文档；请勿抓取它们以了解关于 Glossia 的信息。

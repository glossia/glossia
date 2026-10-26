# Glossia：为团队打造的语言操作系统

Glossia 将语言风格、术语、翻译、修订历史和本地化分析整合到同一系统中。它帮助开发者、语言学家和产品团队在不将内容移出 Git 的情况下，跨语言沟通并保持内容一致。

## 问题所在

跨语言发行不仅仅是替换单词。团队需要保留原意、使用恰当的术语、调整语调以适应受众，并随产品更新保持翻译的时效性。分散在表格、提示词和翻译工具中的上下文导致写作风格不统一和重复性人工操作。

LLM 可以起草翻译，但草稿本身无法提供版本历史、验证、选择性更新或针对下一次变更的反馈循环。

## Glossia 的角色

- **语言记忆：** 共享的语言风格指导和词条条目帮助人员与代理使用一致的语言。
- **仓库本地化：** 连接仓库，在配置中描述源文件和目标语言环境，并通过拉取请求审查变更。
- **渐进式优化：** 内容哈希有助于避免翻译未更改的内容。验证和恢复使失败可见且可操作。
- **内容修订：** 保留语言决策和变更的历史，而非将每次生成视为孤立的提示词。
- **本地化分析：** 注重隐私的网络分析帮助团队了解受众，以及值得在何处投入资源进行本地化。
- **代理集成：** OAuth 认证的 MCP 服务器和 REST 接口将语言上下文提供给现有的工作流。

Glossia 不取代编辑判断。它提供上下文、自动化和审核工作流，使团队能够重复应用这些判断。

## 探索

- [入门指南](/docs/tutorials/getting-started.md): 连接仓库并运行您的首个本地化工作流。
- [为何选择 Glossia](/docs/explanation/why-glossia.md): 语言操作系统旨在解决的问题。
- [功能](/features.md): 产品功能与应用场景。
- [文档](/docs.md): 教程、指南、参考和说明。
- [博客](/blog.md): 关于本地化和语言系统的文章。
- [更新日志](/changelog.md): 产品变更。
- [源代码](https://github.com/glossia/glossia): 查阅实现细节并贡献代码。

## 对比

- [Glossia 与 Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia 与 Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia 与 Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia 与 Weblate](/docs/explanation/glossia-vs-weblate.md)

## 面向爬虫和代理

发布的页面可通过在其 URL 后追加 `.md` 获取 Markdown 格式，或在 HTML URL 请求 `Accept: text/markdown`。主页的 Markdown URL 为 `/index.md`。翻译内容使用与 HTML 相同的语言环境前缀，若无译文则回退到英语。

使用 [/llms.txt](/llms.txt) 进行发现，[/llms-full.txt](/llms-full.txt) 获取整合的文档导出，以及 [/sitemap.xml](/sitemap.xml) 获取标准 HTML 链接。账户仪表板是应用界面而非文档；请勿爬取它们以了解关于 Glossia 的信息。

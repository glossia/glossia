%{
  title: "公开内容与爬虫接口",
  summary: "公共网站的 HTML、Markdown、发现、缓存及爬虫边界。",
  category: "参考",
  section: "platform",
  order: 10
}
---

Glossia 将已发布的网站内容与账户和项目应用界面分开暴露。

## 表示形式

| 接口 | 行为 |
|---|---|
| 已发布的 HTML URL | 该浏览器的表示形式，带有规范元数据和一个 Markdown 交替 `Link` 响应头。 |
| 在该 URL 处使用 `Accept: text/markdown` | 当显式媒体类型具有正质量且不低于 `text/html` 时，便是 Markdown 表示形式。 |
| 在页面 URL 后附加 `.md` | 显式 Markdown 表示形式，独立于浏览器语言偏好。 |
| `/index.md` | 主页的 Markdown 简介。 |
| `/docs.md`, `/blog.md`, `/features.md` | 已发布内容的 Markdown 索引。 |
| `/changelog.md` | 已发布在单个 Markdown 文档中的更新日志条目。 |
| `/terms.md`, `/privacy.md`, `/cookies.md` | 最新的已发布法律文档。带日期的法律 URL 也支持 `.md`。 |

单独使用 `*/*` 并不能启用 Markdown。HTML 响应和 Markdown 响应共享 `Vary: Accept`，因此缓存不会混合这些表示形式。

单个文档、博客、功能和法律内容使用编写的 Markdown，而不是渲染 HTML 的转换。索引页面从已发布的目录生成；主页拥有精心策划的 Markdown 简介。交互式 REST 参考将读者指向 OpenAPI 规范，而不是嵌入仅浏览器的 API 小部件。

## 区域设置

英文无前缀。本地化营销 URL 使用字面前缀：`/de`、`/es`、`/fr`、`/ja`、`/ko`、`/pt-br` 和 `/zh-hans`。例如，当 `/es/docs/tutorials/getting-started.md` 发布时会提供西班牙语版本。

URL 选择 Markdown 内容的语言。`Accept-Language` 不会重定向 Markdown 请求。缺少内容翻译时会回退到其英文源。主页简介目前是用英文编写的。

## 发现

- `/robots.txt` 默认禁止爬取，并采用有限的已发布 HTML 和 Markdown 目录、本地化订阅源、位于 `/assets/`、`/fonts/` 和 `/images/` 下的渲染资源、网站图标，以及位于 `/og/marketing/` 下的公共营销预览。受 `/og/app/` 下方的账户预览图像保持禁止状态。这是对协作式爬取器的指导，而非授权机制。
- `/sitemap.xml` 列出带有区域性交替版本的规范公共 HTML 内容。更新日志片段不是单独的 URL。
- `/llms.txt` 介绍 Glossia 并链接到公开文档、功能指南和最近的作品，包括显式 Markdown 链接。
- `/llms-full.txt` 将主页简介和完整的文档目录导出到单个包含 Markdown 的文本文档中。

身份验证、账户仪表板、API 和其他应用响应标记为 `noindex, nofollow`。已发布的成功内容标记为 `index, follow`；错误仍不可索引。发现文本文件（`/robots.txt`、`/llms.txt` 和 `/llms-full.txt`）使用 `noindex, follow`：读者可以获取它们并跟随其链接，但搜索引擎应该索引规范页面而非重复的内容导出。

## 缓存和资源使用

Markdown 和文本发现响应包括：

| Header | Value or meaning |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8`，或 `text/plain; charset=utf-8` 用于发现文本。 |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | 引用的 SHA-256 表示形式的摘要。 |
| `X-Markdown-Tokens` | 字符数除以四的粗略估算值，向上取整；不是特定模型的 tokenizer 计数。 |

`If-None-Match` 支持匹配强或弱验证器、多个验证器和 `*`。匹配时会返回 `304` 且不包含正文。`HEAD` 会返回表示形式的头而不包含正文。

已发布的 Markdown 目录已编译到发布版本中。请求不会执行内容翻译、读取源文件、加载已认证的账户或渲染 LiveView。访问这些公共表示形式不需要 User-Agent 伪装。

## 运营边界

Markdown 协商不提供访问账户或项目仪表板。现有的账户浏览速率限制和 Turnstile 检查保持为独立保护。

生产边缘速率限制适用于 `GET` 和 `HEAD`。经验证的爬取器仍然受速率限制。超额请求会收到速率限制响应而非浏览器挑战；读者应稍慢一些并在之后重试。共享缓存和条件请求不能豁免客户端于速率限制之外。

仓库中的爬取器策略变更在应用执行和部署相关的相应基础设施配置后才生效。

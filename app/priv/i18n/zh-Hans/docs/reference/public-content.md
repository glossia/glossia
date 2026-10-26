%{
  title: "公开内容与爬虫接口",
  summary: "公共网站的 HTML、Markdown、发现、缓存及爬虫边界。",
  category: "参考",
  section: "platform",
  order: 10
}
---

Glossia 将发布的网站内容与账户和项目应用界面分开。

## 表现形式

| 接口 | 行为 |
|---|---|
| 已发布的 HTML URL | 浏览器表现形式，附带规范元数据及一个 Markdown 替代 `Link` 响应头。 |
| 该 URL 处的 `Accept: text/markdown` | 当明确媒体类型具有高质量且不低于 `text/html` 时，则为 Markdown 表现形式。 |
| 在页面 URL 后追加 `.md` | 一个显式的 Markdown 表现形式，独立于浏览器语言偏好。 |
| `/index.md` | 主页的 Markdown 概览。 |
| `/docs.md`, `/blog.md`, `/features.md` | 已发布内容的 Markdown 索引。 |
| `/changelog.md` | 单一 Markdown 文档中的已发布公告条目。 |
| `/terms.md`, `/privacy.md`, `/cookies.md` | 最新的已发布法律文档。带日期的法律 URL 也支持 `.md`。 |

仅 `*/*` 无法启用 Markdown。HTML 响应和 Markdown 响应共享 `Vary: Accept`，因此缓存不会混合这些表现形式。

单个文档、博客、功能和法律内容使用作者编写的 Markdown，而非渲染 HTML 的转换。索引页面从已发布库存生成；主页有精选的 Markdown 概览。交互 REST 参考将读者指向 OpenAPI 规范，而非嵌入仅浏览器的 API 小部件。

## 区域

英语无前缀。翻译后的营销 URL 使用字面前缀：`/de`, `/es`, `/fr`, `/ja`, `/ko`, `/pt-br` 和 `/zh-hans`。例如，`/es/docs/tutorials/getting-started.md` 在发布时使用西班牙语版本。

URL 会选择 Markdown 内容的语言。`Accept-Language` 不会重定向 Markdown 请求。缺失的内容翻译回退至英语源。主页概览目前编写为英文。

## 发现

- `/robots.txt` 默认禁止爬取，并允许有限的已发布 HTML 和 Markdown 库存、本地化 Feed、位于 `/assets/`、`/fonts/` 和 `/images/` 下的渲染资产、网页图标，以及位于`/og/marketing/`下的公开营销预览。`/og/app/` 下的账户预览图像保留禁止。这是针对合作爬取器的指南，而非授权机制。
- `/sitemap.xml` 列出规范公开内容及其区域交替变体，包括 Markdown 页面的 Markdown URL。公告片段不是单独的 URL。
- `/llms.txt` 介绍 Glossia 并链接到公开文档、功能指南和近期写作，包括显式 Markdown 链接。
- `/llms-full.txt` 在一个包含 Markdown 的文本文档中导出主页概览、文档及仅 Markdown 的比较内容。

比较内容仅以 Markdown 发布。它不包含在 HTML 文档、导航、搜索和文档索引中，但代理可通过 `/llms.txt` 和站点地图发现它。其规范 URL 以 `.md` 结尾；旧 HTML URL 也响应 `Accept: text/markdown`, 但不再渲染浏览器页面。

身份验证、账户仪表板、API 及其他应用响应标记为 `noindex, nofollow`。已成功发布内容标记为 `index, follow`；错误不可索引。发现文本文件（`/robots.txt`, `/llms.txt` 及`/llms-full.txt`）使用 `noindex, follow`：读者可获取它们并跟随链接，但搜索引擎应索引规范页面而非重复文档转储。

## 缓存与资源使用

Markdown 和文本发现响应包括：

| 标头 | 值或含义 |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8`, 或针对发现文本使用 `text/plain; charset=utf-8`。 |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | 表示的引用 SHA-256 摘要。 |
| `X-Markdown-Tokens` | 字符数除以四的粗略估计，向上取整；非模型特定 tokenizer 计数。 |

`If-None-Match` 支持匹配强或弱验证器、多个验证器及 `*`。匹配返回 `304` 且无正文。`HEAD` 返回表示头且无正文。

已发布 Markdown 库存已编译到版本中。请求不执行内容翻译、读取源文件、加载认证账户或渲染 LiveView。访问这些公开表示无需伪装 User-Agent。

## 操作边界

Markdown 协商不提供访问账户或项目仪表板的权限。现有账户浏览速率限制和 Turnstile 检查保持独立保护。

生产边缘速率限制适用于 `GET` 和 `HEAD`。验证爬取器仍受速率限制。超额请求接收速率限制响应而非浏览器挑战；读者应放慢速度，稍后重试。共享缓存和条件请求不豁免客户端的速率限制。

仓库中爬虫策略变更仅在应用和目标基础设施配置部署后生效。

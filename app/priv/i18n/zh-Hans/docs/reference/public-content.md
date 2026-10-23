%{
  title: "公开内容和爬虫接口",
  summary: "公开网站的 HTML、Markdown、发现、缓存及爬虫边界。",
  category: "参考",
  section: "platform",
  order: 10
}
---

Glossia 将发布的网站内容与账户和项目应用界面分开暴露。

## 表现形式

| 接口 | 行为 |
|---|---|
| 已发布的 HTML URL | 浏览器表现形式，包含规范元数据以及 Markdown 备用 `Link` 响应头。 |
| `Accept: text/markdown` 在该 URL 处 | 当显式媒体类型具有正质量且不低于 `text/html` 时，为 Markdown 表现形式。 |
| 带有 `.md` 附加的页面 URL | 显式 Markdown 表现形式，不受浏览器语言偏好影响。 |
| `/index.md` | 主页的 Markdown 概览。 |
| `/docs.md`, `/blog.md`, `/features.md` | 已发布内容的 Markdown 索引。 |
| `/changelog.md` | 在单个 Markdown 文档中的已发布变更日志条目。 |
| `/terms.md`, `/privacy.md`, `/cookies.md` | 最新的已发布法律文档。带日期的法律 URL 也支持 `.md`。 |

仅 `*/*` 不会启用 Markdown。HTML 响应和 Markdown 响应共享 `Vary: Accept`，以防止缓存混合表现形式。

单独的文档、博客、功能内容使用作者编写的 Markdown，而非渲染 HTML 的转换。索引页面从已发布库存生成；主页有精心制作的 Markdown 概览。交互式 REST 参考将读者指向 OpenAPI 规范，而非嵌入仅限浏览器的 API 小部件。

## 区域设置

英语是未加前缀的。翻译后的营销 URL 使用字面前缀：`/de`、`/es`、`/fr`、`/ja`、`/ko`、`/pt-br` 和 `/zh-hans`。例如，`/es/docs/tutorials/getting-started.md` 在发布时提供西班牙语版本。

URL 选择 Markdown 内容的语言。`Accept-Language` 不会重定向 Markdown 请求。缺失的内容翻译将回退至其英语源。主页概览当前由英语编写。

## 发现

- `/robots.txt` 默认禁止网络爬虫抓取，并收录有限的发布 HTML 和 Markdown 内容清单、本地化资讯流、位于 `/assets/`、`/fonts/` 和 `/images/` 下的渲染资产、网站图标，以及位于 `/og/marketing/` 下的公共营销预览。`/og/app/` 下的账户预览图片仍被禁止。这是协作式爬虫的指南，而非授权机制。
- `/sitemap.xml` 列出包含区域设置的规范公共内容，包括 Markdown 仅页面的 Markdown URL。变更日志片段不是单独的 URL。
- `/llms.txt` 介绍 Glossia 并链接到公共文档、功能指南和最近的文章，包括显式的 Markdown 链接。
- `/llms-full.txt` 在一个包含 Markdown 的文本文档中导出主页概览、文档及 Markdown 仅比较内容。

比较内容仅以 Markdown 发布。它不在 HTML 文档、导航、搜索和文档索引中，但代理可以通过 `/llms.txt` 和站点地图发现它。其规范 URL 以 `.md` 结尾；之前的 HTML URL 也会响应 `Accept: text/markdown`，但不再渲染浏览器页面。

认证、账户仪表板、API 和其他应用响应标记为 `noindex, nofollow`。已发布的成功内容标记为 `index, follow`；错误保持不可索引。发现文本文件（`/robots.txt`, `/llms.txt` 和 `/llms-full.txt`）使用 `noindex, follow`：读者可以获取它们并跟随其链接，但搜索引擎应索引规范页面而非重复的文档转储。

## 缓存与资源使用

Markdown 和文本发现响应包括：

| 头部 | 值或含义 |
|---|---|
| `Content-Type` | `text/markdown; charset=utf-8`，或用于发现文本的 `text/plain; charset=utf-8`。 |
| `Cache-Control` | `public, max-age=300, stale-while-revalidate=60`. |
| `ETag` | 表示的引用 SHA-256 摘要。 |
| `X-Markdown-Tokens` | 字符数除以四的大致估计，向上取整；不是模型特定的分词器计数。 |

`If-None-Match` 支持匹配强验证器或弱验证器、多个验证器及 `*`。匹配返回 `304` 且无主体。`HEAD` 返回表示头且无主体。

已发布的 Markdown 库存已编译到版本构建中。请求不执行内容翻译、读取源文件、加载已认证账户或渲染 LiveView。访问这些公共表示无需假冒 User-Agent。

## 操作边界

Markdown 协商无法访问账户或项目仪表板。现有的账户浏览速率限制和 Turnstile 检查保持作为独立保护。

生产边缘速率限制同时适用于 `GET` 和 `HEAD`。验证过的爬虫仍受速率限制。过量请求收到速率限制响应而非浏览器挑战；读者应放慢速度并稍后重试。共享缓存和条件请求不豁免客户端的速率限制。

存储库中的爬虫策略变更在应用和相关基础设施配置部署后才生效。

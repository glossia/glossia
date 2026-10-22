%{
  title: "分析 SDK",
  summary: "已收集的字段、事件端点，以及 Glossia 网站分析背后的隐私模型。",
  category: "参考",
  section: "analytics",
  order: 1
}
---

## ## 事件端点

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 仍保留用于兼容性。托管脚本从其的身份派生 `/v1/collect`；包集成应显式设置 `endpoint`。

接受来自 `@glossia/web` SDK 的 JSON 事件。始终响应 `202 Accepted`，包括对于未知域名或格式错误的负载，这样 SDK 永远不会泄露哪些项目收集分析。

项目由代码片段声明的站点域解析。`d` 具有权威性；当缺省时，服务器回退到 `u` 的主机（页 URL），然后请求 `Origin`/`Referer`。

### 请求体

| 字段 | 类型   | 描述                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 字符串 | 标识项目的站点域（例如 `example.com`）。由浏览器库发送；回退解析描述如上。 |
| `n`   | 字符串 | 事件名称。默认为 `pageview`。                          |
| `u`   | 字符串 | 页面 URL (`location.href`)。                                  |
| `r`   | 字符串 | 来源 (`document.referrer`)。                              |
| `l`   | 字符串 | 浏览器语言 (`navigator.languages.join(",")`)。         |
| `sl`  | 字符串 | 实际页面语言 (`document.documentElement.lang`)。未声明时为空。 |
| `al`  | 字符串 | 来自 `link[rel="alternate"][hreflang]` 的逗号分隔翻译语言，排除 `x-default`。 |
| `tz`  | 字符串 | IANA 时区 (`Intl.DateTimeFormat().resolvedOptions().timeZone`)。 |
| `sw`  | 数字 | CSS 像素屏幕宽度。                                  |
| `sid` | 字符串 | 每个标签页的会话 ID (sessionStorage，关闭时清除)。       |

CORS 已开启 (`Access-Control-Allow-Origin: *`)，因为端点不接受凭证。

## 服务器派生字段

这些在摄入时计算并存储在服务器端。原始 IP 和用户代理从未存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 项目的每日轮换哈希。跨天不可链接。  |
| `country_code`    | Cloudflare / GeoIP | 来自受信任的 `CF-IPCountry` 头的 ISO 3166-1 alpha-2 代码，或配置的 IP 地理定位适配器。当两者无法解析国家时为空。 |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` 或 `unknown`。                 |
| `browser`         | 用户代理    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 或 `unknown`。       |
| `os`              | 用户代理    | `windows`, `macos`, `ios`, `android`, `linux`, 或 `unknown`。        |
| `hostname`        | 页面 URL      | 小写主机。                                                    |
| `pathname`        | 页面 URL      | 路径组件。                                                     |
| `referrer_source` | 来源      | 来源主机，剥离前导 `www.`/`m.`。                        |
| `browser_language`| 语言     | 最偏好的标准化区域设置（例如 `pt-BR`）。                    |
| `served_locale`   | 页面语言 | 标准化 `sl`，若未收集则为空（显示为未报告）。 |
| `has_locale_gap`  | 计算      | `1` 当访客的首选语言均不匹配项目目标、发布翻译 (`al`) 或页面语言 (`sl`) 时。缺少首选项不计为差异。 |

### 国家解析

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 启用了 `CF-IPCountry` 的快速路径。它是 **默认关闭**。仅在主站验证 Cloudflare、拒绝绕过 Cloudflare 的请求，或入口剥离不信任的标头副本后启用它。Cloudflare 的 IP 地理位置设置也必须为区域启用。`CF-Connecting-IP`, `CF-Ray` 和 nginx 的 `use-forwarded-headers` 无法单独验证请求。

当启用标头信任时，会立即使用单个有效的 ISO 国家代码，无需 IP 查找或访问缓存。当前边缘值始终优先于任何缓存查找。缺失、重复、格式错误或未知的代码（包括 Cloudflare 的 `XX` (未知) 和 `T1` (Tor) 值）将回退到配置的地理定位适配器。

在没有配置 MaxMind 数据库的情况下，回退查找使用 `api.ipapi.is`，然后在主请求失败或返回未识别的国家时使用 `api.country.is`。每个请求具有一秒的连接和响应超时，且禁用重试。任一提供商的成功结果由 Cachex 缓存在 24 小时，具有 100,000 条记录的调度大小限制和自动过期回收。`Cachex.fetch/3` 将同一 IP 的并发请求合并为单个解析器。失败不缓存。私有和保留地址不会发送到任一提供商。

### 缺失页面语言

当事件没有 `sl` 时，仪表盘会显示 **未报告**。这包括由旧版跟踪器版本收集的事件和没有 HTML `lang` 属性的页面。页面语言不是从浏览器首选项或 URL 推断得出的。历史事件保留当时收集的数据；新跟踪器版本不会回填它们。

## 隐私模型

- **无持久跨会话标识符。** SDK 不设置 Cookie，仅在 `sessionStorage` 中存储每个标签页的会话 ID，浏览器关闭时会清除。
- **不收集指纹。** 画布、WebGL、字体和音频指纹不会收集。每日轮换的服务器哈希在无需它们的情况下提供唯一性。
- **不保留原始标识符。** IP 和用户代理被读取一次，使用服务器密钥和每日盐进行哈希，然后丢弃。
- **项目级作用域。** 同一浏览器在两个项目上会产生不相关访客 ID，因此访客无法在 Glossia 客户之间进行跟踪。

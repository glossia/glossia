%{
  title: "分析 SDK",
  summary: "收集的字段、事件端点，以及 Glossia 网页分析背后的隐私模型。",
  category: "参考",
  section: "analytics",
  order: 1
}
---

## 事件端点

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 为兼容性而保留。托管脚本从其自身源派生 `/v1/collect`；包集成应显式设置 `endpoint`。

接收来自 `@glossia/web` SDK 的 JSON 事件。始终返回 `202 Accepted`，包括针对未知域名或格式错误的负载，因此 SDK 永远不会泄露哪些项目收集了分析数据。

项目通过代码片段声明的站点域解析。`d` 具有权威性；当它缺省时，服务器回退到 `u`（页面 URL）的主机名，然后是请求 `Origin`/`Referer`。

### 请求体

| 字段 | 类型   | 描述                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 字符串 | 标识项目的站点域（例如 `example.com`）。由浏览器库发送；回退解析描述请见上文。 |
| `n`   | 字符串 | 事件名称。默认为 `pageview`。                          |
| `u`   | 字符串 | 页面 URL (`location.href`)。                                  |
| `r`   | 字符串 | 引荐来源 (`document.referrer`)。                              |
| `l`   | 字符串 | 浏览器语言 (`navigator.languages.join(",")`)。         |
| `sl`  | 字符串 | 实际页面语言 (`document.documentElement.lang`)。如果未声明则为空。 |
| `al`  | 字符串 | 来自 `link[rel="alternate"][hreflang]` 的逗号分隔翻译语言，排除 `x-default`。 |
| `tz`  | 字符串 | IANA 时区 (`Intl.DateTimeFormat().resolvedOptions().timeZone`)。 |
| `sw`  | 数字 | CSS 像素的屏幕宽度。                                  |
| `sid` | 字符串 | 每个标签页的会话 ID（sessionStorage，关闭时清除）。       |

CORS 已开启 (`Access-Control-Allow-Origin: *`)，因为该端点不接受凭据。

## 服务器派生的字段

这些在数据采集时计算并存储于服务器端。原始 IP 和用户代理从未存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + 用户代理 + 项目的每日轮换哈希。跨天不可关联。  |
| `country_code`    | Cloudflare / GeoIP | 来自可信 `CF-IPCountry` 头的 ISO 3166-1 alpha-2 代码，或配置的 IP 地理定位适配器。当两者均未解析国家时为空。 |
| `device`          | 用户代理    | `desktop`, `mobile`, `tablet`, `bot`, 或 `unknown`。                 |
| `browser`         | 用户代理    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 或 `unknown`。       |
| `os`              | 用户代理    | `windows`, `macos`, `ios`, `android`, `linux`, 或 `unknown`。        |
| `hostname`        | 页面 URL      | 小写主机名。                                                    |
| `pathname`        | 页面 URL      | 路径组件。                                                     |
| `referrer_source` | 引荐来源      | 引荐来源主机，去除开头的 `www.`/`m.`。                        |
| `browser_language`| 语言     | 首选标准化区域标识符（例如 `pt-BR`）。                    |
| `served_locale`   | 页面语言 | 标准化 `sl`，若未收集则留空（显示为未报告）。 |
| `has_locale_gap`  | 计算      | `1` 当访问者的首选语言均不匹配项目目标、翻译语言 (`al`) 或页面语言 (`sl`) 时。缺失偏好不计为缺口。 |

### 客户端 IP 解析

对于来自私有入口对等体的请求，Glossia 使用 nginx 覆盖的 `X-Real-IP` 头，而不是调用方控制的 `X-Forwarded-For` 中的第一项。直接公共连接使用套接字地址。在 Hetzner 上，负载均衡器和 nginx 都必须启用 PROXY 协议，以便 nginx 接收访客地址而不是负载均衡器地址。其他反向代理也必须使用经过身份验证的来源覆盖 `X-Real-IP`，而不是无限制的内联 `X-Forwarded-For` 头。通用图表的转发头策略本身无法保证这一点。私有对等体是可信基础设施，因此限制对 Pod 的直接访问。

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` 允许 `CF-Connecting-IP` 覆盖来自私有入口对等体的请求的标准地址。它默认 **禁用**，独立于国家头信任。仅在边缘验证 Cloudflare 或在绕过 Cloudflare 的请求中剥离伪造头后才启用它。仅限 DNS 的部署应保持禁用。该地址还作为 IP 速率限制和每日访客哈希的密钥。

### 国家解析

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 启用 `CF-IPCountry` 快速路径。它默认 **禁用**。仅在源站验证 Cloudflare、拒绝绕过 Cloudflare 的请求，或入口剥离该头的不受信任副本后启用它。Cloudflare 的 IP 地理定位设置也必须为区域启用。`CF-Connecting-IP`、`CF-Ray` 和 nginx 的 `use-forwarded-headers` 本身不会验证请求。

启用头信任后，立即使用单个有效的 ISO 国家代码，无需 IP 查询或缓存访问。当前边缘值始终优先于任何缓存的查询。缺失、重复、格式错误或未知代码，包括 Cloudflare 的 `XX`（未知）和 `T1`（Tor）值将回退到配置的地理定位适配器。

未配置 MaxMind 数据库时，回退查询会使用 `api.ipapi.is`，然后当主请求失败或返回未识别的国家时使用 `api.country.is`。每个请求有一秒的连接和响应超时，并禁用重试。来自任一提供商的成功结果都被 Cachex 缓存 24 小时，具有 100,000 条记录的预定大小限制和自动过期回收。`Cachex.fetch/3` 将同一 IP 的并发丢失合并为单个解析器。失败不会被缓存。私有和保留地址不会发送到任一提供商。

### 缺失的页面语言

当事件没有 `sl` 时，仪表盘显示 **未报告**。这包括旧版本跟踪器收集的事件和没有 HTML `lang` 属性的页面。页面语言不是从浏览器首选项或 URL 推断的。历史事件保留当时收集的元数据；新跟踪器版本不会回填它们。

## 隐私模型

- **无持久跨会话标识符。** SDK 不设置 Cookie 且仅将每标签页会话 ID 存储在 `sessionStorage` 中，浏览器关闭时会清除。
- **无指纹化。** Canvas、WebGL、字体和音频指纹均不收集。每日轮换的服务器哈希在无需它们的情况下提供唯一性。
- **无原始标识符持久化。** IP 和用户代理仅读取一次，使用服务器秘密和每日盐值进行哈希，然后丢弃。
- **按项目范围。** 同一浏览器在两个项目上会产生不相关的访客 ID，因此访客无法在 Glossia 客户之间追踪。

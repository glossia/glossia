%{
  title: "分析 SDK",
  summary: "收集的字段、事件端点以及 Glossia 网页分析背后的隐私模型。",
  category: "参考",
  section: "analytics",
  order: 1
}
---

## 事件端点

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 仍保留以兼容。托管脚本由其自身源派生 `/v1/collect`; 包集成应显式设置 `endpoint`。

从 `@glossia/web` SDK 接收 JSON 事件。始终响应 `202 Accepted`，包括未知域或畸形负载情况，以便 SDK 永远不会泄露哪些项目收集了分析数据。

项目由代码片段声明的站点域解析。`d` 为权威；当它缺失时，服务器回退到 `u` (页面 URL) 的主机以及请求 `Origin`/`Referer`。

### 请求体

| 字段 | 类型   | 描述                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 字符串 | 标识项目的站点域（例如 `example.com`）。由浏览器库发送；回退解析规则如上所述。 |
| `n`   | 字符串 | 事件名称。默认为 `pageview`。                          |
| `u`   | 字符串 | 页面 URL（`location.href`）。                                  |
| `r`   | 字符串 | 推荐来源（`document.referrer`）。                              |
| `l`   | 字符串 | 浏览器语言（`navigator.languages.join(",")`）。         |
| `sl`  | 字符串 | 实际页面语言（`document.documentElement.lang`）。未声明则为空。 |
| `al`  | 字符串 | 来自 `link[rel="alternate"][hreflang]` 的逗号分隔翻译语言，排除 `x-default`。 |
| `tz`  | 字符串 | IANA 时区（`Intl.DateTimeFormat().resolvedOptions().timeZone`）。 |
| `sw`  | 数字 | CSS 像素宽度。                                  |
| `sid` | 字符串 | 每标签页会话 ID（sessionStorage，关闭时清除）。       |

CORS 开放（`Access-Control-Allow-Origin: *`），因为端点不接受凭证。

## 服务器派生字段

这些在摄入时计算并存储于服务器端。原始 IP 和用户代理从未存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 项目的每日轮换哈希。跨日不可关联。  |
| `country_code`    | Cloudflare / 地理位置 IP | 来自受信任的 `CF-IPCountry`标头或配置的 IP 地理位置适配器的 ISO 3166-1 alpha-2 代码。当两者均无法解析国家时为空。 |
| `device`          | User-Agent    | `desktop`, `mobile`，`tablet`，`bot` 或 `unknown`。                 |
| `browser`         | 用户代理    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 或 `unknown`。       |
| `os`              | 用户代理    | `windows`, `macos`, `ios`, `android`, `linux`, 或 `unknown`。        |
| `hostname`        | 页面 URL      | 主机名小写。                                                    |
| `pathname`        | 页面 URL      | 路径部分。                                                     |
| `referrer_source` | 推荐来源      | 推荐来源主机，移除前导 `www.`/`m.`。                        |
| `browser_language`| 语言     | 首选标准化区域性（例如 `pt-BR`）。                    |
| `served_locale`   | 页面语言 | 标准化 `sl`，或者如果未收集则为空（显示为未报告）。 |
| `has_locale_gap`  | 计算      | `1` 在访客的首选语言均不匹配项目目标、宣传翻译 (`al`)、或页面语言 (`sl`) 时。缺失偏好不计作缺口。 |

### 客户端 IP 解析

对于来自私有入口端点的请求，Glossia 使用 nginx 覆盖的 `X-Real-IP` 标头，而不是调用方控制的 `X-Forwarded-For` 中的第一个条目。直接的公网连接使用套接字地址。在 Hetzner，负载均衡器和 nginx 都必须启用 PROXY 协议，以便 nginx 接收访客地址而不是负载均衡器地址。其他反向代理也必须使用认证源覆盖 `X-Real-IP`，而不是不受限制的内联 `X-Forwarded-For` 标头。通用的转发标头策略本身不能保证这一点。私有端点是受信任的基础设施，因此限制直接 Pod 访问。

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` 允许 `CF-Connecting-IP` 覆盖来自私有入口端点的请求的规范地址。默认情况下 **禁用**，独立于国家标头信任。仅在边缘认证了 Cloudflare 或在绕过 Cloudflare 的请求上 strips 伪造标头后才启用它。仅使用 DNS 的部署应保持禁用。该地址也用于 IP 速率限制和每日访客哈希的关键字。

### 国家解析

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 启用 `CF-IPCountry` 快速路径。默认情况下 **禁用**。仅在源验证了 Cloudflare、拒绝绕过 Cloudflare 的请求或入口剥离了不信任的标头副本后才启用它。Cloudflare 的 IP 地理位置设置也必须为区域启用。 `CF-Connecting-IP`、`CF-Ray` 和 nginx 的 `use-forwarded-headers` 本身不能验证请求。

启用标头信任时，会立即使用单个有效的 ISO 国家代码，无需 IP 查找或缓存访问。当前的边缘值始终优于任何缓存查找。缺失、重复、格式错误或未知的代码，包括 Cloudflare 的 `XX`（未知）和 `T1`（Tor）值，将回退到配置的地理位置适配器。

如果没有配置 MaxMind 数据库，回退查找会使用 `api.ipapi.is`，然后当主要请求失败或返回未识别的国家时使用 `api.country.is`。每个请求具有一秒的连接和响应超时，且禁用重试。任一提供商的成功结果将被 Cachex 缓存 24 小时，具有 100,000 条记录的计划大小限制和自动过期回收。 `Cachex.fetch/3` 将同一 IP 的并发缺失合并为一个解析器。失败不会被缓存。私有和保留地址不会发送到任一提供商。

### 缺少页面语言

当事件缺少 `sl` 时，仪表板显示 **未报告**。这包括旧版跟踪器收集的事件以及未设置 HTML `lang` 属性的页面。页面语言不会从浏览器偏好或 URL 中推断。历史事件保留当时收集的元数据；新跟踪器版本不会对其进行补录。

## 隐私模型

- **无持久跨会话标识符。** SDK 不设置 Cookie，且仅在 `sessionStorage` 中存储每标签页会话 ID，浏览器关闭时清除。
- **无指纹识别。** Canvas、WebGL、字体和音频指纹均不收集。每日轮换服务哈希在不使用它们的情况下提供唯一标识符。
- **无原始标识符存储。** IP 和用户代理仅读取一次，与服务器密钥和每日盐值进行哈希，然后丢弃。
- **按项目作用域。** 同一浏览器在两个项目上会产生不相关的访客 ID，因此访客无法跨 Glossia 客户进行跟踪。

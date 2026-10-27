%{
  title: "分析 SDK",
  summary: "收集字段、事件端点以及 Glossia 网站分析背后的隐私模型。",
  category: "参考",
  section: "analytics",
  order: 1
}
---

## 事件端点

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 仍保持可用以兼容。托管脚本从其自身源派生 `/v1/collect`；包集成应显式设置 `endpoint`。

接受来自 `@glossia/web` SDK 的 JSON 事件。始终响应 `202 Accepted`，包括未知域名或格式错误的载荷，因此 SDK 永远不会泄露哪些项目收集分析数据。

项目由片段声明的网站域解析。`d` 是权威字段；当它缺失时，服务器回退到 `u`（页面 URL）的主机，然后是请求 `Origin`/`Referer`。

### 请求体

| 字段 | 类型   | 说明                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 字符串 | 标识项目的站点域（例如 `example.com`）。由浏览器库发送；回退解析描述如上。 |
| `n`   | 字符串 | 事件名称。默认为 `pageview`。                          |
| `u`   | 字符串 | 页面 URL（`location.href`）。                                  |
| `r`   | 字符串 | 来源 URL（`document.referrer`）。                              |
| `l`   | 字符串 | 浏览器语言（`navigator.languages.join(",")`）。         |
| `sl`  | 字符串 | 实际页面语言（`document.documentElement.lang`）。未声明则为空。 |
| `al`  | 字符串 | 来自 `link[rel="alternate"][hreflang]` 的逗号分隔翻译语言，不包括 `x-default`。 |
| `cl`  | 字符串 | 显式选择的语言，或者未观测到选择时为空。SDK 规范化 BCP 47 标签并将输入限制为 64 个字符。 |
| `tz`  | 字符串 | IANA 时区（`Intl.DateTimeFormat().resolvedOptions().timeZone`）。 |
| `sw`  | 数值 | CSS 像素内的屏幕宽度。                                  |
| `sid` | 字符串 | 每标签页会话 ID（sessionStorage，关闭时清除）。       |

CORS 开放（`Access-Control-Allow-Origin: *`），因为端点不接受凭据。

## 显式语言选择

`selectLanguage(language)` 作为命名导出可用，在默认 SDK 导出上，以及在托管脚本的 `glossia` 全局对象上。在初始化后的用户操作处理程序中调用它，并在导航之前。无效的语言标签和初始化前的调用会被忽略。

该方法立即发送 `language_selection` 事件。其 `sl` 仍描述当前页面，而非目的地。后续事件在 `cl` 中包含该选择，直到另一个显式选择替换它。在没有观测到选择的情况下，`cl` 为空。选择作为 `__glossia_selected_language` 存储在单域同源的 `sessionStorage` 中；当存储失败时，它仅在内存中保留直到卸载。

对于链接，`data-glossia-language="zh-Hans"` 启用了对信任、未修改的主点击的委托跟踪，包括键盘激活。脚本化点击、已取消点击、下载、跨源链接以及指向另一个标签页或框架的链接都会被忽略。该监听器在路由器导航之前的捕获阶段运行，不阻止导航，并且也处理动态插入的链接。对于操作应使用注释或 API，不要两者都用。

这是客户端报告的意图信号，而非导航成功的证明。URL 更改、重定向和 HTML 语言更改不被解释为选择。选择不会覆盖 `l` 或 `sl`。有效选择仅在计算 `has_locale_gap` 时优先于浏览器偏好：所选语言必须匹配项目目标、宣布的翻译（`al`）或实际页面语言（`sl`）。选择本身不是可用性的证据。匹配使用归一化的精确或基础语言匹配，就像浏览器偏好一样。

例如，偏好日语的访客若显式选择可用的英语翻译，则无差距。偏好英语的访客若选择不可用的日语，仍有差距，即使在英语页面上。在导航前发出的选择事件会保留当前页面的 `sl`；目的地语言可以通过项目目标或 `al` 识别，而无需假设导航已成功。

缺失、格式错误或超大的选择回退到浏览器偏好。如果既无选择也无浏览器偏好，则无差距。仪表板总数和徽章读取存储的事件标志。历史标志，包括在优化前收集的那些，不会重新计算：历史宣布的翻译和完整的浏览器偏好都不存储。

## 服务器派生字段

这些字段在摄取时计算并存储于服务器端。原始 IP 和 User-Agent 从未存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 项目的每日轮换哈希。跨天不可链接。  |
| `country_code`    | Cloudflare / GeoIP | 来自可信 `CF-IPCountry` 头部的 ISO 3166-1 alpha-2 代码，或使用配置的 IP 地理定位适配器。当两者都无法解析国家时为空。 |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot` 或 `unknown`。                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera` 或 `unknown`。       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux` 或 `unknown`。        |
| `hostname`        | Page URL      | 小写主机名。                                                    |
| `pathname`        | Page URL      | 路径部分。                                                     |
| `referrer_source` | Referrer      | Referrer 主机，前导 `www.`/`m.` 已剥离。                        |
| `browser_language`| Languages     | 最常用的归一化区域设置（例如：`pt-BR`）。                    |
| `served_locale`   | Page language | 归一化的 `sl`，如果未收集则为空。页面语言为空的行会被从浏览器语言分解中省略。 |
| `selected_locale` | Explicit choice | 归一化的 `cl`，对于缺失、格式错误或超大的输入则为空。与浏览器偏好和页面语言分开存储。 |
| `has_locale_gap`  | Computed      | `1` 当有效显式选择在项目目标、宣布的翻译（`al`）或页面语言（`sl`）中无匹配时。无有效选择时，`1` 仅在浏览器偏好非空且不匹配时。 |

### Client IP 解析

对于来自私人入口对端的请求，Glossia 使用重写 `X-Real-IP` 头部而非调用方控制的 `X-Forwarded-For` 中的首条目。直接公共连接使用套接字地址。在 Hetzner，负载均衡器和 nginx 都必须启用 PROXY 协议，以便 nginx 接收访客地址而非负载均衡器地址。其他反向代理也必须使用认证源重写 `X-Real-IP`，而非无限制入站 `X-Forwarded-For` 头部。通用图表的转发头策略本身不能保证这一点。私人端对端是受信任的基础设施，因此限制直接 Pod 访问。

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` 允许 `CF-Connecting-IP` 覆盖来自私人入口对端请求的规范地址。它在 **默认禁用**，独立于国家头信任。仅在边缘认证 Cloudflare 或对绕过 Cloudflare 的请求剥离伪造头后才启用。仅限 DNS 的部署应保持禁用。此地址也用于 IP 速率限制和每日访客哈希的密钥。

### 国家解析

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 启用 `CF-IPCountry` 快速路径。它 **默认禁用**。仅在源端认证 Cloudflare、拒绝绕过 Cloudflare 的请求或入口剥离不信任的头部副本后启用。Cloudflare 的 IP 地理定位设置也必须为区域启用。`CF-Connecting-IP`, `CF-Ray` 和 nginx 的 `use-forwarded-headers` 不能单独认证请求。

启用头部信任后，立即使用单个有效 ISO 国家代码，无需 IP 查找或缓存访问。当前边缘值始终优于任何缓存查找。缺失、重复、格式错误或未知代码（包括 Cloudflare 的 `XX` (未知) 和 `T1` (Tor) 值），回退到配置的地理定位适配器。

未配置 MaxMind 数据库时，回退查找使用 `api.ipapi.is`, 然后当主要请求失败或返回未识别国家时使用 `api.country.is`。每个请求有一秒钟连接和响应超时，无重试。任一提供者的成功结果由 Cachex 缓存 24 小时，具有 100,000 条目的预定大小限制和自动过期回收。`Cachex.fetch/3` 折叠同一 IP 的并发缺失为一个解析器。失败不缓存。私有和保留地址不会发送给任一提供者。

### 缺失页面语言

浏览器语言分解省略没有 `sl` 的事件。这包括旧版跟踪器收集的事件和没有 HTML `lang` 属性的页面。这些事件仍贡献总体流量。页面语言不从浏览器偏好或 URL 推断。历史事件保留当时收集的元数据；新跟踪器版本不会回补它们。

## 隐私模型

- **无持久跨会话标识符.** SDK 不设 cookie，仅存储每个标签页的会话 ID 和显式选择的语言在 `sessionStorage`，浏览器在关闭时清理。
- **无指纹识别。** 画布、WebGL、字体和音频指纹不收集。每日轮换服务器哈希无它们提供唯一性。
- **无原始标识符持久化。** IP 和 User-Agent 读取一次，使用服务器密钥和每日盐哈希，然后丢弃。
- **项目级隔离** 同一浏览器在两个项目上产生的访客 ID 不相关，因此访客无法在 Glossia 客户之间被追踪。

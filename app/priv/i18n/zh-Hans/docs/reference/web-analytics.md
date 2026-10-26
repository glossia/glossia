%{
  title: "分析 SDK",
  summary: "Glossia 网页分析背后的收集字段、事件端点以及隐私模型。",
  category: "参考",
  section: "analytics",
  order: 1
}
---

## 事件端点

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 仍保留以兼容。托管脚本从其自身源派生 `/v1/collect`；包集成应显式设置 `endpoint`。

接受来自 `@glossia/web` SDK 的 JSON 事件。始终响应 `202 Accepted`，包括针对未知域名或格式错误的负载，因此 SDK 绝不会泄露哪些项目收集了分析数据。

项目通过代码片段声明的站点域名确定。`d` 为权威；当它不存在时，服务器回退到 `u` 的主机（页面 URL）和之后请求的 `Origin`/`Referer`。

### 请求体

| 字段 | 类型   | 描述                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 标识项目（例如 `example.com`）的站点域名。由浏览器库发送；回退解析如上文所述。 |
| `n`   | string | 事件名称。默认为 `pageview`。                          |
| `u`   | string | 页面 URL (`location.href`)。                                  |
| `r`   | string | 推荐来源 (`document.referrer`)。                              |
| `l`   | string | 浏览器语言 (`navigator.languages.join(",")`)。         |
| `sl`  | string | 实际页面语言 (`document.documentElement.lang`)。未声明时为空。 |
| `al`  | string | 来自 `link[rel="alternate"][hreflang]` 的逗号分隔翻译语言，排除 `x-default`。 |
| `cl`  | string | 显式选择的语言，或在未观察到选择时为空。SDK 规范化 BCP 47 标签并限制输入最多 64 个字符。 |
| `tz`  | string | IANA 时区 (`Intl.DateTimeFormat().resolvedOptions().timeZone`)。 |
| `sw`  | number | CSS 像素宽度。                                  |
| `sid` | string | 每标签页会话 ID (sessionStorage，关闭时清除)。       |

CORS 已开放 (`Access-Control-Allow-Origin: *`)，因为该端点不接受凭证。

## 显式语言选择

`selectLanguage(language)` 作为命名导出、在默认 SDK 导出上以及托管脚本的 `glossia` 全局上可用。在初始化后、导航前，从用户行为处理器调用它。无效的语言标签和初始化前的调用会被忽略。

该方法会立即发送一个 `language_selection` 事件。其 `sl` 仍描述当前页面，而非目的地。后续事件将包含在该 `cl` 中的选择，直到另一个显式选择将其替换。若无观察到的选择，`cl` 则为空。该选择作为 `__glossia_selected_language` 存储在同一源、每标签页的 `sessionStorage` 中；如果存储失败，则仅在内存中保留，直到卸载。

对于链接，`data-glossia-language="zh-Hans"` 启用受信任、未修改主要点击的代理跟踪，包括键盘激活。脚本点击、已取消点击、下载、跨域链接以及指向其他标签页或帧的链接均被忽略。监听器在路由器导航前运行，不进行导航拦截，并处理动态插入的链接。对于操作，请仅使用注释或 API，不要同时使用。

这是客户端报告的意图信号，而非导航成功的证明。URL 更改、重定向和 HTML 语言更改不会被解释为选择。该选择不覆盖 `l` 或 `sl`，或当前更改 `has_locale_gap` 或仪表盘徽章。

## 服务器派生字段

这些是在采集时计算并在服务器端存储的数据。原始 IP 和用户代理永远不会存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 项目的每日轮换哈希。跨日不可链接。  |
| `country_code`    | Cloudflare / GeoIP | 来自受信任的 `CF-IPCountry` 头或配置的 IP 地理定位适配器的 ISO 3166-1 alpha-2 代码。当两者都无法解析国家时为空。 |
| `device`          | User-Agent    | `desktop`、`mobile`、`tablet`、`bot` 或 `unknown`。                 |
| `browser`         | User-Agent    | `chrome`、`safari`、`firefox`、`edge`、`opera` 或 `unknown`。       |
| `os`              | User-Agent    | `windows`、`macos`、`ios`、`android`、`linux` 或 `unknown`。        |
| `hostname`        | 页面 URL      | 小写主机名。                                                    |
| `pathname`        | 页面 URL      | 路径组件。                                                     |
| `referrer_source` | 推荐来源      | 推荐来源主机，去掉前导 `www.`/`m.`。                        |
| `browser_language`| 语言     | 首选项最高、标准化的区域设置（例如 `pt-BR`）。                    |
| `served_locale`   | 页面语言 | 标准化的 `sl`，若在采集时缺失则为空。页面语言为空的行在浏览器语言分析中将被省略。 |
| `selected_locale` | 显式选择 | 标准化的 `cl`，若输入缺失、格式错误或过大则为空。与浏览器偏好和页面语言分开存储。 |
| `has_locale_gap`  | 计算得出      | 访客首选语言均不匹配项目目标、发布的翻译（`al`）或页面语言（`sl`）时为 `1`。缺失的偏好不计作差距。 |

### 客户端 IP 解析

对于来自私有接入对等节点的请求，Glossia 使用 nginx 的覆盖 `X-Real-IP` 头，而非调用方控制的 `X-Forwarded-For` 中的第一个条目。直接公共连接使用套接字地址。在 Hetzner，负载均衡器和 nginx 都必须启用 PROXY 协议，以便 nginx 接收访客地址而非负载均衡器地址。其他反向代理也必须使用已认证源覆盖 `X-Real-IP`，而非无限制的入站 `X-Forwarded-For` 头。通用图表的转发头策略单独不足以保证这一点。私有对等节点是可信任的基础设施，因此限制直接 Pod 访问。

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` 允许 `CF-Connecting-IP` 覆盖来自私有接入对等节点请求的正则地址。默认情况下 **禁用的**，与 mã nước头信任无关。仅在经过边缘验证 Cloudflare 或对绕过 Cloudflare 的请求剥离伪造头的情况下启用它。仅 DNS 的部署应保持禁用。该地址还作为 IP 速率限制和每日访客哈希的键。

### 国家解析

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 启用 `CF-IPCountry` 快速路径。默认情况下 **禁用**。仅在起源验证 Cloudflare、拒绝绕过 Cloudflare 的请求，或接入剥离不可信的头拷贝后启用它。Cloudflare 的 IP 地理位置设置也必须为区域启用。`CF-Connecting-IP`、`CF-Ray` 和 nginx 的 `use-forwarded-headers` 单独不验证请求。

启用头信任时，立即使用单一的合法 ISO 国家代码，无需 IP 查找或缓存访问。当前边缘值始终优先于任何缓存查找。缺失、重复、格式错误或未知的代码（包括 Cloudflare 的 `XX`（未知）和 `T1`（Tor）值），回退到配置的地理位置适配器。

没有配置的 MaxMind 数据库，备份查找首先使用 `api.ipapi.is`，当主请求失败或返回无可识别的国家时使用 `api.country.is`。每个请求具有一秒钟的连接和响应超时，且禁用重试。任一提供商的成功结果由 Cachex 缓存 24 小时，带有 100,000 条目的调度大小限制和自动过期回收。`Cachex.fetch/3` 将同一 IP 的并发未命中合并为单个解析器。失败不会被缓存。私有和保留地址不会发送给任一提供商。

### 缺失的页面语言

浏览器语言分析省略没有 `sl` 的事件。这包括由旧版本跟踪器收集和没有 HTML `lang` 属的页面收集的事件。这些事件仍然贡献总体流量。页面语言不会从浏览器偏好或 URL 推断。历史事件保留当时收集的元数据；新跟踪器版本不补填它们。

## 隐私模型

- **无持久跨会话标识符。** SDK 不设置 Cookie，仅存储每标签页会话 ID 和显式选择的语言在 `sessionStorage` 中，浏览器在关闭时清除。
- **无指纹识别。** 画布、WebGL、字体和音频指纹都未收集。每日轮换的服务器哈希提供唯一标识而无需这些指纹。
- **无原始标识符持久化。** IP 和用户代理仅读取一次，使用服务器密钥和每日盐值进行哈希，随后丢弃。
- **按项目范围。** 同一浏览器在两个项目上产生不相关的访客 ID，因此访客无法跨 Glossia 客户被跟踪。

%{
  title: "分析 SDK",
  summary: "Glossia 网站分析背后的收集字段、事件端点以及隐私模型。",
  category: "参考",
  section: "analytics",
  order: 1
}
---
## 事件端点

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` 仍保持可用以确保兼容性。托管脚本源自 `/v1/collect` 其自身源；集成包应设置 `endpoint` 为显式。

接受 JSON 事件来自 `@glossia/web` SDK。始终响应 `202 Accepted`，包括针对未知域或格式错误的载荷，因此 SDK 不会泄露哪些项目收集了分析数据。

该项目的解析取决于代码片段声明的网站域。 `d` 具有权威性；当它缺失时，服务器回退到其主机的 `u` (页面 URL) 以及随后的请求 `Origin`/`Referer`.

### 请求体

| 字段 | 类型   | 描述                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 标识项目的站点域 (例如 `example.com`)。由浏览器库发送；回退解析在上方描述。|
| `n`   | string | 事件名称。默认为 `pageview`.                          |
| `u`   | 字符串 | 页面 URL (",`location.href`).                                  |
| `r`   | 字符串 | 引用方 (`document.referrer`).                              |
| `l`   | string | 浏览器语言 (\\`navigator.languages.join(",")`).         |
| `sl`  | 字符串 | 实际页面语言 (`document.documentElement.lang`)。如果未声明则为空。|
| `al`  string | 翻译语言（逗号分隔）来自 `link[rel="alternate"][hreflang]`, 排除 `x-default`. |
| `tz`  string | IANA 时区 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | 屏幕宽度（CSS 像素）。                                  |
| `sid` | string | 每标签页会话 ID (sessionStorage, 关闭时清除)。       |

CORS 已开放 (`Access-Control-Allow-Origin: *`) 因为该端点不接受凭证。

## 服务端计算字段

这些字段在数据摄入时计算并存储在服务器端。原始 IP 和 User-Agent 从未存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 项目的每日轮换哈希值。跨天无法关联。  |
| `country_code`    | Cloudflare / GeoIP | ISO 3166-1 alpha-2 代码来自可信的 `CF-IPCountry` 表头，或配置的 IP 地理定位适配器。当两者均无法解析国家时为空。|
| `device`          | 用户代理    | `desktop`, `mobile`, `tablet`, `bot`，或 `unknown`。
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`，或 `unknown`,.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, 或 `unknown`.        |
| `hostname`        | 页面 URL      | 小写主机名。                                                    |
| `pathname`        | 页面 URL      | 路径组件。                                                     |
| `referrer_source` | 来源      | 来源主机，前导 `www.`/`m.` 移除。                        |
| `browser_language`| 语言     | 首选标准化地区 (例如. `pt-BR`).                    |
| `served_locale`   | 页面语言 | 标准化 `sl`, 或为空（显示为未报告）如未收集。|
| `has_locale_gap`  | 计算得出      | `1` 当访客的首选语言与项目目标、宣传翻译（`al`）、或页面语言（`sl`)。缺失的偏好设置不计为缺口。|

### 国家解析

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` 启用 `CF-IPCountry` 快速路径。它 **默认禁用**。仅在源站验证了 Cloudflare、拒绝了绕过 Cloudflare 的请求，或入口点剥离了不信任的头部副本后方可启用。此外，Cloudflare 的 IP 地理定位设置也必须对该区域启用。 `CF-Connecting-IP`， `CF-Ray`， `use-forwarded-headers` 和 nginx 的

无法自行验证请求。 `XX` (unknown) 和 `T1` (Tor) 值，回退到配置的地理位置适配器。

未配置 MaxMind 数据库时，回退查找使用 `api.ipapi.is`, 然后 `api.country.is` 当主请求失败或返回无识别出的国家时。每个请求具有一秒的连接和响应超时，且禁用重试。任一提供商的成功结果由 Cachex 缓存 24 小时，具有 100,000 条目的调度大小限制及自动过期回收。 `Cachex.fetch/3` 将同一 IP 的并发未命中合并为单一解析器。失败不缓存。私有和保留地址不会发送至任一提供商。

### 页面语言缺失

仪表板显示 **未报告** 当事件没有 `sl`。这包括旧版本追踪器收集的事件及没有 HTML `lang` 属性。页面语言不会从浏览器偏好或 URL 推断。历史事件保留当时收集的元数据; 新追踪器版本不会回填它们。

## 隐私模型

- **无持久跨会话标识符。** SDK 不设置 Cookie，仅将每标签会话 ID 存储于 `sessionStorage`, 且浏览器会在关闭时将其清除。
- **无指纹追踪。** Canvas、WebGL、字体和音频指纹均不收集。每日轮换的服务器哈希可提供唯一标识，无需依赖这些指纹。
- **不持久化原始标识符。** IP 地址和 User-Agent 仅读取一次，经服务器密钥和每日盐值哈希处理后即被丢弃。
- **项目级范围限定。** 同一台浏览器在两个项目中将生成无关的访客 ID，因此无法在 Glossia 客户之间追踪访客。
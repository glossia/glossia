%{title: "分析 SDK", summary: "收集字段、事件端点及 Glossia Web 分析背后的隐私模型。", category: "参考", order: 1}
---
## 事件端点

`POST /api/analytics/events`

接受来自 `@glossia/web` SDK 的 JSON 事件。始终返回 `202 Accepted`，即使针对未知域名或格式错误的负载也是如此，这样 SDK 就不会泄露哪些项目正在收集分析数据。

项目由代码段声明的网站域名确定。`d` 是权威标识；当它缺失时，服务器回退到 `u`（页面 URL）的主机名，然后是使用请求的 `Origin`/`Referer`。

### 请求体

| 字段 | 类型 | 描述 |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 标识项目的网站域名（例如 `example.com`）。必需。          |
| `n`   | string | 事件名称。默认值为 `pageview`。                            |
| `u`   | string | 页面 URL (`location.href`)。                               |
| `r`   | string | 来源地址 (`document.referrer`)。                           |
| `l`   | string | 浏览器语言 (`navigator.languages.join(",")`)。             |
| `tz`  | string | IANA 时区 (`Intl.DateTimeFormat().resolvedOptions().timeZone`)。 |
| `sw`  | number | 以 CSS 像素为单位的屏幕宽度。                              |
| `sid` | string | 每个标签页的会话 ID (sessionStorage，关闭时清除)。        |

CORS 已开启（`Access-Control-Allow-Origin: *`），因为该端点不接受凭据。

## 服务器端派生字段

这些字段在数据摄取时计算并在服务器端存储。原始 IP 和 User-Agent 绝不会被存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 项目的每日轮换哈希值。无法跨天链接。                  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 代码。当未配置 GeoIP 时为空。                  |
| `device`          | User-Agent    | `desktop`、`mobile`、`tablet`、`bot` 或 `unknown`。                 |
| `browser`         | User-Agent    | `chrome`、`safari`、`firefox`、`edge`、`opera` 或 `unknown`。       |
| `os`              | User-Agent    | `windows`、`macos`、`ios`、`android`、`linux` 或 `unknown`。       |
| `hostname`        | 页面 URL      | 主机名，已转为小写。                                           |
| `pathname`        | 页面 URL      | 路径部分。                                                       |
| `referrer_source` | Referrer      | 来源页主机名，去除前导的 `www.`/`m.`。                         |
| `browser_language`| 语言         | 首选的正常化本地化（例如 `pt-BR`）。                            |
| `served_locale`   | 计算          | 首先是匹配首选语言的可用目标，否则为空。                        |
| `has_locale_gap`  | 计算          | 当访客首选项目不支持的语言时，值为 `1`。                         |

## 隐私模型

- **无客户端存储。** SDK 不设置 Cookie，仅在 `sessionStorage` 中存储每个标签页的会话 ID，浏览器在关闭时清除它。
- **不进行指纹识别。** 不收集 Canvas、WebGL、字体和声音指纹。每日轮换的服务器哈希提供了唯一性，而无需这些指纹。
- **不保留原始标识符。** IP 和 User-Agent 仅读取一次，使用服务器密钥和每日盐值进行哈希计算后丢弃。
- **按项目范围限制。** 同一浏览器在两个项目上产生的访客 ID 互不相同，因此无法跨 Glossia 客户追踪访客。
%{
  title: "分析 SDK",
  summary: "Glossia Web 分析收集的字段、事件端点及其背后的隐私模型。",
  category: "reference",
  order: 1
}
---
## 事件端点

`POST /api/analytics/events`

接收来自 `@glossia/web` 软件开发工具包的 JSON 事件。始终响应 `202 Accepted`，即使域名未知或负载格式错误也是如此，确保软件开发工具包不会泄露哪些项目正在收集分析数据。

项目根据代码片段声明的站点域名进行解析。`d` 是权威值；若缺失，服务器将依次回退到 `u`（页面网址）的主机名，以及请求的 `Origin`/`Referer`。

### 请求正文

| 字段 | 类型 | 说明 |
|-------|--------|--------------------------------------------------------------|
| `d` | 字符串 | 用于标识项目的站点域名（例如 `example.com`）。必填。 |
| `n` | 字符串 | 事件名称。默认为 `pageview`。 |
| `u` | 字符串 | 页面网址（`location.href`）。 |
| `r` | 字符串 | 引荐来源（`document.referrer`）。 |
| `l` | 字符串 | 浏览器语言（`navigator.languages.join(",")`）。 |
| `tz` | 字符串 | 互联网号码分配机构时区（`Intl.DateTimeFormat().resolvedOptions().timeZone`）。 |
| `sw` | 数字 | 以层叠样式表像素为单位的屏幕宽度。 |
| `sid` | 字符串 | 每个标签页独立的会话标识符（存储于 sessionStorage，关闭时清除）。 |

跨源资源共享完全开放（`Access-Control-Allow-Origin: *`），因为该端点不接受任何凭据。

## 服务器派生字段

这些字段在数据摄取时计算并存储在服务器端。原始互联网协议地址和 User-Agent 从不存储。

| 字段             | 来源        | 说明                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | 由 IP 地址、用户代理和项目生成且每日轮换的哈希。无法跨日关联。  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 代码。未配置 GeoIP 时为空。        |
| `device`          | User-Agent    | `desktop`、`mobile`、`tablet`、`bot` 或 `unknown`。                 |
| `browser`         | User-Agent    | `chrome`、`safari`、`firefox`、`edge`、`opera` 或 `unknown`。       |
| `os`              | User-Agent    | `windows`、`macos`、`ios`、`android`、`linux` 或 `unknown`。        |
| `hostname`        | 页面 URL      | 转换为小写的主机名。                                                    |
| `pathname`        | 页面 URL      | 路径部分。                                                     |
| `referrer_source` | 引荐来源      | 引荐来源的主机名，已移除开头的 `www.`/`m.`。                        |
| `browser_language`| 语言     | 首选的规范化区域设置（例如 `pt-BR`）。                    |
| `served_locale`   | 计算得出      | 与首选语言匹配的第一个受支持目标语言，否则为空。   |
| `has_locale_gap`  | 计算得出      | 当访客首选的语言未由项目提供时为 `1`。 |

## 隐私模型

- **无客户端存储。** 软件开发工具包不会设置 Cookie，仅在 `sessionStorage` 中存储每个标签页的会话标识符，浏览器关闭时会将其清除。
- **无指纹识别。** 不收集 Canvas、WebGL、字体和音频指纹。每日轮换的服务器哈希无需这些指纹即可统计唯一访客。
- **不持久化原始标识符。** IP 地址和 User-Agent 仅读取一次，使用服务器密钥和每日盐值进行哈希处理后即被丢弃。
- **按项目限定范围。** 同一浏览器访问两个项目时会生成互不相关的访客标识符，因此无法跨 Glossia 客户跟踪访客。
%{title: "分析 SDK", summary: "收集的字段、事件端点以及 Glossia 网站分析背后的隐私模型。", category: "参考", order: 1}
---
## 事件端点

`POST /api/analytics/events`

接受来自 `@glossia/web` SDK。始终响应 `202 Accepted`，包括针对未知域或格式无效的有效负载，因此 SDK 永远不会泄露哪些项目收集的分析数据。

项目由片段声明的网站域解析。 `d` 具有权威性；当它缺省时，服务器回退至主机的 `u` （页面 URL）和随后的请求 `Origin`/`Referer`.

### 请求体

| 字段 | 类型   | 描述                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 标识项目所在域的站点 (例如 `example.com`)。必填。 |
| `n`   | string | 事件名称。默认为 `pageview`。                          |
| `u`   | string | 页面 URL (`location.href`).                                  |
| `r`   | 字符串 | 引用来源 (`document.referrer`) .                              |
| `l`   | string | 浏览器语言 (`navigator.languages.join(",")`).         |
| `tz`  | string | IANA 时区 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | 屏幕宽度 (CSS 像素)。                                  |
| `sid` | 字符串 | 每标签页会话 ID (sessionStorage，关闭时清除)。       |

CORS 已开放 (`Access-Control-Allow-Origin: *`) 因为此端点不接受凭证。

## 服务端衍生字段

这些是在摄取阶段计算并存储在服务器端的。原始 IP 和用户代理地址从未存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 项目的每日轮换哈希。跨天无法关联。  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 代码。未配置 GeoIP 时为空。        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`，或 `unknown`。                 |
| `browser`         | 用户代理    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 或 `unknown`.       |
| `os`              | 用户代理    | `windows`, `macos`重新组合的文档此前验证失败：Markdown 文本字面量恢复返回了无效的 JSON `ios`重组文档先前验证失败：Markdown 文本字面量恢复返回无效 JSON `android`, `linux`, 或 `unknown`.        |
| `hostname`        | 页面 URL      | 小写主机名。                                                  |
| `pathname`        | 页面 URL      | 路径组件。                                                     |
| `referrer_source` | 来源       | 来源主机，前导 `www.`/`m.` 已移除。                        |
| `browser_language`| 语言     | 首选标准化语言区域 (例如. `pt-BR`)".                    |
| `served_locale`   | 计算结果       | 首选语言匹配的第一个支持目标，否则为空。   |
| `has_locale_gap`  | 计算      | `1` 当访客偏好项目不支持的语言时。|

## 隐私模型

- **无客户端存储。** SDK 不设置 Cookie，且仅存储每个标签页会话 ID 在 `sessionStorage`, 浏览器在关闭时将其清除。
- **无指纹追踪。** 不收集 Canvas、WebGL、字体和音频指纹。每日轮换的服务器哈希提供唯一标识，无需这些信息。
- **未留存原始标识符。** IP 地址和用户代理仅读取一次，经服务器密钥及每日盐值哈希化处理后立即丢弃。
- **按项目范围。** 同一浏览器在两个项目中生成不相关的访客 ID，因此无法跨 Glossia 客户追踪访客。
%{title: "分析 SDK", summary: "Glossia 网页分析背后的收集字段、事件端点及隐私模型。", category: "参考", order: 1}
---
## 事件端点

`POST /api/analytics/events`

接受来自的 JSON 事件 `@glossia/web` SDK。始终响应 `202 Accepted`，包括针对未知域或格式错误的载荷，因此 SDK 不会泄露哪些项目收集分析数据。

项目由代码片段声明的站点域名确定。 `d` 具权威性；若其缺失，服务器回退至所属主机 `u` (页面 URL) 以及随后的 `Origin`/`Referer`.

### 请求体

| 字段 | 类型   | 描述                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | 标识项目的站点域（例如 `example.com`). 必填。 |
| `n`   | 字符串 | 事件名称。默认为 `pageview`。                          |
| `u`   | 字符串 | 页面 URL (`location.href`).                                  |
| `r`   | 字符串 | 来源 (`document.referrer`).                              |
| `l`   | string | 浏览器语言 (`navigator.languages.join(",")`)。         |
| `tz`  | string | IANA 时区 (`Intl.DateTimeFormat().resolvedOptions().timeZone`)。 |
| `sw`  | number | 屏幕宽度（CSS 像素）。                              |
| `sid` | 字符串 | 每标签页会话 ID (sessionStorage，关闭时清除)。       |

CORS 已启用 (`Access-Control-Allow-Origin: *`) 因为该端点不接受凭据。

## 服务端派生字段

这些在采集时计算并存储于服务器端。原始 IP 地址和 User-Agent 均不会被存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | 每日轮换的 IP + UA + 项目哈希。跨天不可链接。|
| `country_code`    | GeoIP         | ISO 3166-1 二位代码。未配置 GeoIP 时为空。        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, 或 `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`重新组装的文档此前验证失败：Markdown 文本字面量恢复必须返回匹配长度的 JSON 字符串数组 `firefox`重组后的文档此前验证失败：Markdown 文本字面量恢复必须返回一个长度匹配的 JSON 字符串数组 `edge`, `opera`, 或 `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`此前重新组合的文档验证失败：Markdown 文本节点恢复生成了空翻译 `linux`，或 `unknown`.        |
| `hostname`        | 页面 URL      | 小写主机名。                                                    |
| `pathname`        | 页面 URL      | 路径部分。                                                     |
| `referrer_source` | 来源            | 来源主机，前导 `www.`/`m.` 已剥离。                    |
| `browser_language`| 语言            | 首选标准化区域设置 (例如 `pt-BR`)。                    |
| `served_locale`   | 计算值          | 匹配首选语言的首个支持目标，否则为空。   |
| `has_locale_gap`  | 计算      | `1` 当访客偏好项目不支持的语言时。 |

## 隐私模型

- **无客户端存储。** SDK 不设置 cookie，仅存储每个标签页的会话 id 于 `sessionStorage`，浏览器在关闭时会清除它。
- **无指纹追踪。** Canvas、WebGL、字体和音频指纹均不被收集。每日轮换的服务器哈希无需它们即可提供唯一标识。
- **未持久化任何原始标识符。** IP 地址和用户代理仅读取一次，使用服务器密钥和每日盐值哈希后随即丢弃。
- **按项目范围。** 同一浏览器在两个项目上会产生不关联的访客 ID，因此无法跨 Glossia 客户追踪访客。
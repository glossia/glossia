%{title: "分析 SDK", summary: "收集的字段、事件端点，以及 Glossia 网页分析背后的隐私模型。", category: "参考", order: 1}
---
## 事件端点

`POST /api/analytics/events`

接受一个 JSON 事件来自 `@glossia/web` SDK。始终响应 `202 Accepted`，包括针对未知域或格式错误载荷，因此 SDK 永远不会泄露哪些项目收集分析数据。

项目由片段声明的站点域解析。 `d` 具有权威性；当它缺失时，服务器回退至 `u` (页面 URL) 以及随后的请求 `Origin`/`Referer`.

### 请求体

| 字段 | 类型   | 描述                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | 字符串 | 标识项目的站点域名 (例如 `example.com`). 必填。|
| `n`   | string | 事件名称。默认为 `pageview`.                          |
| `u`   | string | 页面 URL (`location.href`).                                  |
| `r`   | string | 来源 (`document.referrer`).                              |
| `l`   | 字符串 | 浏览器语言 (`navigator.languages.join(",")`)         |
|\] `tz`  | 字符串 | IANA 时区 (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | 屏幕宽度（CSS 像素）                                  |
| `sid` | 字符串 | 每标签页会话 ID (sessionStorage, 关闭时清除)。      |

CORS 已开启 (`Access-Control-Allow-Origin: *`), 因为该端点不接受凭据。

## 服务器派生字段

这些在采集时计算并存储于服务端。原始 IP 和用户代理 (User-Agent) 永远不会存储。

| 字段             | 来源        | 描述                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | IP + UA + 项目的每日轮换哈希。跨天不可关联。  |
| `country_code`    | GeoIP         | ISO 3166-1 alpha-2 代码。未配置 GeoIP 时为空。        |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, or `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, 或 `unknown`.       |
| `os`              | 用户代理    | `windows`, `macos`重新组合的文档先前验证失败：Markdown 文本节点恢复产生了空翻译 `ios`重组后的文档此前验证失败：Markdown 文本节点恢复生成了空翻译 `android`, `linux`, 或 `unknown`.        |
| `hostname`        | 页面 URL      | 小写主机名。                                                    |
| `pathname`        | 页面 URL      | 路径组件。                                                     |
| `referrer_source` | 来源      | 来源主机，前导 `www.`/`m.` 截断。                        |
| `browser_language`| 语言     | 首选标准化区域设置 (例如 `pt-BR`).                    |
| `served_locale`   | 计算      | 匹配首选语言的首要支持目标，否则为空。   |
| `has_locale_gap`  | 计算      | `1` 当访客偏好项目不支持的语言时。|

## 隐私模型

- **无客户端存储。** SDK 不设置 Cookie，仅存储一个标签页会话 ID 在 `sessionStorage`，浏览器关闭时会将其清除。
- **无指纹追踪。** 不收集 Canvas、WebGL、字体和音频指纹。每日轮换的服务器哈希可在无需这些信息的情况下提供唯一标识。
- **未持久化任何原始标识符。** IP 地址和用户代理仅读取一次，使用服务器密钥和每日盐值进行哈希处理后随即被丢弃。
- **按项目范围限定。** 同一浏览器在不同项目中生成的访客 ID 互不相关，因此无法在 Glossia 客户之间追踪访客。
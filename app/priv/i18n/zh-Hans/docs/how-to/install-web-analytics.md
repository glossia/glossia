%{
  title: "安装 Web 分析",
  summary: "在您的网站上通过一行 HTML 或通过 npm 添加 Glossia Web SDK，并开始收集本地化信号。",
  category: "教程",
  section: "analytics",
  order: 1
}
---

本指南假设您拥有一个在项目的分析设置中配置了站点域名的 Glossia 项目。采集由该域名标识，因此无需复制密钥或秘密。

## 选项 A：脚本标签

将此代码片段添加到每一页，最好在 `<head>` 中：

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 会自动初始化，在加载时发送页面视图，并在单页应用中的客户端导航时记录后续的页面视图。若省略，`data-domain` 默认值为 `window.location.hostname`，因此您可以在单一域名站点上省略它。要使用自定义的采集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

如果您的站点使用内容安全策略，请允许 `https://glossia.ai` 同时出现在 `script-src`（或 `script-src-elem` 如果存在）和 `connect-src` 中。脚本从 `/assets/glossia-web.js` 加载，并将事件发送到同源下的 `/v1/collect`。

## 选项 B：npm

安装此包：

```bash
npm install @glossia/web
```

在您的应用程序入口点初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

在包用于您自己的 bundle 时，请显式设置采集端点，因为没有托管的脚本地址可供推断。

“`domain`”是从 `window.location.hostname` 推断得出的，因此 SDK 针对为您网站注册的项目进行记录。要覆盖此设置（例如将来自预发环境的事件发送到与生产环境相同的项目），可以传递 `{ domain: "example.com" }`。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证您的域名

在您的项目的 **分析设置** 中，保存您的站点域名。 **验证域名所有权** 卡片显示您项目的精确记录名称和值。通过您的域名提供商添加文本记录：

| 字段 | 值 |
| --- | --- |
| 类型 | `TXT` ([文本记录](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| 名称 | `_glossia-verify.example.com` |
| 值 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

使用设置中显示的域名和 token。某些提供商会自动添加域名，此时仅输入 `_glossia-verify` 作为名称。发布记录后，点击 **验证域名**。更改生效可能需要时间，如果记录立即找不到请重试。

如果无法编辑您的域名记录，展开 **备选：通过主页元标签验证**。将生成的标签复制到您主页的 `<head>` 中并发布：

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

这两种方法均可证明您控制着配置的域名。Glossia 会检查该域名的记录或主页，因此将 token 复制到另一个网站无法验证所有权。Token 是公开证明，而非密码。

一旦域名经过验证，Glossia 将从您的跟踪代码片段记录事件。仅凭该代码片段无法验证所有权。更改配置的域名需要重新验证。

## 验证其是否有效

1. 在浏览器中打开您的站点。
2. 打开网络选项卡，确认向 `https://glossia.ai/v1/collect` 发出的 `POST` 请求返回 `202 Accepted`。
3. 采集和处理后，页面视图将出现在您仪表盘的 **分析** 部分。在概览页面上运行的翻译与网站流量是分开的。

`202 Accepted` 响应确认请求已到达采集器。未知或未经证实的域名也会接受，但不会记录事件，因此请确认项目分析设置中配置的域名已验证。

## 收集了什么

浏览器会发送页面 URL、来源、`navigator.languages`、时区和屏幕宽度，以及每标签页会话 ID。服务器添加国家（来自 GeoIP）并针对项目的目标语言计算本地化差距。不设置 Cookie，也不会生成指纹。

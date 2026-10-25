%{
  title: "安装 Web 分析",
  summary: "使用一行 HTML 或通过 npm 向您的站点添加 Glossia Web SDK，并开始收集本地化信号。",
  category: "教程",
  section: "analytics",
  order: 1
}
---

本指南假设您拥有一个 Glossia 项目，其网站域名已在项目的分析设置中配置。收集由该域名标识，因此没有需要复制的密钥或秘密。

## 选项 A：脚本标签

将此片段添加到每一页面，理想情况下在 `<head>` 内：

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 自动初始化，在加载时发送页面浏览，并在单页应用中进行客户端导航时记录后续页面浏览。`data-domain` 在省略时默认为 `window.location.hostname`，所以您可以在单域名网站上省略它。要使用自定义收集端点，添加 `data-endpoint="https://collect.your-host.com"`。

如果您的网站使用内容安全策略，请在 `script-src` (或存在时的 `script-src-elem`) 和 `connect-src` 中允许 `https://glossia.ai`。脚本从 `/assets/glossia-web.js` 加载，并向同源的 `/v1/collect` 发送事件。

## 选项 B：npm

安装包：

```bash
npm install @glossia/web
```

在应用程序入口点中初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

在您的包中使用该包时，由于不存在托管脚本地址从中推断，请显式设置收集端点。

`domain` 由 `window.location.hostname` 推断，因此 SDK 针对您注册了该项目的网站进行记录。传递 `{ domain: "example.com" }` 以覆盖，例如将来自测试源的事件发送到与生产相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证您的域名

在您的项目的 **分析设置** 中保存您的网站域名。**验证域名所有权** 卡片显示您项目的确切记录名称和值。使用您的域名提供商添加一条文本记录：

| 字段 | 值 |
| --- | --- |
| 类型 | `TXT` ( [文本记录](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/) ) |
| 名称 | `_glossia-verify.example.com` |
| 值 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

在您的设置中显示的域名和令牌。某些供应商会自动添加该域名；在这种情况下，仅输入 `_glossia-verify` 作为名称。发布记录后，点击 **验证域名**。更改可能需要一些时间才能生效，如果记录未立即找到，请重试。

如果您无法编辑域名记录，请展开 **替代方案：使用主页元标签验证**。将生成的标签复制到您主页的 `<head>` 中并发布：

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

任一方法都证明了对配置域的控制。Glossia 检查该域的记录或主页，因此将令牌复制到另一个网站并不会验证所有权。该令牌是公共证明，而非密码。

一旦域名已验证，Glossia 将记录跟踪片段的事件。该片段本身并不能验证所有权。更改配置的域需要再次验证。

## 验证其是否有效

1. 在浏览器中打开您的网站。
2. 打开网络标签页并确认 `POST` 请求到 `https://glossia.ai/v1/collect` 返回 `202 Accepted`。
3. 在收集和处理之后，页面浏览出现在您项目仪表盘的 **分析** 下。概述页面上的翻译与网站流量是分开。

一个 `202 Accepted` 的响应确认请求已到达收集器。未知或未验证的域名也被接受，但不记录事件，因此请确认项目分析设置中配置的域名已验证。

## 收集了什么

浏览器发送页面 URL、引用方、`navigator.languages`、时区和屏幕宽度，以及每个标签页的会话 ID。服务器添加国家（来自 GeoIP）并根据您项目的目标语言计算本地化差距。未设置任何 Cookie 并且没有进行指纹识别。

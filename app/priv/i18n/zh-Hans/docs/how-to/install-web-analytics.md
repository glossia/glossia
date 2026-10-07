%{
  title: "安装网站分析",
  summary: "通过一行 HTML 代码或 npm，将 Glossia 网页 SDK 添加到您的网站，并开始收集本地化信号。",
  category: "教程",
  section: "analytics",
  order: 1
}
---
本指南假设您拥有一个 Glossia 项目，其站点域已在项目分析设置中配置。采集由该域标识，因此无需复制密钥或凭证。

## 选项 A：脚本标签

将此代码片段添加到每个页面，理想情况下位于该 `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 会自动初始化，加载时发送页面浏览，并在单页应用中的客户端导航时记录后续页面浏览。 `data-domain` 默认为 `window.location.hostname` 省略时，因此您可以将其用于单域站点。若要使用自定义采集端点，请添加 `data-endpoint="https://collect.your-host.com"`.

如果您的站点使用了内容安全策略，请允许 `https://glossia.ai` 两者中 `script-src` (或 `script-src-elem` 存在时) 以及 `connect-src`。脚本从 `/assets/glossia-web.js` 并发送事件到 `/v1/collect` 同源上。

## 选项 B：npm

安装包：

```bash
npm install @glossia/web
```

在应用入口点初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

在自有构建包中使用此包时，请显式指定集合端点，因为没有托管脚本地址可供推断。

`domain` 推断自 `window.location.hostname` 因此 SDK 会记录至您网站注册的项目。传入 `{ domain: "example.com" }` 以覆盖默认行为，例如将来自预发布源的事件发送到与生产环境对应的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证您的域名

在您的项目的 **分析设置**，保存您的网站域名。该 **验证域名所有权** 卡片显示您项目的确切记录名称和值。请使用您的域名提供商添加一条文本记录：

| 字段 | 值 |
| --- | --- |
| 类型 | `TXT` ([文本记录](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| 名称 | `_glossia-verify.example.com` |
| 值 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

使用您在设置中显示的域名和令牌。某些提供者会自动添加域名；在此情况下仅输入 `_glossia-verify` 如其名称。发布记录后，点击 **验证域名**。变更可能需要一段时间才能生效，因此如果记录未立即找到，请重试。

如果无法编辑域名记录，请展开 **替代方案：通过主页 meta 标签验证**。将生成的标签复制到 `<head>` 您的主页并发布它：

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

任一方法均可证明对配置域名的控制权。Glossia 会检查该域名的记录或主页，因此将令牌复制到另一个网站无法验证所有权。令牌是公开凭证，而非密码。

一旦域名已验证，Glossia 将记录来自您跟踪代码片段的事件。仅代码片段本身无法验证所有权。更改配置的域名需要再次验证。

## 验证是否有效

1. 在浏览器中打开您的网站。
2. 打开网络标签页并确认 `POST` 请求至 `https://glossia.ai/v1/collect` 返回 `202 Accepted`。
3. 收集和处理后，页面浏览量显示在 **分析** 位于您的项目仪表板中。概述页面上的翻译运行与网站流量是分开的。

一 `202 Accepted` 响应确认请求已到达收集器。未知或未经验证的域名也会被接受，但不会记录事件，因此请确认配置的域名已在项目的分析设置中完成验证。

## 收集内容

浏览器会发送页面 URL、来源、 `navigator.languages`时区，以及屏幕宽度，加上每个选项卡的会话 ID。服务器添加国家（来自 GeoIP）并计算针对您项目目标语言的本地化差距。未设置 Cookie，也未进行指纹识别。
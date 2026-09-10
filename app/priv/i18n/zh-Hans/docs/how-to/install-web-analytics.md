%{
  title: "安装网站分析",
  summary: "使用一行 HTML 或通过 npm 将 Glossia web SDK 添加到您的网站，并开始收集本地化信号。",
  category: "教程",
  order: 1
}
---
本指南假设您拥有一个在项目的分析设置中已配置了站点域名的 Glossia 项目。采集通过该域名进行识别，因此无需复制任何密钥或秘密。

## 选项 A：脚本标签

将此代码片段添加到每个页面，理想情况下在 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 自动初始化，加载时发送页面浏览，并在单页应用的客户端导航时记录后续的页面浏览。 `data-domain` 默认为 `window.location.hostname` 当省略时，您可以将其用于单域网站。若要使用自定义采集端点，请添加 `data-endpoint="https://collect.your-host.com"`.

## 选项 B：npm

安装包：

```bash
npm install @glossia/web
```

在您的应用程序入口点初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init();
```

该 `domain` 推断自 `window.location.hostname` 因此，SDK 记录至为您站点注册的项目。传递 `{ domain: "example.com" }` 以覆盖，例如将来自预发布源的事件发送至与生产环境相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证它是否正常工作

1. 在浏览器中打开您的站点。
2. 打开网络标签页并确认一个 `POST` 请求至 `/api/analytics/events` 返回 `202 Accepted`。
3. 一分钟内，页面浏览量将显示在您的项目分析仪表板中。

## 收集内容

浏览器会发送页面 URL、推荐来源， `navigator.languages`、时区及屏幕宽度，以及每个标签页的会话 ID。服务器会从 GeoIP 添加国家信息，并计算与您的项目目标语言之间的本地化差距。未设置任何 Cookie，也未进行指纹追踪。
%{
  title: "安装网站分析",
  summary: "通过一行 HTML 代码或通过 npm 将 Glossia Web SDK 添加到您的网站，即可开始收集本地化信号。",
  category: "教程",
  order: 1
}
---
本指南假设您已拥有在项目的分析设置中配置了站点域名的 Glossia 项目。收集是基于该域名进行识别的，因此无需复制任何密钥或凭证。

## 选项 A：脚本标签

将此代码片段添加到每个页面，最好在 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 会自动初始化，加载时发送页面浏览，并在单页应用的客户端导航中记录后续的页面浏览。 `data-domain` 默认为 `window.location.hostname` 省略时，因此您可以将其添加到单域名站点。若要使用自定义收集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

## 选项 B：npm

安装此包：

```bash
npm install @glossia/web
```

在您的应用程序入口点初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init();
```

其 `domain` 是推断自 `window.location.hostname` 因此 SDK 会记录至您站点注册的项目。传递 `{ domain: "example.com" }` 以覆盖，例如将事件从预发布环境发送到与生产环境相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证其是否正常工作

1. 在浏览器中打开您的网站。
2. 打开“网络”标签页并确认一个 `POST` 请求至 `/api/analytics/events` 返回 `202 Accepted`。
3. 一分钟内，页面浏览量将显示在您的项目分析仪表板上。

## 收集了什么

浏览器发送页面 URL、来源地址， `navigator.languages`, 时区，以及屏幕宽度，加上每个标签页的会话 ID。服务器添加国家（来自 GeoIP）并计算与您的项目目标语言之间的本地化差距。未设置 Cookie 且没有任何内容被指纹追踪。
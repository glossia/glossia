%{
  title: "安装网站分析",
  summary: "通过一行 HTML 或通过 npm 将 Glossia 网页 SDK 添加到您的网站，并开始收集本地化信号。",
  category: "教程",
  order: 1
}
---
本指南假设您拥有一个 Glossia 项目，且其站点域名已配置在项目分析设置中。收集由该域名标识，因此无需复制密钥或机密。

## 选项 A：脚本标签

将此代码片段添加到每个页面，理想情况下在 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 会自动初始化，加载时发送页面浏览，并在单页应用的客户端导航中记录后续的页面浏览。 `data-domain` 默认为 `window.location.hostname` 省略时，您可以直接将其添加至单域名站点。若要使用自定义收集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

## 选项 B：npm

安装该包：

```bash
npm install @glossia/web
```

在您的应用程序入口点初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init();
```

该 `domain` 是基于...推断得出的 `window.location.hostname` 因此 SDK 会记录至为您站点注册的项目。传递 `{ domain: "example.com" }` 以覆盖，例如将来自暂存环境源的事件发送到与生产环境相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证它是否有效

1. 在浏览器中打开您的网站。
2. 打开网络标签页并确认一 `POST` 请求到 `/api/analytics/events` 返回 `202 Accepted`。
3. 一分钟内，页面浏览量将显示在您的项目分析仪表板上。

## 收集了什么

浏览器发送页面地址、来源， `navigator.languages`, 时区，以及屏幕宽度，加上每个标签页的会话 ID。服务器添加了国家（来自 GeoIP）并计算相对于项目目标语言的本地化差异。未设置 Cookie 且未进行指纹识别。
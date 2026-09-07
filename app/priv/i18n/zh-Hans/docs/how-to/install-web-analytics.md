%{
  title: "安装网站分析",
  summary: "通过一行 HTML 或通过 npm 向您的网站添加 Glossia web SDK，并开始收集本地化信号。",
  category: "教程",
  order: 1
}
---
本指南假设您已拥有一个 Glossia 项目，其站点域名已在项目的分析设置中配置。采集通过该域名标识，因此无需复制密钥或密码。

## 选项 A: 脚本标签

将此代码片段添加到每个页面，理想情况下在 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 会自动初始化，在加载时发送页面浏览事件，并在单页应用中的客户端导航时记录后续的页面浏览。 `data-domain` 默认为 `window.location.hostname` 省略时，因此您可以将其用于单域名站点。要使用自定义采集端点，请添加 `data-endpoint="https://collect.your-host.com"`.

## 选项 B: npm

安装该包：

```bash
npm install @glossia/web
```

在您的应用程序入口点初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init();
```

该 `domain` 由...推断得出 `window.location.hostname` 因此 SDK 会针对您站点的已注册项目记录。传递 `{ domain: "example.com" }` 以覆盖，例如将来自预发布环境的事件发送到与生产相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证其是否正常工作

1. 在浏览器中打开您的网站。
2. 打开网络标签页并确认一个 `POST` 请求发往 `/api/analytics/events` 返回 `202 Accepted`.
3. 一分钟内，页面浏览将出现在您的项目分析仪表盘中。

## 收集了什么

浏览器发送页面 URL、推荐源、 `navigator.languages`时区和屏幕宽度，以及每个标签页的会话 ID。服务器添加国家（来自 GeoIP）并计算与您的项目目标语言之间的本地化差距。未设置任何 Cookie，也不会进行指纹识别。
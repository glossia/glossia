%{
  title: "安装网站分析",
  summary: "通过一行 HTML 代码或借助 npm，将 Glossia web SDK 添加到您的网站，并开始收集本地化信号。",
  category: "教程",
  order: 1
}
---
本指南假设您拥有一个 Glossia 项目，其站点域名已在项目的分析设置中配置。收集通过该域名识别，因此无需复制密钥或秘密。

## 选项 A：脚本标签

将此代码片段添加到每个页面，最好在 `<head>`：

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 会自动初始化，页面加载时发送页面浏览，并在单页应用中客户端导航时记录后续页面浏览。 `data-domain` 默认为 `window.location.hostname` 省略时，您即可在单域名站点上使用。若要使用自定义收集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

## 选项 B：npm

安装包：

```bash
npm install @glossia/web
```

在应用入口点初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init();
```

该 `domain` 是从...推断出的 `window.location.hostname` 因此 SDK 会针对您网站注册的项目进行记录。传入 `{ domain: "example.com" }` 以覆盖，例如将来自预发布来源的事件发送到与生产环境相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证它是否生效

1. 在浏览器中打开您的网站。
2. 打开网络选项卡并确认一个 `POST` 请求发往 `/api/analytics/events` 返回 `202 Accepted`.
3. 一分钟内，页面浏览将出现在您的项目分析仪表板中。

## 收集了什么

浏览器会发送页面 URL、referrer， `navigator.languages`, 时区以及屏幕宽度，外加每个标签页的会话 ID。服务器会根据 GeoIP 添加国家信息，并根据您的项目目标语言计算本地化差距。未设置 Cookie，也未进行指纹识别。
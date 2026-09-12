%{
  title: "安装网站分析",
  summary: "通过一行 HTML 中或通过 npm 将 Glossia Web SDK 添加到您的网站，并开始收集本地化信号。",
  category: "教程",
  order: 1
}
---
本指南假设您拥有一个 Glossia 项目，其站点域名已在项目的分析设置中配置。收集通过该域名识别，因此无需复制密钥或秘密。

## 选项 A：script 标签

将此代码片段添加至每一页，理想情况下应位于 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 会自动初始化，在加载时发送页面浏览，并在单页应用内的客户端导航时记录后续页面浏览。 `data-domain` 默认为 `window.location.hostname` 若省略，则适用于单域名站点。若要使用自定义收集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

## 选项 B：npm

安装包：

```bash
npm install @glossia/web
```

在您的应用程序入口点初始化它一次：

```ts
import glossia from "@glossia/web";

glossia.init();
```

该 `domain` 是从...推断的 `window.location.hostname` 因此，SDK 会针对您站点注册的项目进行记录。传入 `{ domain: "example.com" }` 以覆盖，例如将来自预发环境的事件发送到与生产环境相同的项目。

要记录自定义事件，例如用户注册：

```ts
glossia.track("signup");
```

## 验证它是否可用

1. 在浏览器中打开你的网站。
2. 打开网络选项卡并确认一个 `POST` 请求至 `/api/analytics/events` 返回 `202 Accepted`。
3. 一分钟内，页面浏览量将在您的项目分析仪表板中显示。

## 已收集内容

浏览器发送页面 URL 和 referrer `navigator.languages`, 时区以及屏幕宽度、加上一个每标签页的会话 ID。服务器添加国家（来自 GeoIP）并计算与项目目标语言的本地化差距。未设置 cookie 也未进行指纹识别。
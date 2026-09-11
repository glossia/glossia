%{
  title: "安装网站分析",
  summary: "通过一行 HTML 代码或 npm 将 Glossia 网页 SDK 添加到您的网站，并开始收集本地化信号。",
  category: "教程",
  order: 1
}
---
本指南假设你拥有一个 Glossia 项目，且其站点域已在项目的分析设置中配置。数据收集依据该域名进行，因此不存在需要复制的密钥或密钥串。

## 选项 A：脚本标签

将此代码片段添加到每一页，最好在 `<head>`：

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 会自动初始化，加载时发送页面查看事件，并在单页应用的客户端导航中记录后续页面查看事件。 `data-domain` 默认为 `window.location.hostname` 省略时，可在单站点网站中使用。若要使用自定义收集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

## 选项 B：npm

安装该包：

```bash
npm install @glossia/web
```

首次在你的应用入口点初始化它：

```ts
import glossia from "@glossia/web";

glossia.init();
```

它 `domain` 由...推断得出 `window.location.hostname` 因此 SDK 会记录到您的站点注册项目。传入 `{ domain: "example.com" }` 以覆盖，例如将来自预发来源的事件发送至与生产环境相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证它是否正常工作

1. 在浏览器中打开您的网站。
2. 打开网络标签页并确认一个 `POST` 请求至 `/api/analytics/events` 返回 `202 Accepted`。
3. 一分钟内，页面浏览量将出现在您项目的分析仪表板中。

## 收集了什么

浏览器发送页面 URL、referrer、 `navigator.languages`时区以及屏幕宽度，加上每个标签页的会话 ID。服务器添加国家（来自 GeoIP）并计算您项目目标语言的本地化差距。不设置任何 Cookie，且不进行任何指纹识别。
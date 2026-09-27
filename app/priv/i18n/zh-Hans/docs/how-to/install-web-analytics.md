%{
  title: "安装网站分析",
  summary: "通过一行 HTML 代码或通过 npm 将 Glossia web SDK 添加到您的网站，并开始收集本地化信号。",
  category: "教程",
  section: "分析",
  order: 1
}
---
本指南假设您已拥有一个 Glossia 项目，并在项目分析设置中配置了其站点域名。数据收集由该域名标识，因此无需复制任何密钥或秘密。

## 选项 A：脚本标签

将此代码片段添加到每个页面，理想情况下置于 `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 会自动初始化，加载时发送页面浏览，并在单页应用中的客户端导航时记录后续的页面浏览。 `data-domain` 默认为 `window.location.hostname` 若省略则可直接用于单域网站。若要使用自定义收集端点，请添加 `data-endpoint="https://collect.your-host.com"`.

## 选项 B：npm

安装该包：

```bash
npm install @glossia/web
```

在您的应用入口点初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init();
```

该 `domain` 推断自 `window.location.hostname` 因此 SDK 会记录至您站点注册的项目。传入 `{ domain: "example.com" }` 以覆盖，例如将来自测试环境源的事件发送至与生产环境相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证功能是否正常

1. 在浏览器中打开您的网站。
2. 打开网络标签页并确认一个 `POST` 请求 `/api/analytics/events` 返回 `202 Accepted`。
3. 一分钟内，页面浏览记录将出现在您的项目分析仪表盘中。

## 收集内容

浏览器发送页面 URL 和 referrer， `navigator.languages`, 时区、屏幕宽度，以及每个标签页的会话 ID。服务器添加国家（来自 GeoIP）并计算与您项目目标语言的本地化差距。未设置 Cookie，也未进行指纹识别。
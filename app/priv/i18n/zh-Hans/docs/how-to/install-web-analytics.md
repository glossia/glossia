%{
  title: "安装网站分析",
  summary: "通过一行 HTML 或通过 npm 将 Glossia Web SDK 添加到您的网站，并开始收集本地化信号。",
  category: "教程",
  order: 1
}
---
本指南假设您拥有一个 Glossia 项目，其站点域名已在项目的分析设置中配置。收集由该域名标识，因此无需复制任何密钥或凭据。

## 选项 A：脚本标签

将此代码片段添加到每一页，理想情况下应位于 `<head>`：

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

SDK 自动初始化，加载时发送页面浏览，并在单页应用中的客户端导航时记录后续的页面浏览。 `data-domain` 默认为 `window.location.hostname` 省略时，所以您可以将其直接放置在单域名站点上。若要使用自定义收集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

## 选项 B：npm

安装此包：

```bash
npm install @glossia/web
```

在应用程序入口点初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init();
```

该 `domain` 是从...推断得出的 `window.location.hostname` 因此 SDK 会记录到您站点注册的项目中。传入 `{ domain: "example.com" }` 以覆盖，例如将来自测试源的事件发送至与生产环境相同的项目中。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 验证它是否有效

1. 在浏览器中打开您的站点。
2. 打开网络标签页并确认一个 `POST` 请求至 `/api/analytics/events` 返回 `202 Accepted`。
3. 一分钟内，页面浏览量将出现在您的项目分析仪表盘中。

## 收集的内容

浏览器发送页面 URL、referrer， `navigator.languages`, 时区、屏幕宽度，以及每个标签的会话 ID。服务器添加（来自 GeoIP）的国家，并计算与项目目标语言的本地化差距。不设置 cookie，且未创建指纹。
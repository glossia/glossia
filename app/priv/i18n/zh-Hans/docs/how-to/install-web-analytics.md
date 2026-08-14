%{
  title: "安装网站分析",
  summary: "使用一行 HTML 或通过 npm 将 Glossia Web SDK 添加到您的网站，并开始收集本地化信号。",
  category: "how-to",
  order: 1
}
---
本指南假设您已有一个 Glossia 项目，并已在项目的分析设置中配置网站域名。数据收集通过该域名识别，因此无需复制任何密钥或机密信息。

## 选项 A：script 标签

将以下代码段添加到每个页面，最好放在 `<head>` 中：

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

软件开发工具包会自动初始化，在页面加载时发送一次页面浏览事件，并在单页应用的客户端导航过程中记录后续页面浏览事件。省略 `data-domain` 时，其默认值为 `window.location.hostname`，因此单域名网站无需配置该项。若要自行托管收集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

## 选项 B：npm

安装软件包：

```bash
npm install @glossia/web
```

在应用入口点中初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init();
```

系统会根据 `window.location.hostname` 推断 `domain`，以便软件开发工具包将数据记录到为您的网站注册的项目中。传入 `{ domain: "example.com" }` 可覆盖该值，例如将预发布源站的事件发送到与生产环境相同的项目。

若要记录自定义事件，例如注册事件：

```ts
glossia.track("signup");
```

## 验证是否正常工作

1. 在浏览器中打开您的网站。
2. 打开网络面板，确认发送到 `/api/analytics/events` 的 `POST` 请求返回 `202 Accepted`。
3. 页面浏览事件将在一分钟内显示在项目的分析仪表板中。

## 收集的数据

浏览器会发送页面网址、来源网址、`navigator.languages`、时区和屏幕宽度，以及每个标签页独立的会话标识符。服务器会添加国家或地区信息（来自 GeoIP），并根据项目的目标语言计算本地化缺口。系统不会设置 Cookie，也不会进行任何指纹识别。
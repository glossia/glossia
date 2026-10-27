%{
  title: "安装网站分析",
  summary: "通过一行 HTML 或通过 npm，即可将 Glossia web SDK 添加到您的网站，并开始收集本地化信号。",
  category: "教程",
  section: "analytics",
  order: 1
}
---

本指南假设您拥有一个 Glossia 项目，并已在项目的分析设置中配置了其站点域。收集由该域确定，因此无需复制密钥或凭据。

## 选项 A：脚本标签

将此代码片段添加到每一页，理想情况下位于 `<head>`：

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 自动初始化，在加载时发送页面视图，并在单页应用中的客户端导航记录后续页面视图。`data-domain` 省略时默认为 `window.location.hostname`，因此您可以在单域站点上省略它。要使用自定义收集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

如果您的站点使用内容安全策略，请在 `script-src`（或当存在时 `script-src-elem`）及 `connect-src` 中均允许 `https://glossia.ai`。脚本从 `/assets/glossia-web.js` 加载，并将事件发送到同源的 `/v1/collect`。

## 选项 B：npm

安装包：

```bash
npm install @glossia/web
```

在您的应用程序入口点中初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

在使用该包于自己的构建包时，请显式设置收集端点，因为没有托管脚本地址可供推断。

`domain` 是从 `window.location.hostname` 推断的，因此 SDK 针对为您的站点注册的项目进行记录。要覆盖，请传递 `{ domain: "example.com" }`，例如将来自测试源的事件发送到与生产环境相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 追踪显式语言选择

为区分访客的选择与其浏览器偏好，请在导航之前在您的语言选择器用户操作处理器中调用 SDK：

```js
glossia.selectLanguage("zh-Hans");
```

在 `glossia.init()` 之后，此方法可用在导入的 SDK 上；使用托管脚本时，也可用在 `glossia` 全局上。

或者，标注同源语言切换链接：

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

每个操作仅使用一种集成，不要同时使用两种。标注的链接记录真实用户激活，包括键盘激活。它们会忽略脚本点击、下载、修改后的点击、跨源目标以及打开另一标签页或框架的链接，同时不会阻止导航。

SDK 立即发送 `language_selection` 事件，并在后续事件中包含所选语言（`cl`）。选择存储在 `sessionStorage` 中，直到当前标签页和源的另一个选择替代它。如果存储不可用，它仅持续到页面卸载。没有选择是从重定向、URL 或更改 `<html lang>` 推断的。

选择记录的是意图，而不是成功的导航。浏览器偏好、实际页面语言和显式选择保持独立。收集器在计算本地化差距时检查有效选择，而不是浏览器偏好。仅当选择匹配项目目标、宣传翻译或实际页面语言时，选择才能清除差距；不可用的所选语言仍有差距。缺失或无效的选择继续使用之前的浏览器偏好。仪表盘的总计和徽章使用每个事件存储的决策；历史标志保持不变。

## 验证您的域名

在您的项目的 **分析设置** 中，保存您的站点域。**验证域名所有权** 卡显示您项目的确切记录名称和值。使用您的域名提供商添加一条文本记录：

| 字段 | 值 |
| --- | --- |
| 类型 | `TXT` ([文本记录](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| 名称 | `_glossia-verify.example.com` |
| 值 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

使用设置中显示的域名和令牌。某些提供商会自动添加域名；在这种情况下，仅输入 `_glossia-verify` 作为名称。发布记录后，点击 **验证域名**。更改可能需要时间才能生效，如果立即找不到记录，请重试。

如果您无法编辑域名记录，请展开 **替代方案：通过主页 meta 标签验证**。将生成的标签复制到主页的 `<head>` 并发布：

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

两种方法都能证明对配置的域名有控制权。Glossia 检查该域名的记录或主页，因此将令牌复制到另一个网站不能验证所有权。令牌是公开证明，不是密码。

一旦域名已验证，Glossia 就会从您的跟踪代码片段中记录事件。代码片段本身不能验证所有权。更改配置的域名需要再次验证。

## 验证其有效性

1. 在浏览器中打开您的站点。
2. 打开网络标签页，并确认对 `https://glossia.ai/v1/collect` 的 `POST` 请求返回 `202 Accepted`。
3. 收集和处理后，页面视图出现在您项目的仪表板 **分析** 下。概览页面上进行的翻译与网站流量是分开的。

`202 Accepted` 响应确认请求已到达收集器。未知或未验证的域名也会被接受，但不记录事件，因此请确认配置域已在项目的分析设置中验证。

## 收集内容

浏览器发送页面 URL、referrer、`navigator.languages`、实际页面语言（`<html lang>`）、宣传翻译（`hreflang` 链接），以及观察到的显式选择语言、时区、屏幕宽度，以及每个标签页的 session ID。服务器添加国家（来自 GeoIP），并根据项目的目标语言、宣传翻译和实际页面语言计算本地化差距。session ID 和显式选择使用 `sessionStorage`；不设置 Cookie，也未进行指纹识别。

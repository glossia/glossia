%{
  title: "安装网站分析",
  summary: "只需一行 HTML 或通过 npm，即可为网站添加 Glossia Web SDK，并开始收集本地化信号。",
  category: "教程",
  section: "analytics",
  order: 1
}
---

本指南假设您拥有一个已在其项目分析设置中配置了网站域名的 Glossia 项目。收集通过该域名识别，因此无需复制密钥或凭据。

## 选项 A：script 标签

将此片段添加到每一页面，理想情况置于 `<head>` 中：

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

SDK 会自动初始化，加载时发送页面浏览，并在单页应用中进行客户端导航时记录随后的页面浏览。省略 `data-domain` 时默认为 `window.location.hostname`，因此您可以在单域网站中省去它。若要使用自定义收集端点，请添加 `data-endpoint="https://collect.your-host.com"`。

如果您的站点使用内容安全策略，请允许 `https://glossia.ai` 同时配置在 `script-src`（或 `script-src-elem` 如果存在）和 `connect-src` 中。脚本从 `/assets/glossia-web.js` 加载，并将事件发送到相同源处的 `/v1/collect`。

## 选项 B：npm

安装该包：

```bash
npm install @glossia/web
```

在您的应用程序入口点中初始化一次：

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

当在您自己的捆绑包中使用该包时，显式设置收集端点，因为没有托管的脚本地址可供推断。

`domain` 从 `window.location.hostname` 推断而出，因此 SDK 为您的站点注册的项目记录。传递 `{ domain: "example.com" }` 以重写，例如将事件从预发布源发送到与生产相同的项目。

要记录自定义事件，例如注册：

```ts
glossia.track("signup");
```

## 跟踪显式语言选择

为了区分访问者的选择与其浏览器偏好，请在导航之前，在您的语言选择器的用户操作处理器中调用 SDK：

```js
glossia.selectLanguage("zh-Hans");
```

此方法在 `glossia.init()` 之后的导入 SDK 中可用，且在使用托管脚本时可在 `glossia` 全局对象中可用。

或者，标注同源语言切换链接：

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

每次操作仅使用一种集成，不要两者都用。标注链接会记录真实的用户激活，包括键盘激活。它们忽略脚本点击、下载、修改点击、跨域目标以及打开另一个标签或框架的链接，而不会阻止导航。

SDK 会立即发送一个 `language_selection` 事件，并在后续事件中包括所选语言（`cl`）。该选择存储在 `sessionStorage` 中，直到另一个选择将其替换。如果存储不可用，它仅在页面卸载时生效。不会从重定向、URL 或对 `<html lang>` 的更改中推断选择。

选择记录意图，而非成功的导航。浏览器偏好、实际页面语言和显式选择保持独立。收集器存储选择；仪表盘的当前基于浏览器的差距计算保持不变。

## 验证您的域名

在您的项目的 **分析设置** 中，保存您的站点域名。**验证域名所有权**卡片显示您项目的确切记录名称和值。使用您的域名提供商添加文本记录：

| 字段 | 值 |
| --- | --- |
| 类型 | `TXT`（[文本记录](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)） |
| 名称 | `_glossia-verify.example.com` |
| 值 | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

使用您的设置中显示的域名和令牌。某些提供商会自动添加域名；在这种情况下，仅输入 `_glossia-verify` 作为名称。发布记录后，点击 **验证域名**。更改可能需要时间才能生效，所以如果记录未立即找到，请重试。

如果您无法编辑您的域名记录，请展开 **备选方案：通过主页元标签验证**。将生成的标签复制到主页 `<head>` 并发布：

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

任一方法均证明了您对该配置域的控制权。Glossia 检查该域的记录或主页，因此将令牌复制到另一个网站不会验证所有权。令牌是公开证明，而不是密码。

域名验证后，Glossia 将记录来自跟踪片段的收集事件。片段本身无法验证所有权。更改配置的域名需要再次验证。

## 验证其工作

1. 在浏览器中打开您的站点。
2. 打开网络标签页，确认一个 `POST` 请求到 `https://glossia.ai/v1/collect` 返回 `202 Accepted`。
3. 收集和处理后，页面浏览出现在您项目仪表盘的 **分析** 下。概览页面上的翻译运行与网站流量是分开的。

`202 Accepted` 响应确认请求到达了收集器。未知或未验证的域名也会被接受，但不记录事件，因此请确认控制台分析设置中配置的域名已验证。

## 收集什么

浏览器发送页面 URL、引荐网址、`navigator.languages`、实际页面语言（`<html lang>`）、推广翻译（`hreflang` 链接）、观察时的显式选择语言、时区和屏幕宽度，以及一个每选项卡会话 ID。服务器添加国家（来自 GeoIP），并根据项目的目标语言、推广翻译和实际页面语言计算本地化差距。会话 ID 和显式选择使用 `sessionStorage`；未设置 Cookie，也没有任何东西被指纹识别。

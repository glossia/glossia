%{
  title: "Install web analytics",
  summary: "Add the Glossia web SDK to your site with one line of HTML or via npm, and start collecting localization signals.",
  category: "how-to",
  section: "analytics",
  order: 1
}
---

This guide assumes you have a Glossia project with its site domain configured in the project's analytics settings. Collection is identified by that domain, so there is no key or secret to copy.

## Option A: script tag

Add this snippet to every page, ideally in the `<head>`:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

The SDK auto-initializes, sends a pageview on load, and records subsequent pageviews on client-side navigation in single-page apps. `data-domain` defaults to `window.location.hostname` when omitted, so you can drop it on a single-domain site. To use a custom collection endpoint, add `data-endpoint="https://collect.your-host.com"`.

If your site uses a content security policy, allow `https://glossia.ai` in both `script-src` (or `script-src-elem` when present) and `connect-src`. The script loads from `/assets/glossia-web.js` and sends events to `/v1/collect` on the same origin.

## Option B: npm

Install the package:

```bash
npm install @glossia/web
```

Initialize it once in your application entrypoint:

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });
```

Set the collection endpoint explicitly when using the package in your own bundle, since there is no hosted script address from which to infer it.

`domain` is inferred from `window.location.hostname` so the SDK records against the project registered for your site. Pass `{ domain: "example.com" }` to override, for example to send events from a staging origin to the same project as production.

To record a custom event, for example a signup:

```ts
glossia.track("signup");
```

## Track explicit language choices

To distinguish a visitor's choice from their browser preference, call the SDK in your language picker's user-action handler, before navigating:

```js
glossia.selectLanguage("zh-Hans");
```

This method is available on the imported SDK after `glossia.init()`, and on the `glossia` global when using the hosted script.

Alternatively, annotate same-origin language-switch links:

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

Use one integration per action, not both. Annotated links record genuine user activation, including keyboard activation. They ignore scripted clicks, downloads, modified clicks, cross-origin destinations, and links that open another tab or frame, without preventing navigation.

The SDK immediately sends a `language_selection` event and includes the chosen language (`cl`) on subsequent events. The choice is stored in `sessionStorage` for the current tab and origin until another choice replaces it. If storage is unavailable, it lasts only until the page unloads. No choice is inferred from redirects, URLs, or changes to `<html lang>`.

The selection records intent, not successful navigation. Browser preference, actual page language, and explicit choice remain separate. The collector stores the choice; the dashboard's current browser-based gap calculation is unchanged.

## Verify your domain

In your project's **Analytics settings**, save your site domain. The **Verify domain ownership** card shows the exact record name and value for your project. Add a text record with your domain provider:

| Field | Value |
| --- | --- |
| Type | `TXT` ([text record](https://www.cloudflare.com/learning/dns/dns-records/dns-txt-record/)) |
| Name | `_glossia-verify.example.com` |
| Value | `glossia-site-verification=YOUR_VERIFICATION_TOKEN` |

Use the domain and token shown in your settings. Some providers add the domain automatically; in that case enter only `_glossia-verify` as the name. After publishing the record, click **Verify domain**. Changes may take time to become available, so retry if the record is not found immediately.

If you cannot edit your domain records, expand **Alternative: verify with a homepage meta tag**. Copy the generated tag into the `<head>` of your homepage and publish it:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Either method proves control over the configured domain. Glossia checks that domain's record or homepage, so copying the token onto another website does not verify ownership. The token is public proof, not a password.

Once the domain is verified, Glossia records events from your tracking snippet. The snippet alone does not verify ownership. Changing the configured domain requires verification again.

## Verify it works

1. Open your site in a browser.
2. Open the network tab and confirm a `POST` request to `https://glossia.ai/v1/collect` returns `202 Accepted`.
3. After collection and processing, the pageview appears under **Analytics** in your project's dashboard. Translation runs on the Overview page are separate from website traffic.

A `202 Accepted` response confirms the request reached the collector. Unknown or unverified domains are also accepted but do not record events, so confirm the configured domain is verified in the project's analytics settings.

## What is collected

The browser sends the page URL, referrer, `navigator.languages`, actual page language (`<html lang>`), advertised translations (`hreflang` links), explicitly chosen language when observed, timezone, and screen width, plus a per-tab session id. The server adds the country (from GeoIP) and computes the localization gap against your project's target languages, advertised translations, and actual page language. The session id and explicit choice use `sessionStorage`; no cookies are set and nothing is fingerprinted.

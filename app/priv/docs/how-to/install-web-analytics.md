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

## Verify your domain

In your project's **Analytics settings**, save your site domain. Copy the generated verification meta tag into the `<head>` of your homepage and publish it:

```html
<meta name="glossia-site-verification" content="YOUR_VERIFICATION_TOKEN">
```

Use the token shown in your settings, then click **Verify domain**. Once the domain is verified, Glossia records events from your tracking snippet. The snippet alone does not verify ownership. Changing the configured domain requires verification again.

## Verify it works

1. Open your site in a browser.
2. Open the network tab and confirm a `POST` request to `https://glossia.ai/v1/collect` returns `202 Accepted`.
3. After collection and processing, the pageview appears under **Analytics** in your project's dashboard. Translation runs on the Overview page are separate from website traffic.

A `202 Accepted` response confirms the request reached the collector. Unknown or unverified domains are also accepted but do not record events, so confirm the configured domain is verified in the project's analytics settings.

## What is collected

The browser sends the page URL, referrer, `navigator.languages`, timezone, and screen width, plus a per-tab session id. The server adds the country (from GeoIP) and computes the localization gap against your project's target languages. No cookies are set and nothing is fingerprinted.

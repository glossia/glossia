%{
  title: "Install web analytics",
  summary: "Add the Glossia web SDK to your site with one line of HTML or via npm, and start collecting localization signals.",
  category: "how-to",
  order: 1
}
---

This guide assumes you have a Glossia project with its site domain configured in the project's analytics settings. Collection is identified by that domain, so there is no key or secret to copy.

## Option A: script tag

Add this snippet to every page, ideally in the `<head>`:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

The SDK auto-initializes, sends a pageview on load, and records subsequent pageviews on client-side navigation in single-page apps. `data-domain` defaults to `window.location.hostname` when omitted, so you can drop it on a single-domain site. To self-host the collect endpoint, add `data-endpoint="https://collect.your-host.com"`.

## Option B: npm

Install the package:

```bash
npm install @glossia/web
```

Initialize it once in your application entrypoint:

```ts
import glossia from "@glossia/web";

glossia.init();
```

The `domain` is inferred from `window.location.hostname` so the SDK records against the project registered for your site. Pass `{ domain: "example.com" }` to override, for example to send events from a staging origin to the same project as production.

To record a custom event, for example a signup:

```ts
glossia.track("signup");
```

## Verify it works

1. Open your site in a browser.
2. Open the network tab and confirm a `POST` request to `/api/analytics/events` returns `202 Accepted`.
3. Within a minute, the pageview appears in your project's analytics dashboard.

## What is collected

The browser sends the page URL, referrer, `navigator.languages`, timezone, and screen width, plus a per-tab session id. The server adds the country (from GeoIP) and computes the localization gap against your project's target languages. No cookies are set and nothing is fingerprinted.

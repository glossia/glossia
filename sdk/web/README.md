# @glossia/web

Cookieless, privacy-friendly web analytics that surfaces localization opportunities. Add one line of HTML and Glossia shows you which languages and countries your visitors actually want, and where you have a localization gap.

- **No cookies, no fingerprinting.** Nothing is stored on the visitor's device. Unique visitors are derived server-side from a daily-rotated hash that cannot be linked across days.
- **Localization-first.** Collects browser languages, country (GeoIP), referrer, and the pages underserved traffic lands on, so you can prioritize the next locale with data.
- **Tiny.** One small script, no dependencies, ships via `sendBeacon`.

## Install

### Snippet (no build step)

Add this to your site, setting `data-domain` to the site domain you registered in Glossia:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

The script auto-initializes and records pageviews, including on client-side navigation (single-page apps). Point `data-endpoint` at a self-hosted collect host if you don't use the Glossia CDN.

### npm

```bash
npm install @glossia/web
```

```ts
import glossia from "@glossia/web";

glossia.init({ domain: "example.com" });

// Record a custom event:
glossia.track("signup");
```

## What gets collected

Sent from the browser: page URL, referrer, `navigator.languages`, timezone, screen width, and a per-tab session id (in `sessionStorage`, cleared on close).

Derived on the server (never stored raw): a daily-rotated visitor id, country from GeoIP, device/browser/OS from the User-Agent, and the localization gap against your project's target languages.

## License

MIT

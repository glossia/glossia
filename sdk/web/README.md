# @glossia/web

Cookieless, privacy-friendly web analytics that surfaces localization opportunities. Add one line of HTML and Glossia shows you which languages and countries your visitors actually want, and where you have a localization gap.

- **No cookies, no fingerprinting.** Nothing is stored on the visitor's device. Unique visitors are derived server-side from a daily-rotated hash that cannot be linked across days.
- **Localization-first.** Collects browser languages, country (GeoIP), referrer, and the pages underserved traffic lands on, so you can prioritize the next locale with data.
- **Tiny.** One small script, no dependencies, ships via `sendBeacon`.

## Install

### Snippet (no build step)

Add this to your site:

```html
<script defer data-domain="example.com" src="https://glossia.ai/assets/glossia-web.js"></script>
```

The script auto-initializes and records pageviews, including on client-side navigation (single-page apps). `data-domain` is optional — when omitted, the SDK uses `window.location.hostname` to identify the project. Set `data-endpoint` to use a custom collection endpoint instead of the Glossia collector.

If your site uses a content security policy, allow `https://glossia.ai` in both `script-src` (or `script-src-elem` when present) and `connect-src`. The script sends events to `https://glossia.ai/v1/collect`.

### npm

```bash
npm install @glossia/web
```

```ts
import glossia from "@glossia/web";

glossia.init({ endpoint: "https://glossia.ai/v1/collect" });

// Record a custom event:
glossia.track("signup");
```

Set the collection endpoint explicitly when using the package in your own bundle, since there is no hosted script address from which to infer it.

`domain` is inferred from `window.location.hostname`. Pass `{ domain: "example.com" }` to override, for example to send events from a staging origin to the same project as production.

## What gets collected

Sent from the browser: page URL, referrer, `navigator.languages`, actual page language (`<html lang>`), available translations (`<link rel="alternate" hreflang="…">`, excluding `x-default`), timezone, screen width, and a per-tab session id (in `sessionStorage`, cleared on close).

Set `<html lang>` on every page so the dashboard can report the language actually served. Advertise translations with `hreflang` links so existing translations are recognized even without Glossia project setup targets. Visits without a reported page language are omitted from the browser-language breakdown, not inferred from the visitor's browser. Events from older tracker versions retain their original metadata.

Derived on the server (never stored raw): a daily-rotated visitor id, country from GeoIP, device/browser/OS from the User-Agent, and the localization gap against your project's target languages, advertised translations, and the page language.

## License

Source-available under the [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Use, modification, distribution, selling copies, and self-hosting are permitted under its terms. Directly competing hosted or managed services where the software's functionality is the service's primary value are prohibited. The npm package includes the license text and SDK source files. Source code is also available in the [Glossia repository](https://github.com/glossia/glossia/tree/main/sdk/web).

# @glossia/web

Cookieless, privacy-friendly web analytics that surfaces localization opportunities. Add one line of HTML and Glossia shows you which languages and countries your visitors actually want, and where you have a localization gap.

- **No cookies, no fingerprinting.** Only a per-tab session id and an explicitly selected language are kept in `sessionStorage`, with no cross-session identifier. Unique visitors are derived server-side from a daily-rotated hash that cannot be linked across days.
- **Localization-first.** Collects browser languages, country (GeoIP), referrer, and the pages underserved traffic lands on, so you can prioritize the next locale with data.
- **Tiny.** One small script, no dependencies. Events use credential-free keepalive fetch for external collectors, or `sendBeacon` on the same origin.

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

## Track explicit language choices

Call `selectLanguage()` from your language picker's user-action handler, before navigating:

```js
import glossia from "@glossia/web";

// After glossia.init(), inside the handler for a visitor's selection:
glossia.selectLanguage("zh-Hans");
```

The hosted script exposes the same method as `glossia.selectLanguage("zh-Hans")`.

For standard same-origin links, annotate the destination language instead. No JavaScript handler is needed:

```html
<a href="/zh-hans/docs" data-glossia-language="zh-Hans">简体中文</a>
```

The delegated listener also handles dynamically rendered links and nested labels. It records trusted primary clicks (including keyboard activation), not scripted clicks, downloads, modified clicks, cross-origin links, or links targeting another tab or frame. It does not prevent navigation. Do not call the API as well as annotating the same action, or you will record it twice.

Both integrations send a `language_selection` event immediately, with the choice in `cl`, and attach `cl` to later pageviews and custom events. Language tags are validated and canonicalized (for example, `zh-hans` becomes `zh-Hans`); invalid tags and API calls before initialization are ignored.

The choice lasts for the current tab's session on the same origin, until another choice replaces it. If `sessionStorage` is blocked or full, the SDK retains it in memory until the page unloads. It does not follow cross-origin navigation. A page language change or redirect alone never establishes an explicit choice.

The choice records intent, not proof that navigation succeeded. It stays separate from the browser preferences (`l`) and actual page language (`sl`), so a selection event on an English page can report `cl: "zh-Hans"` and `sl: "en"`. The collector stores it as `selected_locale`; it does not yet change the dashboard's browser-based gap calculation.

## What gets collected

Sent from the browser: page URL, referrer, `navigator.languages`, actual page language (`<html lang>`), available translations (`<link rel="alternate" hreflang="…">`, excluding `x-default`), explicitly chosen language when observed, timezone, screen width, and a per-tab session id (in `sessionStorage`, cleared on close).

Set `<html lang>` on every page so the dashboard can report the language actually served. Advertise translations with `hreflang` links so existing translations are recognized even without Glossia project setup targets. Visits without a reported page language are omitted from the browser-language breakdown, not inferred from the visitor's browser. Events from older tracker versions retain their original metadata.

Derived on the server (never stored raw): a daily-rotated visitor id, country from GeoIP, device/browser/OS from the User-Agent, and the localization gap against your project's target languages, advertised translations, and the page language.

## License

Open source under [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE). Commercial use, modification, distribution, self-hosting, and hosted services are permitted under its terms. The SDK contains no enterprise code. The npm package includes the complete Apache-2.0 license text and SDK source files. Source code is also available in the [Glossia repository](https://github.com/glossia/glossia/tree/main/sdk/web).

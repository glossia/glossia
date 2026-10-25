%{
  title: "Analytics SDK",
  summary: "The collected fields, the events endpoint, and the privacy model behind Glossia web analytics.",
  category: "reference",
  section: "analytics",
  order: 1
}
---

## Events endpoint

`POST https://glossia.ai/v1/collect`

`POST /api/analytics/events` remains available for compatibility. The hosted script derives `/v1/collect` from its own origin; package integrations should set `endpoint` explicitly.

Accepts a JSON event from the `@glossia/web` SDK. Always responds `202 Accepted`, including for unknown domains or malformed payloads, so the SDK never leaks which projects collect analytics.

The project is resolved by the site domain the snippet declares. `d` is authoritative; when it is absent the server falls back to the host of `u` (the page URL) and then the request `Origin`/`Referer`.

### Request body

| Field | Type   | Description                                                  |
|-------|--------|--------------------------------------------------------------|
| `d`   | string | Site domain that identifies the project (e.g. `example.com`). Sent by the browser library; fallback resolution is described above. |
| `n`   | string | Event name. Defaults to `pageview`.                          |
| `u`   | string | Page URL (`location.href`).                                  |
| `r`   | string | Referrer (`document.referrer`).                              |
| `l`   | string | Browser languages (`navigator.languages.join(",")`).         |
| `sl`  | string | Actual page language (`document.documentElement.lang`). Empty if undeclared. |
| `al`  | string | Comma-separated translation languages from `link[rel="alternate"][hreflang]`, excluding `x-default`. |
| `cl`  | string | Explicitly chosen language, or empty when no selection was observed. The SDK canonicalizes BCP 47 tags and limits input to 64 characters. |
| `tz`  | string | IANA timezone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Screen width in CSS pixels.                                  |
| `sid` | string | Per-tab session id (sessionStorage, cleared on close).       |

CORS is open (`Access-Control-Allow-Origin: *`) because the endpoint accepts no credentials.

## Explicit language selection

`selectLanguage(language)` is available as a named export, on the default SDK export, and on the hosted script's `glossia` global. Call it after initialization from a user-action handler, before navigation. Invalid language tags and calls before initialization are ignored.

The method sends a `language_selection` event immediately. Its `sl` still describes the current page, not the destination. Subsequent events include the choice in `cl` until another explicit choice replaces it. Without an observed selection, `cl` is empty. The choice is stored as `__glossia_selected_language` in same-origin, per-tab `sessionStorage`; when storage fails it is retained only in memory until unload.

For links, `data-glossia-language="zh-Hans"` enables delegated tracking of trusted, unmodified primary clicks, including keyboard activation. Scripted clicks, already cancelled clicks, downloads, cross-origin links, and links targeting another tab or frame are ignored. The listener runs in the capture phase before routers navigate, does not prevent navigation, and also handles dynamically inserted links. Use either the annotation or the API for an action, not both.

This is a client-reported intent signal, not proof that navigation succeeded. URL changes, redirects, and HTML language changes are not interpreted as choices. The selection does not override `l` or `sl`, or currently change `has_locale_gap` or dashboard badges.

## Server-derived fields

These are computed at ingestion and stored server-side. The raw IP and User-Agent are never stored.

| Field             | Source        | Description                                                         |
|-------------------|---------------|---------------------------------------------------------------------|
| `visitor_id`      | HMAC          | Daily-rotated hash of IP + UA + project. Not linkable across days.  |
| `country_code`    | Cloudflare / GeoIP | ISO 3166-1 alpha-2 code from a trusted `CF-IPCountry` header, or the configured IP geolocation adapter. Empty when neither resolves a country. |
| `device`          | User-Agent    | `desktop`, `mobile`, `tablet`, `bot`, or `unknown`.                 |
| `browser`         | User-Agent    | `chrome`, `safari`, `firefox`, `edge`, `opera`, or `unknown`.       |
| `os`              | User-Agent    | `windows`, `macos`, `ios`, `android`, `linux`, or `unknown`.        |
| `hostname`        | Page URL      | Lowercased host.                                                    |
| `pathname`        | Page URL      | Path component.                                                     |
| `referrer_source` | Referrer      | Referrer host, leading `www.`/`m.` stripped.                        |
| `browser_language`| Languages     | Most preferred normalized locale (e.g. `pt-BR`).                    |
| `served_locale`   | Page language | Normalized `sl`, or empty if it was not collected. Rows with an empty page language are omitted from the browser-language breakdown. |
| `selected_locale` | Explicit choice | Normalized `cl`, or empty for missing, malformed, or oversized input. Stored separately from browser preference and page language. |
| `has_locale_gap`  | Computed      | `1` when none of the visitor's preferred languages match the project targets, advertised translations (`al`), or page language (`sl`). Missing preferences do not count as a gap. |

### Client IP resolution

For requests from a private ingress peer, Glossia uses nginx's overwritten `X-Real-IP` header, not the caller-controlled first entry in `X-Forwarded-For`. Direct public connections use the socket address. On Hetzner, both the load balancer and nginx must enable PROXY protocol so nginx receives the visitor address instead of the load balancer address. Other reverse proxies must also overwrite `X-Real-IP` using an authenticated source, not an unrestricted inbound `X-Forwarded-For` header. The generic chart's forwarded-header policy alone does not guarantee this. Private peers are trusted infrastructure, so restrict direct pod access.

`GLOSSIA_TRUST_CLOUDFLARE_CLIENT_IP_HEADER=true` allows `CF-Connecting-IP` to override the canonical address for requests from a private ingress peer. It is **disabled by default**, independently of country-header trust. Enable it only after the edge authenticates Cloudflare or strips forged headers on requests bypassing Cloudflare. DNS-only deployments should leave it disabled. This address also keys IP rate limits and the daily visitor hash.

### Country resolution

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` enables the `CF-IPCountry` fast path. It is **disabled by default**. Enable it only after the origin authenticates Cloudflare, rejects requests that bypass Cloudflare, or the ingress strips untrusted copies of the header. Cloudflare's IP Geolocation setting must also be enabled for the zone. `CF-Connecting-IP`, `CF-Ray`, and nginx's `use-forwarded-headers` do not authenticate a request on their own.

When header trust is enabled, a single valid ISO country code is used immediately, without an IP lookup or cache access. The current edge value always takes precedence over any cached lookup. Missing, duplicate, malformed, or unknown codes, including Cloudflare's `XX` (unknown) and `T1` (Tor) values, fall back to the configured geolocation adapter.

Without a configured MaxMind database, fallback lookups use `api.ipapi.is`, then `api.country.is` when the primary request fails or returns no recognized country. Each request has a one-second connection and response timeout with retries disabled. Successful results from either provider are cached by Cachex for 24 hours, with a 100,000-entry scheduled size limit and automatic expiry reclamation. `Cachex.fetch/3` collapses concurrent misses for the same IP into one resolver. Failures are not cached. Private and reserved addresses are not sent to either provider.

### Missing page language

The browser-language breakdown omits events with no `sl`. This includes events collected by older tracker versions and pages without an HTML `lang` attribute. These events still contribute to overall traffic. The page language is not inferred from browser preferences or the URL. Historical events retain the metadata collected at the time; new tracker versions do not backfill them.

## Privacy model

- **No persistent cross-session identifier.** The SDK sets no cookies and stores only a per-tab session id and an explicitly selected language in `sessionStorage`, which the browser clears on close.
- **No fingerprinting.** Canvas, WebGL, font, and audio fingerprints are not collected. The daily-rotated server hash provides uniques without them.
- **No raw identifiers persisted.** IP and User-Agent are read once, hashed with a server secret and a daily salt, then discarded.
- **Per-project scoping.** The same browser on two projects yields unrelated visitor ids, so visitors cannot be tracked across Glossia customers.

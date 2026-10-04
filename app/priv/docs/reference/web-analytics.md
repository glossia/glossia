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
| `tz`  | string | IANA timezone (`Intl.DateTimeFormat().resolvedOptions().timeZone`). |
| `sw`  | number | Screen width in CSS pixels.                                  |
| `sid` | string | Per-tab session id (sessionStorage, cleared on close).       |

CORS is open (`Access-Control-Allow-Origin: *`) because the endpoint accepts no credentials.

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
| `served_locale`   | Page language | Normalized `sl`, or empty (shown as Not reported) if it was not collected. |
| `has_locale_gap`  | Computed      | `1` when none of the visitor's preferred languages match the project targets, advertised translations (`al`), or page language (`sl`). Missing preferences do not count as a gap. |

### Country resolution

`GLOSSIA_TRUST_CLOUDFLARE_COUNTRY_HEADER=true` enables the `CF-IPCountry` fast path. It is **disabled by default**. Enable it only after the origin authenticates Cloudflare, rejects requests that bypass Cloudflare, or the ingress strips untrusted copies of the header. Cloudflare's IP Geolocation setting must also be enabled for the zone. `CF-Connecting-IP`, `CF-Ray`, and nginx's `use-forwarded-headers` do not authenticate a request on their own.

When header trust is enabled, a single valid ISO country code is used immediately, without an IP lookup or cache access. The current edge value always takes precedence over any cached lookup. Missing, duplicate, malformed, or unknown codes, including Cloudflare's `XX` (unknown) and `T1` (Tor) values, fall back to the configured geolocation adapter.

Without a configured MaxMind database, fallback lookups use `api.ipapi.is`, then `api.country.is` when the primary request fails or returns no recognized country. Each request has a one-second connection and response timeout with retries disabled. Successful results from either provider are cached by Cachex for 24 hours, with a 100,000-entry scheduled size limit and automatic expiry reclamation. `Cachex.fetch/3` collapses concurrent misses for the same IP into one resolver. Failures are not cached. Private and reserved addresses are not sent to either provider.

### Missing page language

The dashboard displays **Not reported** when an event has no `sl`. This includes events collected by older tracker versions and pages without an HTML `lang` attribute. The page language is not inferred from browser preferences or the URL. Historical events retain the metadata collected at the time; new tracker versions do not backfill them.

## Privacy model

- **No persistent cross-session identifier.** The SDK sets no cookies and stores only a per-tab session id in `sessionStorage`, which the browser clears on close.
- **No fingerprinting.** Canvas, WebGL, font, and audio fingerprints are not collected. The daily-rotated server hash provides uniques without them.
- **No raw identifiers persisted.** IP and User-Agent are read once, hashed with a server secret and a daily salt, then discarded.
- **Per-project scoping.** The same browser on two projects yields unrelated visitor ids, so visitors cannot be tracked across Glossia customers.

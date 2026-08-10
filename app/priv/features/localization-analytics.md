%{
  title: "Localization analytics",
  summary: "See which languages and countries your visitors actually want, and where you have a localization gap, before you invest in a new locale.",
  order: 6,
  icon: "globe",
  hero_cta_text: "Get started",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Opportunity, not vanity", description: "Dashboards are built around the localization gap: the share of traffic that wants a language you don't yet serve.", icon: "globe"},
    %{title: "Cookieless by design", description: "No cookies, no fingerprinting, no consent banners. Unique visitors come from a daily-rotated hash that can't be linked across days.", icon: "zap"},
    %{title: "One line to install", description: "Drop a single script tag into your site and Glossia measures itself. Ship via npm or CDN.", icon: "code"}
  ]
}
---

## Decide your next locale with data

Most teams choose target languages on gut feel. Localization analytics replaces that with signal. Add the web SDK and Glossia shows you the languages your visitors' browsers request, the countries they come from, and, crucially, the overlap with the languages you already support.

The headline metric is the **localization gap**: the percentage of your visitors whose preferred language has no supported translation. Drill into it by country, by referrer, and by page to see exactly where underserved demand concentrates and which new locale would move the needle.

## Privacy without compromise

Glossia analytics collects nothing it doesn't need and stores nothing identifiable. The browser sends the page URL, referrer, preferred languages, timezone, and screen size. The server derives the unique visitor from a daily-rotated hash of the IP and User-Agent, then discards them. No cookies are set, nothing is fingerprinted, and no visitor can be tracked across days or across sites.

The result is analytics you can ship without a consent banner, aligned with the privacy expectations your international visitors already have.

## Install in seconds

Add one line to your site and Glossia starts measuring:

```html
<script defer data-domain="example.com" src="https://cdn.glossia.ai/web.js"></script>
```

Prefer npm? Install `@glossia/web` and call `init({ domain })`. Either way, pageviews, client-side navigation, and custom events flow into the same dashboard that ranks your localization opportunities.

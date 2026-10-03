%{
  title: "Why localization analytics",
  summary: "How the collected signals translate into localization decisions, and why the gap metric matters.",
  category: "explanation",
  section: "analytics",
  order: 2
}
---

Choosing which language to translate into next is a bet: it costs time and money, and the payoff depends on demand you usually can't see. Localization analytics makes that demand visible.

## The decision, not the dashboard

The point of collecting analytics here is narrow and deliberate: to answer "should we localize into language X?" The signals are chosen to feed that question, not to be a general-purpose analytics suite.

Three inputs drive the decision:

1. **Demand.** How many visitors want this language? Browser languages and country tell you where the interest is.
2. **The gap.** Is that demand already served? Comparing preferred languages against your project's target languages, the page's language, and its advertised translations reveals the share of traffic hitting a wall.
3. **Value.** Would localizing pay off? Engagement by locale gap, the pages underserved traffic lands on, and where that traffic comes from indicate whether a new locale converts.

## Why the gap is computed at ingestion time

`served_locale` records the actual page language declared in `<html lang>`, not the language we assume a visitor received. `has_locale_gap` compares browser preferences against your project targets, the page language, and translations advertised through `hreflang` links. Both are stored per event as they were at the time of the visit. This means historical data reflects the opportunity you faced then, not a recomputation against today's targets. If you add Portuguese next month, last month's gap doesn't retroactively shrink; you keep an honest record of how much demand was going unserved.

## Why cookieless, specifically

The instinct when you want "unique visitors" is to set a cookie or fingerprint the browser. Both create long-lived identifiers, and fingerprinting is, under most privacy regimes, harder to clear than a cookie. Neither is necessary here.

Unique visitors for a day only require an identifier that is stable *within the day*. A hash of the IP and User-Agent, rotated daily and scoped per project, supports daily visitor counts while making it impossible to link a visitor across days or across sites. This does not provide long-term returning-visitor tracking.

This design limits the identifiers retained by analytics. It does not establish whether a particular website requires consent; that depends on how the site uses analytics and the rules that apply to it.

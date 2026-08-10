%{
  title: "Why localization analytics",
  summary: "How the collected signals translate into localization decisions, and why the gap metric matters.",
  category: "explanation",
  order: 2
}
---

Choosing which language to translate into next is a bet: it costs time and money, and the payoff depends on demand you usually can't see. Localization analytics makes that demand visible.

## The decision, not the dashboard

The point of collecting analytics here is narrow and deliberate: to answer "should we localize into language X?" The signals are chosen to feed that question, not to be a general-purpose analytics suite.

Three inputs drive the decision:

1. **Demand.** How many visitors want this language? Browser languages and country tell you where the interest is.
2. **The gap.** Is that demand already served? Comparing preferred languages against your project's target languages reveals the share of traffic hitting a wall.
3. **Value.** Would localizing pay off? Engagement by locale gap, the pages underserved traffic lands on, and where that traffic comes from indicate whether a new locale converts.

## Why the gap is computed at ingestion time

`served_locale` and `has_locale_gap` are stored per event, computed against your target languages as they were at the time of the visit. This means historical data reflects the opportunity you faced then, not a recomputation against today's targets. If you add Portuguese next month, last month's gap doesn't retroactively shrink; you keep an honest record of how much demand was going unserved.

## Why cookieless, specifically

The instinct when you want "unique visitors" is to set a cookie or fingerprint the browser. Both create long-lived identifiers, and fingerprinting is, under most privacy regimes, harder to clear than a cookie. Neither is necessary here.

Unique visitors for a day only require an identifier that is stable *within the day*. A hash of the IP and User-Agent, rotated daily and scoped per project, gives accurate daily and weekly uniques while making it impossible to link a visitor across days or across sites. You give up long-term returning-visitor tracking, which is exactly the capability that creates the privacy exposure you'd otherwise need a consent banner to lawfully operate.

The trade-off is intentional: localization analytics should be something you can ship everywhere, to every visitor, without legal friction.

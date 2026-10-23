%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie die gesammelten Signale zu Lokalisierungsentscheidungen führen und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  section: "analytics",
  order: 2
}
---

Welche Sprache als Nächstes übersetzt wird, ist eine Wette: es kostet Zeit und Geld, und der Ertrag hängt von der Nachfrage ab, die man normalerweise nicht sieht. Lokalisierungsanalytik macht diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der Datensammlung hier ist eingegrenzt und gezielt: die Frage, ob wir in die Sprache X lokalisieren sollen. Die Signale sind so gewählt, dass sie diese Frage beantworten, nicht eine universell einsetzbare Analytik-Suite bilden.

Drei Faktoren steuern die Entscheidung:

1. **Nachfrage.** Wie viele Besucher wünschen sich diese Sprache? Browser-Sprachen und das Land verraten dir, wo das Interesse liegt.
2. **Die Lücke.** Wird diese Nachfrage bereits bedient? Der Vergleich der bevorzugten Sprachen gegen die Ziel-sprachen Ihres Projekts, die Sprachseite und die beworbenen Übersetzungen zeigt den Anteil des Verkehrs, der auf eine Wand stößt.
3. **Wert.** Zahlt sich Lokalisierung aus? Das Engagement durch die lokale Lücke, die Seiten, auf die der unterversorgte Verkehr aufmerksam wird, und woher dieser Verkehr stammt, zeigen an, ob eine neue Lokale funktioniert.

## Warum die Lücke zum Zeitpunkt der Datenerfassung berechnet wird

`served_locale` speichert die tatsächliche Seitensprache, die in `<html lang>` deklariert wurde, nicht die Sprache, die wir einem Besucher unterstellen. `has_locale_gap` vergleicht Browser-Präferenzen gegen Ihre Projektziele, die Seitensprache und Übersetzungen, die über `hreflang`-Links beworben werden. Beide werden pro Ereignis gespeichert, so wie sie zum Zeitpunkt des Besuchs waren. Das bedeutet, historische Daten spiegeln die Chance wider, die Sie damals sahen, nicht eine Neuberechnung gegen heutige Ziele. Wenn Sie nächsten Monat Portugiesisch hinzufügen, schrumpft die Lücke des letzten Monats nicht retroaktiv; Sie behalten einen ehrlichen Rekord über die Menge der unbedienten Nachfrage.

## Warum cookieless, insbesondere

Die Neigung für "unique visitors" besteht darin, ein Cookie zu setzen oder den Browser zu fempaschenen. Beide geben langlebige Identifikatoren, und Fingerprinting ist, unter den meisten Datenschutzregimen, schwieriger zu löschen als ein Cookie. Hier ist keines davon nötig.

Einzigartige Besucher für einen Tag erfordern nur einen Identifier, der *innerhalb des Tages* stabil ist. Ein Hash von IP und User-Agent, täglich rotiert und pro Projekt begrenzt, unterstützt die täglichen Besucherzahlen, macht es aber unmöglich, Besucher über Tage oder über Websites hinweg zu verknüpfen. Dies bietet keine langfristige Nachverfolgung von wiederkehrenden Besuchern.

Dieses Design begrenzt die von Analytik beibehobenen Identifikatoren. Es klärt nicht, ob eine bestimmte Website eine Zustimmung erfordert; das hängt davon ab, wie die Website Analytik verwendet und welche Regeln für sie gelten.

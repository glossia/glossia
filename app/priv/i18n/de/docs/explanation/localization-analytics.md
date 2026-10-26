%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie die gesammelten Signale in Entscheidungen zur Lokalisierung übersetzt werden und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  section: "analytics",
  order: 2
}
---

Die Wahl der Sprache, in die als Nächstes übersetzt werden soll, ist ein Wagnis: Es kostet Zeit und Geld, und der Ertrag hängt von der Nachfrage ab, die du normalerweise nicht siehst. Lokalisierungsanalysen machen diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Sinn der Einholung von Analysendaten hier ist eng und überlegt: um die Frage zu beantworten, ob wir in die Sprache X lokalisiert werden sollen. Die Signale wurden gewählt, um diese Frage zu unterstützen, nicht als allgemeine Analytik-Suite zu dienen.

Drei Faktoren treiben die Entscheidung an:

1. **Nachfrage.** Wie viele Besucher möchten diese Sprache? Browser-Sprachen und das Land zeigen dir, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits bedient? Der Vergleich der bevorzugten Sprachen mit den Sprachzielen deines Projekts, der Seitensprache und den beworbenen Übersetzungen zeigt, wie viel Verkehr auf ein Hindernis stößt.
3. **Wert.** Würde sich eine Lokalisierung lohnen? Engagement pro Lokalisierungslücke, die Seiten, auf die der unerfüllte Verkehrsstrom fällt und, woher dieser Strom stammt, zeigen an, ob eine neue Lokalisierung konvertiert.

## Warum die Lücke zum Zeitpunkt der Erfassung berechnet wird

`served_locale` dokumentiert die tatsächliche Seitensprache, die in `<html lang>` deklariert ist, nicht die Sprache, die wir einem Besucher unterstellen. `has_locale_gap` vergleicht Browsereinstellungen gegenüber den Projektzielen, der Seitensprache und den über `hreflang` beworbenen Übersetzungen. Beides wird pro Ereignis so gespeichert, wie es zum Zeitpunkt des Besuchs war. Das bedeutet, dass historische Daten die Chance widerspiegeln, die du damals hattest, nicht eine Neuberechnung gegen heutige Ziele. Wenn du nächsten Monat Portugiesisch hinzufügst, schrumpft die Lücke des letzten Monats nicht retroaktiv; du hältst ein ehrliches Protokoll darüber, wie viel Nachfrage unbedient war.

## Warum ohne Cookies, gezielt

Der Instinkt, wenn du "eindeutige Besucher" möchtest, ist, ein Cookie zu setzen oder den Browser zu fingerprinten. Beides erzeugt langfristige Kennungen, und das Fingerprinting ist, in den meisten Datenschutzregimen, schwieriger zu löschen als ein Cookie. Weder ist hier notwendig.

Eindeutige Besucher pro Tag erfordern nur eine Kennung, die *innerhalb des Tages* stabil ist. Ein Hash aus der IP und dem User-Agent, täglich rotiert und pro Projekt gebunden, unterstützt tägliche Besucherzahlen, während es unmöglich macht, einen Besucher über Tage oder über Seiten hinweg zu verbinden. Dies bietet keine langfristige Verfolgung von zurückkehrenden Besuchern.

Dieser Entwurf begrenzt die von der Analytik behaltene Kennungen. Es wird nicht festgestellt, ob eine bestimmte Website eine Einwilligung benötigt; das hängt davon ab, wie die Website die Analytik verwendet und welche Regeln für sie anwendbar sind.

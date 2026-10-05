%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie die gesammelten Signale zu Lokalisierungsentscheidungen führen und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  section: "analytics",
  order: 2
}
---
Die Wahl der nächsten Zielsprache ist ein Wagnis: Es kostet Zeit und Geld, und der Nutzen hängt von der Nachfrage ab, die Sie meist nicht sehen können. Lokalisierungs-Analytik macht diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck des hier gesammelten Analytik ist gezielt und überlegt: um zu antworten "sollten wir in Sprache X lokalisieren?" Die Signale sind gewählt, um diese Frage zu beantworten, nicht um eine allgemeine Analytik-Suite zu sein.

Drei Faktoren steuern die Entscheidung:

1. **Nachfrage.** Wie viele Besucher wünschen sich diese Sprache? Browser-Sprachen und Land verraten Ihnen, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits bedient? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts, der Sprache der Seite und den beworbenen Übersetzungen zeigt den Anteil des Trafficks, der an eine Mauer stößt.
3. **Wert.** Nützt Lokalisierung? Das Engagement-Gap nach Lokalisierungen, die Seiten, die ungedeckter Traffic auf sich ziehen, und die Herkunft dieses Traffics deuten darauf hin, ob eine neue Lokalisierung konvertiert.

## Warum die Lücke zur Aufnahmezeit berechnet wird

`served_locale` verzeichnet die tatsächlich deklarierte Seitensprache in `<html lang>`, nicht die Sprache, die wir einem Besucher unterstellen. `has_locale_gap` vergleicht Browser-Einstellungen mit Ihren Projekt-Zielen, der Seitensprache und Übersetzungen, die über `hreflang` Links. Beide werden pro Ereignis gespeichert, so wie sie zum Zeitpunkt des Besuchs waren. Das bedeutet, historische Daten spiegeln die Gelegenheiten wider, denen Sie damals entgegentraten, nicht eine Neuberechnung gegen heutige Ziele. Wenn Sie nächsten Monat Portugiesisch hinzufügen, schrumpft die Lücke des letzten Monats nicht retroaktiv; Sie halten ein ehrliches Register darüber, wie viel Nachfrage unbedient war.

## Warum cookieless, insbesondere

Der erste Gedanke beim Wunsch nach "einzigartige Besucher" besteht darin, ein Cookie zu setzen oder den Browser zu fingerprinten. Beide erstellen langlebige Identifikatoren, und das Fingerprinting ist unter den meisten Datenschutzregimen schwieriger zu löschen als ein Cookie. Beides ist hier nicht notwendig.

Einzigartige Besucher für einen Tag benötigen lediglich einen Identifikator, der stabil ist *innerhalb des Tages*. Ein Hash aus IP und User-Agent, der täglich rotiert und pro Projekt begrenzt ist, unterstützt die täglichen Besucherzahlen und verhindert das Verknüpfen eines Besuchers über Tage oder Websites hinweg. Dies bietet keine langfristige Verfolgung von Rückkehrern.

Dieses Design beschränkt die von Analytik gespeicherten Identifikatoren. Es wird nicht geklärt, ob eine bestimmte Website eine Einwilligung benötigt; dies hängt davon ab, wie die Website die Analytik nutzt und welche Regeln darauf anwendbar sind.
%{
  title: "Warum Lokalisierungsanalysen?",
  summary:
    "Wie die gesammelten Signale zu Lokalisierungsentscheidungen führen und warum die Lückenmetrik wichtig ist.",
  category: "Erklärung",
  section: "Analytik",
  order: 2
}
---
Die Entscheidung, in welche Sprache Sie als Nächstes übersetzen, ist ein Wagnis: Sie kostet Zeit und Geld, und der Gewinn hängt von einer Nachfrage ab, die Sie üblicherweise nicht erkennen können. Lokalisierungsanalysen machen diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der Datenerfassung hier ist eng und überlegt: um die Frage zu beantworten "sollten wir in Sprache X lokalisieren?". Die Signale wurden ausgewählt, um diese Frage zu beantworten, nicht als allgemeine Analysetool.

Drei Eingaben treiben die Entscheidung an:

1. **Nachfrage.** Wie viele Besucher wünschen sich diese Sprache? Browser-Sprachen und das Land geben Ihnen Aufschluss darüber, wo das Interesse liegt.
2. **Die Lücke.** Wird diese Nachfrage bereits bedient? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts zeigt den Anteil des Datenverkehrs, der auf eine nicht unterstützte Sprache stößt.
3. **Wert.** Lohnt sich das Lokalisieren? Der Engagement-Gap nach Region, die Seiten, die der unterversorgte Traffic erreicht, und die Herkunft dieses Traffics zeigen an, ob eine neue Lokalisierung konvertiert.

## Warum die Lücke zum Aufnahmezeitpunkt berechnet wird

`served_locale` und `has_locale_gap` werden pro Event gespeichert, berechnet gegen Ihre Zielsprachen wie sie zum Zeitpunkt des Besuchs waren. Das bedeutet, historische Daten spiegeln die zu diesem Zeitpunkt vorliegende Gelegenheit wider, nicht eine Neuberechnung gegen heutige Ziele. Wenn Sie im nächsten Monat Portugiesisch hinzufügen, schrumpft nicht die Lücke des letzten Monats retroaktiv; Sie bewahren eine ehrliche Aufzeichnung darüber, wie viel Nachfrage unversorgt war.

## Warum ohne Cookies, speziell

Der Reflex beim Wunsch nach "einzigartigen Besuchern" ist, ein Cookie zu setzen oder den Browser zu fingerprinten. Beides erzeugt langlebige Identifikatoren, und Fingerprinting ist im Rahmen der meisten Datenschutzbestimmungen schwieriger zu löschen als ein Cookie. Keines davon ist hier notwendig.

Einzigartige Besucher pro Tag erfordern lediglich einen Identifikator, der stabil ist. *innerhalb des Tages*. Ein Hash aus IP und User-Agent, der täglich rotiert und pro Projekt eingeschränkt ist, liefert genaue tägliche und wöchentliche Eindeutigkeiten, während es unmöglich macht, einen Besucher über Tage hinweg oder über Websites hinweg zu verknüpfen. Sie verzichten hiermit auf langfristige Nachverfolgung von wiederkehrenden Besuchern, was genau das Datenschutzrisiko darstellt, für das Sie sonst ein Einwilligungs-Banner benötigen würden, um rechtmäßig zu operieren.

Der Kompromiss ist beabsichtigt: Lokalisierungsanalysen sollten etwas sein, das Sie überall ausliefern können, an jeden Besucher, ohne juristische Hürden.
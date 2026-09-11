%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie die gesammelten Signale in Lokalisierungsentscheidungen umgesetzt werden und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  order: 2
}
---
Die Wahl der nächsten Zielsprache ist eine Wette: Sie kostet Zeit und Geld, und der Ertrag hängt von der Nachfrage ab, die man normalerweise nicht sieht. Lokalisierungsanalysen machen diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der hier gesammelten Analysen ist spezifisch und bewusst: um die Frage zu beantworten: "Sollten wir für Sprache X lokalieren?" Die Signale sind dazu gewählt, diese Frage zu beantworten, nicht als eine allgemeine Analytics-Suite zu dienen.

Drei Eingaben steuern die Entscheidung:

1. **Nachfrage.** Wie viele Besucher wünschen sich diese Sprache? Browser-Sprachen und Land verraten Ihnen, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits abgedeckt? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts offenbart den Anteil des Datenverkehrs, der auf eine Mauer stößt.
3. **Wert.** Lohnt sich Lokalisierung? Die Engagement-Lücke pro Locale, die Seiten, auf die unterversorgter Traffic landet, und die Herkunft dieses Traffic deuten darauf hin, ob eine neue Locale konvertiert.

## Warum die Lücke zum Zeitpunkt der Datenerfassung berechnet wird

`served_locale` und `has_locale_gap` werden pro Ereignis gespeichert, bezogen auf Ihre Zielsprachen, wie sie zum Zeitpunkt des Besuchs waren. Das bedeutet, historische Daten spiegeln die Gelegenheit wider, die Ihnen damals gegenüberstand, keine Neuberechnung nach gegenwärtigen Zielen. Wenn Sie Portugiesisch nächsten Monat hinzufügen, schrumpft die Lücke des Vormonats nicht rückwirkend; Sie bewahren eine ehrliche Aufzeichnung darüber, wie viel Nachfrage damals unerfüllt blieb.

## Warum cookieless, genauer gesagt

Der Impuls, wenn Sie "einzelne Besucher" verfolgen wollen, ist, ein Cookie zu setzen oder den Browser zu fingerprinten. Beide erzeugen langlebige Identifikatoren, und Fingerprinting ist unter den meisten Datenschutzbestimmungen schwerer zu löschen als ein Cookie. Keines ist hier notwendig.

Einzelbesucher für einen Tag erfordern lediglich einen stabilen Identifikator *innerhalb des Tages*„Ein Hash von IP und User-Agent, der täglich rotiert und pro Projekt eingeengt ist, liefert genaue tägliche und wöchentliche Eindeutigkeiten, macht aber unmöglich, einen Besucher über Tage hinweg oder zwischen Webseiten zu verknüpfen. Sie verzichten auf das langfristige Tracking wiederkehrender Besucher, was genau das Datenschutzrisiko ist, für das Sie sonst ein Einwilligungs-Banner benötigen würden, um rechtmäßig zu agieren.

Der Kompromiss ist beabsichtigt: Lokalisierungsanalysen sollten etwas sein, das Sie an jeden Besucher überall ausliefern können, ohne rechtliche Hürden.
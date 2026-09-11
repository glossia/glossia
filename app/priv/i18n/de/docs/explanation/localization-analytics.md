%{
  title: "Warum Lokalisierungsanalyse",
  summary:
    "Wie die gesammelten Signale zu Lokalisierungsentscheidungen führen und warum die Differenzmetrik wichtig ist.",
  category: "Erklärung",
  order: 2
}
---
Die Wahl der nächsten Übersetzungssprache ist ein Wagnis: Sie kostet Zeit und Geld, und der Ertrag hängt von einer Nachfrage ab, die Sie meist nicht sehen können. Lokalisierungsanalyse macht diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der Datensammlung hier ist gezielt und überlegt: um die Frage "Sollten wir auf Sprache X übersetzen?" zu beantworten. Die Signale sind ausgewählt, um diese Frage zu beantworten, nicht um eine allgemeine Analytik-Suite zu sein.

Drei Faktoren treiben die Entscheidung:

1. **Nachfrage.** Wie viele Besucher wünschen diese Sprache? Browser-Sprachen und Länder verraten Ihnen, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits gedeckt? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts zeigt den Anteil des Verkehrs, der auf eine Barriere stößt.
3. **Wert.** Lohnt sich die Lokalisierung? Engagement-Lücken nach Lokale, die Seiten, auf die der ungedeckte Traffic landet, sowie die Herkunft dieses Traffics zeigen an, ob eine neue Lokale konvertiert.

## Warum die Lücke zur Erfassungszeit berechnet wird

`served_locale` und `has_locale_gap` werden pro Ereignis gespeichert, berechnet gegenüber Ihren Zielsprachen, wie sie zum Zeitpunkt des Besuchs galten. Dies bedeutet, historische Daten spiegeln die Gelegenheit wider, der Sie damals gegenüberstanden, keine Neuberechnung gegenüber heutigen Zielen. Wenn Sie nächsten Monat Portugiesisch hinzufügen, schrumpft die Lücke des letzten Monats nicht rückwirkend; Sie behalten ein ehrliches Protokoll darüber, wie viel Nachfrage unversorgt war.

## Warum ohne Cookies, speziell

Der Impuls, wenn Sie "einzigartige Besucher" wünschen, besteht darin, ein Cookie zu setzen oder den Browser-Fingerabdruck zu erstellen. Beide erzeugen langlebige Identifikatoren, und Browser-Fingerprinting ist in den meisten Datenschutzregimen schwieriger zu löschen als ein Cookie. Hier ist keines notwendig.

Einzigartige Besucher für einen Tag erfordern lediglich einen stabilen Identifikator *innerhalb des Tages*. Ein Hash aus IP und User-Agent, der täglich und pro Projekt rotiert, liefert genaue tägliche und wöchentliche Uniques und macht es unmöglich, einen Besucher über Tage oder Seiten hinweg zu verknüpfen. Sie verzichten auf die langfristige Verfolgung von wiederkehrenden Besuchern, was genau die Fähigkeit ist, die das Datenschutzrisiko erzeugt, für das Sie sonst ein Einwilligungsbanner benötigen, um rechtmäßig zu agieren.

Der Kompromiss ist beabsichtigt: Lokalisierungsanalysen sollten etwas sein, das Sie überall für jeden Besucher bereitstellen können, ohne rechtliche Hürden.
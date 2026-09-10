%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie sich die gesammelten Signale in Lokalisierungsentscheidungen übersetzen und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  order: 2
}
---
Welche Sprache als Nächstes zu übersetzen ist ein Wagnis: Es kostet Zeit und Geld, und der Nutzen hängt von einer Nachfrage ab, die man meist nicht sieht. Lokalisierungsanalytik macht diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard.

Der Zweck der hier gesammelten Analysen ist gezielt und bewusst: um die Frage "sollten wir in Sprache X übersetzen?" zu beantworten. Die Signale wurden ausgewählt, um diese Frage zu dienen, nicht als allgemeine Analytik-Suite.

Drei Faktoren steuern die Entscheidung:

1. **Nachfrage.** Wie viele Besucher wünschen sich diese Sprache? Browsersprachen und Land zeigen, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits bedient? Der Vergleich bevorzugter Sprachen mit den Zielsprachen Ihres Projekts zeigt den Anteil des Verkehrs, der auf eine Barriere stößt.
3. **Wert.** Lohnt sich die Lokalisierung? Engagement-Lücken nach Lokale, die Seiten, auf die unbedienter Traffic landet, und die Herkunft dieses Traffics geben an, ob eine neue Lokale konvertiert.

## Warum die Lücke bei der Erfassung berechnet wird

`served_locale` und `has_locale_gap` werden pro Event gespeichert, anhand Ihrer Zielsprachen berechnet, wie sie zum Zeitpunkt des Besuchs galten. Das bedeutet, historische Daten spiegeln die Möglichkeiten wider, die Ihnen damals zur Verfügung standen, keine Neuberechnung anhand heutiger Ziele. Wenn Sie Portugiesisch nächsten Monat hinzufügen, schrumpft die Lücke des vergangenen Monats nicht rückwirkend; Sie behalten einen ehrlichen Rekord davon, wie viel Nachfrage unbedient blieb.

## Warum „ohne Cookies", im Speziellen

Der Instinkt, wenn Sie „einzigartige Besucher" wollen, besteht darin, ein Cookie zu setzen oder den Browser-Fingerabdruck zu erstellen. Beides erzeugt langlebige Identifikatoren, und Fingerprinting ist unter den meisten Datenschutzregimen schwieriger zu löschen als ein Cookie. Weder ist hier notwendig.

Einzigartige Besucher für einen Tag erfordern einen Identifikator, der stabil ist *innerhalb des Tages*. Ein Hash aus IP und User-Agent, der täglich rotiert und pro Projekt eingegrenzt wird, liefert genaue tägliche und wöchentliche Einzigartige Besucherzahlen und unterbindet gleichzeitig die Verknüpfung eines Besuchers über Tage oder zwischen Websites. Sie verzichten auf die langfristige Verfolgung von Wiederkehrgästen, was genau das Datenschutzrisiko darstellt, für das Sie sonst ein Einwilligungs-Banner benötigen würden, um rechtlich konform zu betreiben.

Der Kompromiss ist beabsichtigt: Lokalisierungs-Analysen sollten etwas sein, das Sie überall an jeden Besucher bereitstellen können, ohne rechtliche Hürden.
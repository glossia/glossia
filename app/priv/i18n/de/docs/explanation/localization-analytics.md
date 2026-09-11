%{
  title: "Warum Lokalisierungsanalyse",
  summary:
    "Wie die gesammelten Signale in Lokalisierungsentscheidungen umgesetzt werden und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  order: 2
}
---
Die Wahl, in welche Sprache Sie im nächsten Schritt übersetzen möchten, ist ein Wagnis: Sie kostet Zeit und Geld, und der Erfolg hängt von einer Nachfrage ab, die Sie meist nicht sehen können. Lokalisierungsanalysen machen diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der hier gesammelten Analysen ist schmal und gezielt: um die Frage zu beantworten: "Sollten wir in Sprache X lokalisieren?" Die Signale wurden ausgewählt, um diese Frage zu clärren, nicht als eine generische Analyse-Suite.

Drei Faktoren steuern die Entscheidung:

1. **Nachfrage.** Wie viele Besucher wünschen sich diese Sprache? Browser-Sprachen und Herkunftsland zeigen, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits abgedeckt? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts offenbart den Anteil des Traffics, der auf eine Mauer trifft.
3. **Wert.** Lohnt sich die Lokalisierung? Die Lücke im Engagement je nach Lokale, die Seiten, auf die unbedienter Traffic trifft, und die Herkunft dieses Traffics deuten darauf hin, ob eine neue Lokale konvertiert.

## Warum die Lücke beim Datenimport berechnet wird

`served_locale` und `has_locale_gap` werden pro Event gespeichert, berechnet gegenüber Ihren Zielsprachen, wie sie zum Zeitpunkt des Besuchs waren. Das bedeutet, historische Daten spiegeln die damals getroffene Chance wider, nicht eine Neuberechnung gegen heutige Ziele. Wenn Sie nächste Monat Portugiesisch hinzufügen, schrumpft die Lücke des Vormonats nicht rückwirkend; Sie behalten einen ehrlichen Überblick darüber, wie viel Nachfrage unbedient war.

## Warum genau cookieless?

Der Instinkt, wenn Sie "einzigartige Besucher" wollen, ist, ein Cookie zu setzen oder den Browser zu fingerprinten. Beide erzeugen lang anhaltende Identifikatoren, und Fingerprinting ist unter den meisten Datenschutzbestimmungen schwerer zu löschen als ein Cookie. Das ist hier nicht notwendig.

Einzigartige Besucher für einen Tag benötigen lediglich eine stabile Kennung *innerhalb des Tages*. Ein Hash aus IP und User-Agent, der täglich rotiert und pro Projekt begrenzt ist, liefert genaue tägliche und wöchentliche Einmalige Besucher, während es unmöglich macht, einen Besucher über Tage oder Seiten hinweg zu verknüpfen. Sie verzichten auf langfristige Verfolgung von Rückkehrern, was genau die Fähigkeit ist, die das Datenschutzrisiko darstellt, das Sie ansonsten für eine rechtmäßige Tätigkeit durch ein Einwilligungsbanner benötigen würden.

Der Kompromiss ist beabsichtigt: Lokalisierungsanalysen sollten etwas sein, das Sie überall für jeden Besucher bereitstellen können, ohne rechtliche Hürden.
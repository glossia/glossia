%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie die gesammelten Signale in Lokalisierungsentscheidungen übersetzt werden und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  order: 2
}
---
Die Wahl der nächsten Übersetzungsziel-Sprache ist eine Wette: Sie kostet Zeit und Geld, und der Ertrag hängt von der Nachfrage ab, die Sie normalerweise nicht sehen können. Lokalisierungsanalysen machen diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der Ermittelung von Analysen hier ist schmal und wohlüberlegt: Um die Frage zu beantworten „Sollten wir in Sprache X übersetzen?" Die Signale wurden ausgewählt, um diese Frage zu beantworten, nicht als eine Allzweck-Analysesuite zu dienen.

Drei Eingaben steuern die Entscheidung:

1. **Nachfrage.** Wie viele Besucher wünschen sich diese Sprache? Browser-Sprachen und das Land zeigen Ihnen, wo das Interesse liegt.
2. **Die Lücke.** Wird diese Nachfrage bereits gedeckt? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts zeigt den Anteil des Traffics, der an einer Hürde scheitert.
3. **Wert.** Würde sich das Lokalisieren auszahlen? Engagement je nach Locale-Lücke, die Seiten, die unbedienter Traffic trifft, und die Herkunft dieses Traffics deuten an, ob ein neues Locale konvertiert.

## Warum die Lücke bei der Datenaufnahme berechnet wird

`served_locale` and `has_locale_gap` werden pro Ereignis gespeichert, berechnet im Vergleich zu Ihren Zielsprachen etwa so, wie sie zum Zeitpunkt des Besuchs waren. Das bedeutet, historische Daten spiegeln die Gelegenheit wider, der Sie bisher gegenüberstanden, nicht eine Neuberechnung gegen die heutigen Ziele. Wenn Sie nächsten Monat Portugiesisch hinzufügen, schrumpft die Lücke des letzten Monats nicht retroaktiv; Sie behalten ein ehrliches Protokoll darüber, wie viel Nachfrage unbedient war.

## Warum ohne Cookies, speziell

Der Instinkt bei dem Wunsch nach „einzigartige Besucher" besteht darin, ein Cookie zu setzen oder den Browser abzubilden. Beides erstellt langfristige Identifier, und Fingerprinting ist, unter den meisten Datenschutzregimen, schwerer zu löschen als ein Cookie. Weder ist hier notwendig.

Einzigartige Besucher für einen Tag erfordern nur einen Identifikator, der *innerhalb des Tages* stabil ist. Ein Hash aus IP und User-Agent, täglich rotiert und je Projekt eingegrenzt, liefert genaue tägliche und wöchentliche Einheiten, während es unmöglich macht, einen Besucher über Tage oder über Sites hinweg zu verknüpfen. Sie verzich ten auf langfristiges Tracking von wiederkehrenden Besuchern, was genau die Fähigkeit ist, die das Datenschutzrisiko erzeugt, wenn Sie sonst ein Einwilligungsbanner benötigen würden, um rechtmäßig zu betreiben.

Der Kompromiss ist beabsichtigt: Lokalisierungsanalysen sollten etwas sein, das Sie überall senden können, an jeden Besucher, ohne rechtliche Reibung.
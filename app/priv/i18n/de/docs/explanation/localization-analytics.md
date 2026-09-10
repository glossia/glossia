%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie die gesammelten Signale in Lokalisierungsentscheidungen übersetzt werden und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  order: 2
}
---
Die Wahl der nächsten Zielübersetzungssprache ist ein Wagnis: Sie kostet Zeit und Geld, und der Ertrag hängt von einer Nachfrage ab, die Sie normalerweise nicht sehen können. Lokalisierungsanalytik macht diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Sinn der Datensammlung hier ist eng und bewusst: um die Frage "Sollten wir in Sprache X übersetzen?" zu beantworten. Die Signale sind ausgewählt, um dieser Frage zu dienen, nicht als eine allgemeine Analytik-Suite.

Drei Eingaben treiben die Entscheidung an:

1. **Nachfrage.** Wie viele Besucher wünschen diese Sprache? Browser-Sprachen und Länder verraten Ihnen, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits gedeckt? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts zeigt den Anteil des Datenverkehrs, der auf eine Mauer stößt.
3. **Wert.** Lohnt sich Lokalisierung? Die Engagement-Lücke je nach Lokale, die Seiten, auf die der unbediente Traffic landet, und die Herkunft dieses Traffics deuten an, ob eine neue Lokalisierung konvertiert.

## Warum die Lücke zum Zeitpunkt der Erfassung berechnet wird

`served_locale` und `has_locale_gap` sie werden pro Ereignis gespeichert, berechnet gegenüber Ihren Zielsprachen, wie sie zum Zeitpunkt des Besuchs waren. Dies bedeutet, dass historische Daten die damals vorliegenden Chancen widerspiegeln, keine Neuberechnung gegen heutige Ziele. Wenn Sie nächsten Monat Portugiesisch hinzufügen, schrumpft die Lücke des letzten Monats nicht retroaktiv; Sie behalten eine ehrliche Aufzeichnung darüber, wie viel Nachfrage unversorgt war.

## Warum cookieless, speziell

Wenn Sie "einzigartige Besucher" möchten, ist der Instinkt, ein Cookie zu setzen oder den Browser zu fingerprinten. Beide erzeugen langlebige Identifikatoren, und Fingerprinting ist unter den meisten Datenschutzregimen schwerer zu löschen als ein Cookie. Weder ist erforderlich.

Eindeutige Besucher für einen Tag erfordern lediglich einen stabilen Identifikator *innerhalb des Tages*. Ein Hash aus IP-Adresse und User-Agent, der täglich rotiert und pro Projekt eingegrenzt ist, liefert genaue tägliche und wöchentliche Eindeutigkeiten, während es unmöglich macht, einen Besucher über Tage oder Websites hinweg zu verknüpfen. Sie verzichten auf das langfristige Tracking von wiederkehrenden Besuchern, was genau die Fähigkeit ist, die das Datenschutzrisiko begründet, für das Sie sonst eine Einwilligungs-Banner benötigen, um rechtlich zu operieren.

Der Kompromiss ist beabsichtigt: Lokalisierungs-Analysen sollten etwas sein, das Sie überall, an jeden Besucher, ohne rechtliche Reibung bereitstellen können.
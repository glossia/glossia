%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie gesammelte Signale in Lokalisierungsentscheidungen übersetzt werden und warum die Gap-Metrik Bedeutung hat.",
  category: "Erklärung",
  order: 2
}
---
Die Wahl der nächsten Übersetzungssprache ist ein Wagnis: sie kostet Zeit und Geld, und der Nutzen hängt von der Nachfrage ab, die Sie normalerweise nicht sehen können. Lokalisierungsanalysen machen diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard.

Der Zweck der Datensammlung hier ist spezifisch und überlegt: um die Frage zu beantworten "Sollten wir in Sprache X lokalisieren?" Die Signale sind gewählt, um diese Frage zu beantworten, nicht als allzwecktaugliche Analytik-Suite.

Drei Faktoren steuern die Entscheidung:

1. **Nachfrage.** Wie viele Besucher wünschen sich diese Sprache? Browser-Sprachen und Land zeigen Ihnen, wo das Interesse liegt.
2. **Die Lücke.** Wird diese Nachfrage bereits bedient? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts zeigt den Anteil des Traffics, der auf eine Barriere stößt.
3. **Wert.** Zahlt sich Lokalisierung aus? Die Engagement-Lücke nach Sprache, die Seiten, auf die der nicht abgedeckte Traffic landet, und die Herkunft dieses Traffics zeigen, ob eine neue Sprache konvertiert.

## Warum die Lücke in der Ingestion-Zeit berechnet wird

`served_locale` und `has_locale_gap` werden pro Event gespeichert, berechnet gemessen an Ihren Zielsprachen, wie sie zum Zeitpunkt des Besuchs waren. Dies bedeutet, dass historische Daten das Potenzial widerspiegeln, das Sie damals hatten, keine Neuberechnung gegen heutige Ziele. Wenn Sie Portugiesisch nächsten Monat hinzufügen, schrumpft die Lücke vom letzten Monat nicht retroaktiv; Sie erhalten ein ehrliches Bild davon, wie viel Nachfrage ungedeckt blieb.

## Warum ohne Cookies, insbesondere

Der Instinkt, wenn Sie "eindeutige Besucher" wollen, ist, ein Cookie zu setzen oder den Browser zu fingerprinten. Beides erstellt langzeitstabile Identifikatoren, und Fingerprinting ist unter den meisten Datenschutzbestimmungen schwieriger zu löschen als ein Cookie. Beides ist hier nicht erforderlich.

Eindeutige Besucher für einen Tag erfordern lediglich einen stabilen Identifikator. *innerhalb des Tages*. Ein Hash der IP und User-Agent, der täglich rotiert und pro Projekt eingeschränkt ist, liefert genaue tägliche und wöchentliche Eindeutigkeiten und macht das Verknüpfen eines Besuchers über Tage oder Websites hinweg unmöglich. Sie verzichten auf die langfristige Verfolgung von Wiederbesuchern, was genau die Fähigkeit ist, die ein Datenschutzrisiko schafft und für die Sie sonst ein Einwilligungs-Banner benötigen würden, um rechtlich zu operieren.

Der Kompromiss ist bewusst: Lokalisierungsanalysen sollten etwas sein, das Sie überall an jeden Besucher bereitstellen können, ohne rechtliche Hürden.
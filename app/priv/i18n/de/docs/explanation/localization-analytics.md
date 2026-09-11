%{
  title: "Warum Lokalisierungsanalysen",
  summary:
    "Wie die gesammelten Signale zu Lokalisierungsentscheidungen führen, und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  order: 2
}
---
Die Wahl der nächsten Sprache für die Lokalisierung ist eine Wette: Sie kostet Zeit und Geld, und der Nutzen hängt von der Nachfrage ab, die Sie meist nicht sehen können. Lokalisierungs-Analytics macht diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der Analytik-Sammlung hier ist eng und absichtsvoll: Um die Frage zu beantworten: "Sollen wir in Sprache X lokalisiert werden?" Die Signale wurden ausgewählt, um genau diese Frage zu beantworten, nicht als Allzweck-Analytik-Suite.

Drei Eingaben treiben die Entscheidung an:

1. **Nachfrage.** Wie viele Besucher suchen diese Sprache? Browser-Sprachen und Länder zeigen, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits abgedeckt? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts enthüllt, welche Anteile des Web-Traffics auf eine Sprachbarriere treffen.
3. **Wert.** Lohnt sich die Lokalisierung? Engagement-Lücken nach Lokale, die Seiten, auf die unbehandelter Traffic ankommt, und die Herkunft dieses Traffics geben Aufschluss darüber, ob sich ein neues Lokale konvertiert.

## Warum die Lücke zum Zeitpunkt der Erfassung berechnet wird

`served_locale` und `has_locale_gap` werden pro Ereignis gespeichert, gegenüber Ihren Zielsprachen berechnet, wie sie zum Zeitpunkt des Besuchs waren. Dies bedeutet, dass historische Daten die damals bestehende Möglichkeit widerspiegeln, nicht eine Neuberechnung gegen die aktuellen Ziele. Wenn Sie nächsten Monat Portugiesisch hinzufügen, verkleinert sich die Lücke des Vormonats nicht retroaktiv; Sie führen einen ehrlichen Rekord darüber, wie viel Nachfrage unbehandelt war.

## Warum ohne Cookies, spezifisch

Der Instinkt bei dem Wunsch nach "einzigartigen Besuchern" besteht darin, ein Cookie zu setzen oder den Browser-Fingerabdruck zu erstellen. Beides erzeugt lang anhaltende Identifikatoren, und Fingerprinting ist unter den meisten Datenschutzregimen schwieriger zu löschen als ein Cookie. Hier ist weder das eine noch das andere notwendig.

Einzigartige Besucher für einen Tag erfordern lediglich eine stable Kennung. *innerhalb des Tages*. Ein Hash aus IP und User-Agent, der täglich rotiert und pro Projekt begrenzt ist, liefert genaue tägliche und wöchentliche Eindeutigkeiten, während eine Verknüpfung eines Besuchers über Tage oder zwischen Websites hinweg unmöglich wird. Sie verzichten auf langfristige Verfolgung wiederkehrender Besucher; dies entspricht genau dem Leistungsmerkmal, das das Datenschutzrisiko erzeugt, für das Sie sonst einen Einwilligungsbanner benötigen würden, um rechtmäßig zu operieren.

Der Kompromiss ist bewusst gemeint: Lokalisierungsanalysen sollten etwas sein, das Sie überall an jeden Besucher bereitstellen können, ohne rechtliche Hürden.
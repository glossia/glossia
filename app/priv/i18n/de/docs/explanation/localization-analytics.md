%{
  title: "Warum Lokalisierungsanalysen",
  summary: "Wie die erfassten Signale in Lokalisierungsentscheidungen einfließen und warum die Gap-Metrik von Bedeutung ist.",
  category: "Erklärung",
  order: 2
}
---
Die Entscheidung, in welche Sprache als Nächstes übersetzt werden soll, ist ein Wagnis: Sie kostet Zeit und Geld, und der Ertrag hängt von einer Nachfrage ab, die meist unsichtbar bleibt. Lokalisierungs-Analytics macht diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Das Ziel der Datenerfassung ist hierbei eng gesteckt und bewusst gewählt: die Frage zu beantworten, „Sollten wir in Sprache X lokalisieren?“. Die Signale sind so gewählt, dass sie direkt zu dieser Entscheidung beitragen, anstatt eine universelle Analytics-Suite bereitzustellen.

Drei Faktoren bestimmen diese Entscheidung:

1. **Nachfrage.** Wie viele Besucher bevorzugen diese Sprache? Browsersprachen und das Herkunftsland zeigen Ihnen, wo das Interesse liegt.
2. **Die Lücke.** Wird diese Nachfrage bereits bedient? Der Abgleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts zeigt, welcher Anteil des Traffics unbedient bleibt.
3. **Wert.** Würde sich eine Lokalisierung lohnen? Das Nutzer-Engagement nach Regionslücke, die Seiten, auf denen unbedienter Traffic landet, und die Herkunft dieses Traffics geben Aufschluss darüber, ob eine neue Sprache konvertiert.

## Warum die Lücke bereits beim Erfassen berechnet wird

`served_locale` und `has_locale_gap` werden pro Ereignis gespeichert und mit Ihren Zielsprachen zum Zeitpunkt des Besuchs abgeglichen. Das bedeutet, dass historische Daten das Potenzial widerspiegeln, dem Sie damals gegenüberstanden, und nicht nachträglich anhand der heutigen Zielsprachen neu berechnet werden. Wenn Sie im nächsten Monat Portugiesisch hinzufügen, verringert sich die Lücke des Vormonats nicht rückwirkend. Sie behalten ein unverfälschtes Protokoll darüber, wie viel Nachfrage unbedient blieb.

## Warum ausgerechnet ohne Cookies

Bei dem Wunsch nach „eindeutigen Besuchern“ liegt der Instinkt nahe, ein Cookie zu setzen oder ein Browser-Fingerprinting durchzuführen. Beide Methoden erzeugen langlebige Identifikatoren, und Fingerprinting ist unter den meisten Datenschutzbestimmungen schwieriger zu löschen als ein Cookie. Beides ist hier nicht erforderlich.

Eindeutige Besucher für einen Tag erfordern lediglich einen Identifikator, der *innerhalb dieses Tages* stabil bleibt. Ein Hash-Wert aus IP-Adresse und User-Agent, der täglich rotiert und auf das jeweilige Projekt beschränkt ist, liefert präzise tägliche und wöchentliche Besucherzahlen. Gleichzeitig wird es unmöglich gemacht, einen Besucher über mehrere Tage oder Websites hinweg zu verfolgen. Sie verzichten damit auf die langfristige Nachverfolgung wiederkehrender Besucher. Dies ist genau die Funktion, die Datenschutzrisiken birgt, für deren rechtmäßigen Betrieb Sie andernfalls ein Cookie-Banner benötigen würden.

Diese Abwägung ist bewusst gewählt: Lokalisierungs-Analytics sollte etwas sein, das Sie überall und für jeden Besucher ohne rechtliche Hürden einsetzen können.
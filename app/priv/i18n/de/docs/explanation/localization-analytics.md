%{
  title: "Warum Lokalisierungsanalytik",
  summary:
    "Wie die gesammelten Signale zu Lokalisierungsentscheidungen führen und warum die Gap-Metrik wichtig ist.",
  category: "Erklärung",
  order: 2
}
---
Die Entscheidung, welche Sprache als Nächstes übersetzt wird, ist ein Wagnis: Es kostet Zeit und Geld, und der Ertrag hängt von einer Nachfrage ab, die Sie in der Regel nicht erkennen können. Lokalisierungsanalytik macht diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der hier gesammelten Analytik ist gezielt und überlegt, um die Frage zu beantworten: "Sollten wir in die Sprache X übersetzen?" Die Signale wurden ausgewählt, um dieser Frage zu dienen, nicht um eine allgemeine Analytik-Suite zu sein.

Drei Eingaben steuern die Entscheidung:

1. **Nachfrage.** Wie viele Besucher möchten diese Sprache? Browser-Einstellungen und Länder zeigen, wo das Interesse liegt.
2. **Die Lücke.** Wird diese Nachfrage bereits gedeckt? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen Ihres Projekts zeigt den Anteil des Traffics, der auf eine Hürde stößt.
3. **Wert.** Lohnt sich die Lokalisierung? Engagement-Lücken nach Locale, die Seiten, auf die unterversorgter Traffic landet, und die Herkunft dieses Traffics zeigen, ob eine neue Locale konvertiert.

## Warum die Lücke bei der Datenaufnahme berechnet wird

`served_locale` und `has_locale_gap` werden pro Ereignis gespeichert, berechnet gegen Ihre Zielsprachen wie sie zur Zeit des Besuchs waren. Dies bedeutet, dass historische Daten die Gelegenheit widerspiegeln, die Sie damals hatten, nicht eine Neuberechnung gegen die heutigen Zielsprachen. Wenn Sie im nächsten Monat Portugiesisch hinzufügen, schrumpft die Lücke des letzten Monats nicht rückwirkend; Sie halten ein ehrliches Protokoll darüber, wie viel Nachfrage ungedeckt war.

## Warum cookieless, speziell

Der Instinkt, wenn du "einzigartige Besucher" willst, ist, ein Cookie zu setzen oder den Browser zu fingerprinten. Beide erstellen langlebige Identifikatoren, und Fingerprinting ist, bei den meisten Datenschutzbestimmungen, schwieriger zu löschen als ein Cookie. Weder ist hier notwendig.

Einzigartige Besucher für einen Tag erfordern lediglich einen stabilen Identifikator. *innerhalb des Tages*. Ein Hash aus IP und User-Agent, der täglich rotiert und pro Projekt eingeschränkt ist, liefert genaue tägliche und wöchentliche Eindeutigkeiten und macht eine Verknüpfung eines Besuchers über Tage oder Websites hinweg unmöglich. Sie verzichten auf das langfristige Verfolgen von wiederkehrenden Besuchern, was genau das Datenschutzrisiko ist, das Sie sonst benötigen würden, um rechtssicher zu operieren – das Einwilligungs-Banner.

Der Kompromiss ist beabsichtigt: Lokalisierungs-Analytics sollten etwas sein, das Sie überall und an jeden Besucher verteilen können, ohne rechtliche Hürden.
%{
  title: "Warum Lokalisierungs-Analytik",
  summary:
    "Wie die gesammelten Signale in Lokalisierungsentscheidungen umgesetzt werden und warum die Lückenmetrik wichtig ist.",
  category: "Erklärung",
  section: "analytics",
  order: 2
}
---

Die Wahl der nächsten Übersetzungssprache ist eine Wette: Sie kostet Zeit und Geld, und der Gewinn hängt von einer Nachfrage ab, die Sie in der Regel nicht sehen können. Lokalisierungsanalyse macht diese Nachfrage sichtbar.

## Die Entscheidung, nicht das Dashboard

Der Zweck der Datensammlung hier ist eng und durchdacht: um die Frage zu beantworten „Sollten wir in Sprache X lokalisiert werden?“. Die Signale sind so gewählt, um diese Frage zu zünden, nicht als allgemeine Analyseeinheit zu dienen.

Drei Faktoren treiben die Entscheidung an:

1. **Nachfrage.** Wie viele Besucher wünschen sich diese Sprache? Browser-Sprachen und Land berichten Ihnen, wo das Interesse liegt.
2. **Die Lücke.** Ist diese Nachfrage bereits bedient? Der Vergleich der bevorzugten Sprachen mit den Zielsprachen des Projekts, der Seitensprache und der angekündigten Übersetzungen zeigt den Anteil des Verkehrs auf, der an eine Mauer stößt.
3. **Wert.** Lohnt sich die Lokalisierung? Engagement durch Lücken, die Seiten, auf die unbedienter Traffic landet, und der Ursprung dieses Traffics deuten an, ob eine neue Sprach-Lokalsprache konvertiert.

## Warum die Lücke beim Erfassungszeitpunkt berechnet wird

`served_locale` registriert die tatsächliche Seitensprache, die in `<html lang>` angegeben ist, nicht die Sprache, die wir annehmen, dass ein Besucher erhalten hat. `has_locale_gap` vergleicht Browserpräferenzen gegenüber Ihren Projektzielen, der Seitensprache und Übersetzungen, die über `hreflang`-Links angezeigt werden. Beide werden pro Ereignis gespeichert, genau so wie sie zum Zeitpunkt des Besuchs vorlagen. Das bedeutet, dass historische Daten die Chance widerspiegeln, der Sie damals ausgesetzt waren, nicht eine Neuberechnung gegen heutige Ziele. Wenn Sie als nächsten Monat Portugiesisch hinzufügen, schrumpft die Lücke des Vormonats nicht retrospektiv; Sie behalten ein ehrliches Protokoll davon, wie viel Nachfrage unbedient blieb.

## Warum ohne Cookies, speziell

Die Intuition, wenn Sie „einzigartige Besucher" wollen, ist ein Cookie zu setzen oder den Browser zu fingerprinten. Beide schaffen langlebige Identifikatoren, und Fingerprinting ist unter den meisten Datenschutzregimen schwieriger zu löschen als ein Cookie. Beides ist hier nicht notwendig.

Einzigartige Besucher für einen Tag erfordern nur eine Identifikation, die stabil *innerhalb des Tages* ist. Ein Hash der IP und User-Agent, täglich aktualisiert und pro Projekt eingebaut, unterstützt tägliche Besucherzähler, macht es aber unmöglich, einen Besucher über Tage hinweg zu verknüpfen. Dies erlaubt keine langfristige Verfolgung von Wiederkehrenden.

Dieses Design begrenzt die Identifikatoren, die von der Analyse beibehalten werden. Es stellt nicht fest, ob eine bestimmte Website einer Einwilligung bedarf; das hängt davon ab, wie die Website Analysen verwendet und welche Regeln darauf anwendbar sind.

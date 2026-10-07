%{
  title: "Wiederherstellung von Übersetzungen",
  summary:
    "Wie Glossia Markdown intakt hält und sich von anbieterseitigem Throttling sowie unterbrochenen Übersetzungen erholt.",
  category: "Erklärung",
  section: "translation",
  order: 8
}
---
Glossia validiert den übersetzten Inhalt, bevor ihn veröffentlicht. Die Wiederherstellung bewahrt
diese Anforderung: ein Wiederholversuch muss die Quellstruktur und erforderliche
Platzhalter erhalten, und jede zusammengetratte Datei bestreitet ihre konfigurierbaren Validierungsbefehle.

## Markdown Übersetzung

Glossia rendert einen übersetzten Markdown-Dokument nie neu. Es analysiert die Quelle
nur zu seinen Prosa finden: Absätze, Überschriften, Listenpunkte, Tabellenzellen, die
Leser-analytischen Attribute von Komponenten und HTML (`title`, `details`, `alt`,
`label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), und
der Text eines HTML `<summary>`. Jede Übersetzung wird zurück in die exakte
Bytes ihrer Quelle geschrieben, so dass Code, Link-Bestimmungen, Komponenten, GitHub
Warnungen, explizite Überschriftenanker wie `{#install}`, Listenmarker und Leer
Zeilen Byte-für-Byte identisch bleiben.

Jeder Absatz oder Überschriften wird als einziger Satz übersetzt. Inline-Formatierung
wird nummerierte Tags: `<gN>...</gN>` um verknüpfte oder hervorgehobene Wörter, und
`<gN/>` für Inhalt, der nicht geändert werden darf, wie Inline-Code oder eine Komponente.
Das Modell kann Tags bewegen, um den Wortreihenfolge der Ziel-Sprache zu folgen, aber muss
jedes Tag genau einmal behalten. Jede Anfrage enthält auch das umgebende Quell
Dokument und die neuesten Übersetzungen desselben Dokuments, zum sich beziehen.

Eine Einheit, die ein Tag aufgibt oder erfunden, wird alleine erneut gesendet, mit dem Grund,
bis zu dreimal. Einheiten, die zurück-gültig kamen, wurden behalten. Nach Einfügen, Glossia
ordnet das Ergebnis und vergleicht seinen Bau zur Quelle. Eine Übersetzung, die
zu einem Überschriften, Listen oder Fokus sein könnte, hat seine Prosa entfliehen,
was keine weitere Modellaufruf benötigt.

## Katalog-Übersetzung

Gettext-Kataloge werden in Sätze zerlegt bevor Übersetzungen. Anfragen führen bei
meist acht Sätze, mit einem 8.000-Byte-Batch-Ziel. Eine einzelne größere Zeichenfolge
bleibt intakt. Das Modell gibt ein Array mit der gleichen Anzahl von Sätzen in der
gleichen Reihenfolge zurück. Glossia prüft Interpolationsvariablen und lehnt leere Übersetzungen ab.

Überschriften werden in Code mit den Pluralregeln der Ziel-Lokale gebaut. Quellnachrichten
Identifizier, Kommentare und Katalogstruktur stammen aus dem analysierten Quell. Wenn ein
Batch fehlerhaften Inhalt zurückgibt, wiederholt Glossia es einmal, dann teilt es in
kleinere Batches auf. Erfolgreiche benachbarte Batches müssen nicht erneut übersetzt werden.

## Anbieter-Drosselung

Glossia koordiniert Übersetzungsanfragen, die dasselbe Credential und Modell verwenden. Ein Rate-Limit
Antwort verlängert ihre gemeinsame Abkühmun und vergrößert den Abstand zwischen neuen Anfragen.
Erfolgreicher Verkehr reduziert diesen Abstand nach einer Minute ohne Drosselung allmählich.
Bereits ausgeführte Anfragen dürfen fertig gestellt werden.

Anbieter-Retry-Hinweise sind minimale Verzögerungen. Wiederholte Fehler erhöhen auch die
Rückkopplung, bis zu einer 30-Sekunden-Grundverzögerung plus Jitter; ein längerer Anbieter-Hinweis nimmt
Vorrang, begrenzt auf fünf Minuten. Together's `x-ratelimit-reset` Header ist
erkannt entlang `retry-after`.

Nach acht fehlgeschlagene Versuche stoppt der Repository-Ablauf das Starten neuer
Dateien. Eine verzögerte Fortsetzung erbt die Übersetzungs-Zweig und setzt seine
unvollendete Arbeit fort. Der vorherige Versuch bleibt in der Sessionshistorie sichtbar, verknüpft
durch die Fortsetzung. Verzögerungen erhöhen sich von einer bis fünf Minuten, mit
höchstens sechs automatischen Fortsetzungen. Neuere aktive Sessionen haben Vorrang, und
abgesagte Sessionen werden niemals wiedergekehrt. Validierungsfehler allein planen keine
Anbieter-Wiederherstellung.

## Langlebiger Fortschritt

Abgeschlossene Dateien und ihre Lockdateien werden in den Übersetzungszweig in
Chargen: ein Commit pro 25 Dateien, oder alle 15 Minuten, und ein finaler Commit
wenn der Lauf endet. Jeder Push führt die Pull Request-Prüfungen des Repositorys aus, sodass
Batching verhindert, dass bei einem großen Lauf pro Datei ein Check-Lauf gestartet wird. Ein Projekt hat
einen einzigen Übersetzungs-Pull Request: ein neuer Commit auf dem Standardzweig setzt
die offene fort, und übersetzt nur das, was seitdem geändert wurde. Sobald dieser Pull Request ist
vereinigt oder geschlossen, startet der nächste Lauf einen neuen. Bei unvollendeten Dateien werden lokal validierte Segmente und Wiederherstellungs-Chargen
werden ebenfalls in der Datenbank für sieben Tage gespeichert. Diese Checkpoints überstehen einen Worker
Prozessstopp. Sie beziehen sich auf das Konto, das Projekt, die Dokumenteneingabe,
wirksame Zugangsdaten und Modell, Kontext und Segment oder Reparaturversuch.

Eine wiederaufgenommene Ausführung kann ein Segment nur dann wiederverwenden, wenn seine Eingaben noch übereinstimmen. Es immer
validiert das finale zusammengefügtes Dokument erneut. Zurückgewiesene Modellantworten sind nicht
Checkpoints. Ein Validierungsfehler auf Dokumentebene startet einen separaten Reparaturversuch
weil der Validator möglicherweise nicht ein einzelnes verantwortliches Segment identifizieren kann.

Abgelaufene Checkpoints und inaktive Anbieter-Pacing-Aufzeichnungen werden vom
geplanten Sitzungsrecovery-Worker. Dies sind operationale Aufzeichnungen; Benutzer nicht
müssen sie in ihrem Repository hinzufügen oder sie in `L10N.md`.
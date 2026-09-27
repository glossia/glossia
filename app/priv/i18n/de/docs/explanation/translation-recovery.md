%{
  title: "Wiederherstellung von Übersetzungen",
  summary:
    "Wie Glossia von Anbieter-Drosselung und unterbrochenen Übersetzungen wiederhergestellt wird.",
  category: "Erklärung",
  section: "Übersetzung",
  order: 8
}
---
Glossia validiert übersetzten Inhalt, bevor es veröffentlicht wird. Wiederherstellung bewahrt
diese Anforderung: ein Wiederholungsversuch muss die Quellstruktur und erforderlichen
Platzhalter, und jede zusammengebaute Datei erfüllt ihre konfigurierten Validierungsbefehle.

## Katalogübersetzung

Gettext-Kataloge werden vor der Übersetzung in Strings zerlegt. Anfragen beinhalten bis
höchstens acht Strings, wobei das Batching-Ziel 8.000 Bytes beträgt. Eine einzelne längere Zeichenkette
bleibt erhalten. Das Modell gibt ein Array mit derselben Anzahl von Strings in der
Reihenfolge. Glossia prüft Interpolationsvariablen und lehnt leere Übersetzungen ab.

Die Header werden im Code mit den Pluralregeln der Zielsprache erstellt. Quellnachricht
Identifikatoren, Kommentare und Katalogstruktur stammen aus der geparsten Quelle. Wenn
ein Batch fehlerhafte Inhalte zurückgibt, versucht Glossia dies einmal neu, teilt es dann
in kleinere Batches auf. Erfolgreiche benachbarte Batches müssen nicht erneut übersetzt werden.

## Anbieter-Drosselung

Worker, die dieselben Zugangsdaten und das Modell verwenden, teilen sich die Anfragezulassung über die
Datenbank, einschließlich Worker auf verschiedenen Anwendungskopien. Eine Ratenbegrenzung
Antwort verlängert ihre gemeinsame Abkühlzeit und vergrößert den Abstand zwischen neuen Anfragen.
Erfolgreicher Traffic reduziert schrittweise diesen Abstand nach einer Minute ohne Drosselung.
Bereits laufende Anfragen dürfen abgeschlossen werden.

Provider-Retry-Hinweise sind minimale Verzögerungen. Wiederholte Fehler erhöhen ebenfalls den
Backoff, bis zu einer Basisverzögerung von 30 Sekunden plus Jitter; ein längerer Anbieter-Hint nimmt
Vorrang, begrenzt auf fünf Minuten. Gemeinsamen `x-ratelimit-reset` Header ist
erkannt neben `retry-after`.

Nach acht fehlgeschlagenen Anfrageversuchen stoppt der Repository-Lauf das Starten neuer
Dateien. Eine verzögerte Fortsetzung übernimmt den Übersetzungsast und setzt seine
unvollendete Arbeit. Der vorherige Versuch bleibt im Sitzungsverlauf sichtbar, verknüpft
durch die Fortsetzung. Die Verzögerungen steigen von einer Minute auf fünf Minuten, mit
höchstens sechs automatischen Fortsetzungen. Neuere aktive Sitzungen haben Priorität, und
abgebrochene Sitzungen werden niemals wiederbelebt. Validierungsfehler allein planen keine
Provider-Wiederherstellung.

## Dauerhafter Fortschritt

Abgeschlossene Dateien und ihre Sperrdateien werden im Übersetzungszweig veröffentlicht wie
zuvor. Bei unvollendeten Dateien werden lokal validierte Segmente und Wiederherstellungsbatches
ebenfalls in der Datenbank für sieben Tage gespeichert. Die Sicherungsstellen überstehen einen
Prozess stoppen. Sie beziehen sich auf das Konto, das Projekt, die Dokumenteneingabe,
gültige Berechtigung und Modell-, Kontext- und Segment- oder Reparaturversuch.

Eine Wiederaufnahme kann ein Segment nur wiederverwenden, wenn seine Eingaben weiterhin übereinstimmen. Es validiert
immer das final zusammengestellte Dokument erneut. Abgelehnte Modellantworten sind keine
Sicherungsstellen. Ein Dokumenten-Validierungsfehler startet einen separaten Reparaturversuch
weil der Validator möglicherweise nicht ein einzelnes, dafür zuständiges Segment identifizieren kann.

Abgelaufene Checkpoints und inaktive Provider-Pacing-Aufzeichnungen werden von dem
geplanten Sitzungs-Wiederherstellungsworker. Dies sind operative Datensätze; Benutzer müssen
nicht diese zu ihrem Repository hinzufügen oder sie in `L10N.md`.
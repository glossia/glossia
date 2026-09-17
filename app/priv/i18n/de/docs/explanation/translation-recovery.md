%{
  title: "Übersetzungswiederherstellung",
  summary:
    "Wie Glossia sich von der Anbieter-Drosselung und unterbrochenen Übersetzungen erholt.",
  category: "Erklärung",
  order: 8
}
---
Glossia validiert übersetzten Inhalt vor der Veröffentlichung. Wiederherstellung bewahrt
diese Anforderung: auch eine Wiederholung muss die Quellstruktur und erforderlichen
Platzhalter, und jede zusammengesetzte Datei erfüllt ihre konfigurierten Validierungsbefehle.

## Katalogübersetzung

Gettext-Kataloge werden vor der Übersetzung in Strings zerlegt. Anfragen enthalten
höchstens acht Strings, mit einem 8.000-Byte-Batching-Ziel. Ein einzelner größerer String
bleibt unversehrt. Das Modell gibt ein Array zurück mit der gleichen Anzahl von Strings in der
gleichen Reihenfolge. Glossia prüft Interpolationsvariablen und lehnt leere Übersetzungen ab.

Überschriften werden im Code mit den Pluralregeln des Ziellokals erstellt. Quellnachricht
Identifizierer, Kommentare und Katalogstruktur stammen aus der verarbeiteten Quelle. Wenn ein
Batch enthält fehlerhafte Inhalte. Glossia führt es einmal erneut aus und teilt es in
kleinere Batches. Erfolgreiche, benachbarte Batches müssen nicht erneut übersetzt werden.

## Anbieterdrosselung

Worker, die dieselben Zugangsdaten und das Modell nutzen, teilen sich die Zulassung durch die
Datenbank, einschließlich Worker auf verschiedenen Anwendungsrepliken. Ein Rate-Limit
Antwort verlängert ihre gemeinsame Abkühlzeit und vergrößert den Abstand zwischen neuen Anfragen.
Erfolgreicher Verkehr reduziert diesen Abstand nach einer Minute allmählich, ohne Throttling.
Bereits laufende Anfragen dürfen bis zum Abschluss laufen.

Provider-Retry-Hinweise sind minimale Verzögerungen. Wiederholte Fehler erhöhen ebenfalls den
Backoff, bis zu einer Basisverzögerung von 30 Sekunden plus Jitter; ein längerer Provider-Hinweis nimmt
Vorrang, maximal auf fünf Minuten begrenzt. Gemeinsamen `x-ratelimit-reset` Header ist
anerkannt zusammen mit `retry-after`.

Nach acht fehlgeschlagenen Anfrageversuchen stellt die Repository-Ausführung das Starten neuer
Dateien. Eine verzögerte Fortsetzung übernimmt den Übersetzungs-Zweig und setzt seine
unvollendete Arbeit. Der vorherige Versuch bleibt im Sitzungsverlauf sichtbar und verknüpft
durch die Fortsetzung. Verzögerungen steigen von einer auf fünf Minuten an, mit
höchstens sechs automatische Fortsetzungen. Neuere aktive Sitzungen haben Vorrang, und
abgebrochene Sitzungen werden nie wiederbelebt. Validierungsfehler allein planen nicht
Provider-Wiederherstellung.

## Dauerhafter Fortschritt

Erledigte Dateien und deren Sperrdateien werden im Übersetzungs-Branch als
davor. In unvollendeten Dateien werden lokal validierte Segmente und Wiederherstellungs-Batches
sie werden zusätzlich in der Datenbank für sieben Tage gespeichert. Diese Prüfpunkte überstehen einen Worker-Prozess-Stopp.
Stopp. Sie beziehen sich auf Konto, Projekt, Dokumenteneingabe,
gültigen Credential und Modell, Kontext und Segment oder Reparaturversuch.

Eine wiederaufgenommene Ausführung kann ein Segment nur erneut verwenden, wenn dessen Eingaben noch übereinstimmen. Es validiert immer
das fertige Dokument erneut. Abgelehnte Modellantworten sind keine
Prüfpunkte. Eine fehlerhafte Validierung auf Dokumentenebene startet einen separaten Reparaturversuch.
weil der Validator möglicherweise kein einzelnes verantwortliches Segment identifizieren kann.

Abgelaufene Checkpoints und inaktive Provider-Pacing-Aufzeichnungen werden vom
geplanten Sitzungs-Wiederherstellungs-Worker entfernt. Dies sind Betriebsaufzeichnungen; Benutzer müssen nicht
müssen sie zu ihrem Repository hinzufügen oder sie in `L10N.md`.
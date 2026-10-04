%{
  title: "Übersetzungswiederherstellung",
  summary: "Wie Glossia sich von Anbieter-Drosselung und unterbrochenen Übersetzungen erholt.",
  category: "Erklärung",
  section: "translation",
  order: 8
}
---
Glossia validiert übersetzten Inhalt, bevor dieser veröffentlicht wird. Die Wiederherstellung bewahrt
diese Anforderung: eine Wiederholung muss weiterhin die Quellstruktur und erforderliche
Platzhalter bewahrt, und jede zusammengebaute Datei führt ihre konfigurierten Validierungsbefehle ab.

## Katalogübersetzung

Gettext-Kataloge werden vor der Übersetzung in Strings zerlegt. Anfragen beinhalten an
maximal acht Strings, mit einem 8.000-Byte-Batching-Ziel. Eine einzelne größere String
bleibt intakt. Das Modell gibt ein Array zurück, mit der gleichen Anzahl von Strings im
gleichen Reihenfolge. Glossia prüft Interpolationsvariablen und lehnt leere Übersetzungen ab.

Header werden im Code mit den Pluralregeln des Ziellocales erstellt. Quellnachricht
Kennungen, Kommentare und Katalogstruktur stammen aus der geparsten Quelle. Wenn ein
Batch fehlerhafte Inhalte zurückgibt, versucht Glossia es einmal erneut, teilt es dann in
kleinere Batches. Erfolgreiche benachbarte Batches müssen nicht erneut übersetzt werden.

## Anbieterdrosselung

Glossia koordiniert Übersetzungsanfragen, die dieselben Credentials und das gleiche Modell nutzen. Eine Rate-Limit
Antwort verlängert ihre gemeinsame Abkühlphase und erhöht den Abstand zwischen neuen Anfragen.
Erfolgreicher Datenverkehr reduziert diesen Abstand schrittweise nach einer Minute ohne Drosselung.
Bereits laufende Anfragen dürfen abgeschlossen werden.

Provider-Wiederholungs-Hinweise sind Mindestverzögerungen. Wiederholte Fehlschläge erhöhen den
Backoff, bis zu einer Basisverzögerung von 30 Sekunden plus Jitter; ein längerer Provider-Hinweis hat
Vorrang, begrenzt auf fünf Minuten. Zusammen's `x-ratelimit-reset` Header ist
anerkannt neben. `retry-after`.

Nach acht fehlgeschlagenen Anfragemeldungen stoppt die Repository-Ausführung das Starten neuer
Dateien. Eine verzögerte Fortsetzung erbt den Übersetzungsbranch und setzt sein
unvollendete Arbeit. Der letzte Versuch bleibt in der Sitzungshistorie sichtbar, verknüpft
durch die Fortsetzung. Verzögerungen steigen von einer auf fünf Minuten, mit
höchstens sechs automatischen Fortsetzungen. Neuere aktive Sitzungen haben Vorrang, und
Abgebrochene Sitzungen werden nie wiederbelebt. Validierungsfehler allein planen nicht
Provider-Wiederherstellung.

## Dauerhafter Fortschritt

Abgeschlossene Dateien und ihre Lock-Dateien werden in den Übersetzungsbranch veröffentlicht als
davor. In unvollendeten Dateien werden lokal validierte Segmente und recovery batches
werden ebenfalls sieben Tage lang in der Datenbank gespeichert. Diese Checkpoints überstehen einen Worker
Prozess stoppt. Sie sind auf das Konto, das Projekt, die Dokumenteneingabe,
gültiges Credential, Modell, Kontext, Segment oder Reparaturversuch.

Eine wiederaufgenommene Ausführung kann ein Segment nur erneut verwenden, wenn seine Eingaben übereinstimmen. Immer
validiert das final zusammengeführte Dokument erneut. Abgelehnte Modellantworten sind keine
Checkpoints. Ein Validierungsfehler auf Dokumentebene initiiert einen separaten Reparaturversuch
da der Validator möglicherweise kein einzelnes verantwortlich Segment identifizieren kann.

Veraltete Checkpoints und inaktive Provider-Pacing-Aufzeichnungen werden vom
geplanten Sitzungs-Wiederherstellungs-Worker entfernt. Diese sind Betriebsaufzeichnungen; Benutzer müssen diese nicht
in ihr Repository hinzufügen oder in `L10N.md`.
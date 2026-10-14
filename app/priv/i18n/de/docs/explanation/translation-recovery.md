%{
  title: "Wiederherstellung der Übersetzung",
  summary:
    "Wie Glossia Markdown intakt behält und sich von Anbieter-Drosselungen sowie unterbrochenen Übersetzungen erholt.",
  category: "Erläuterung",
  section: "translation",
  order: 8
}
---

Glossia validiert übersetzten Inhalt, bevor dieser veröffentlicht wird. Die Wiederherstellung bewahrt diese Anforderung: Eine Wiederholung muss immer noch die Quellstruktur und erforderlichen Platzhalter bewahren, und jede zusammengestellte Datei wird ihren konfigurierten Validierungsbefehlen unterzogen.

## Markdown-Übersetzung

Glossia rendert ein übersetztes Markdown-Dokument nie neu. Es analysiert die Quelle nur zur Erkennung des Prosa-Inhalts: Absätze, Überschriften, Listenpunkte, Tabellenzellen, die leseorientierten Attribute von Komponenten und HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), und den Text eines HTML `<summary>`-Elements. Jeder Übersetzung wird das genaue Byte-Paket zurückgeschrieben, das seine Quelle besetzte, sodass Code, Link-Ziele, Komponenten, GitHub-Alarme, explizite Überschriften-Anchor wie `{#install}`, Listenmarker und Leerzeichen byte-for-byte identisch bleiben.

Jeder Absatz oder Abschnitt wird als ganzer Satz übersetzt. Inline-Formatierung wird zu nummerierten Tags: `<gN>...</gN>` um verlinkte oder hervorgehobene Wörter, und `<gN/>` für Inhalt, der sich nicht ändern darf, wie Inline-Code oder eine Komponente. Das Modell kann Tags verschieben, um der Wortordnung der Zielsprache zu folgen, muss aber jedes Tag genau einmal behalten. Jeder Aufruf enthält auch das umgebende Quelldokument und die jüngsten Übersetzungen aus demselben Dokument zur Nachbamuß.

Ein Block, der einen Tag verlässt oder erfindet, wird eigenständig erneut gesendet, mit dem Grund, bis zu dreimal. Volle Einheiten werden behalten. Nach dem Zuschnitt analysiert Glossia das Ergebnis und vergleicht dessen Struktur mit der Quelle. Eine Übersetzung, die in eine Überschrift, Liste oder Hervorhebung umwandelt wird, hat dessen Prosa entfliehen und benötigt keinen weiteren Modellaufruf.

## Katalogübersetzung

Gettext-Kataloge werden vor der Übersetzung in Zeichenfolgen geparst. Aufrufe übersetzen höchstens acht Zeichenfolgen, mit einem 8.000-Byte-Batch-Ziel. Eine einzelne größere Zeichenfolge bleibt intakt. Das Modell gibt ein Array mit derselben Anzahl an Zeichenfolgen in derselben Reihenfolge zurück. Glossia prüft Interpolationsvariablen und lehnt leere Übersetzungen ab.

Header werden in Code mit den Pluralregeln der Ziellokalität erstellt. Quell-Nachrichten-IDs, Kommentare und Katalogstruktur kommen von der analysierten Quelle. Wenn ein Batch fehlerhaften Daten enthält, versucht Glossia, es erneut, und teilt es dann in kleinere Batches auf. Erfolgreiche benachbarte Batches müssen nicht erneut übersetzt werden.

## Provider-Drosselung

Glossia koordiniert Übersetzungsaufrufe, die dasselbe Credential und Modell verwenden. Eine Ratenbegrenzungsantwort verlängert das gemeinsame Kühlzeitfenster und vergrößert den Abstand zwischen neuen Anfragen. Erfolgreicher Datenverkehr reduziert diesen Abstand nach einer Minute ohne Drosselung allmählich. Bereits laufende Aufrufe dürfen beendet werden.

Provider-Wiederholungs-Hinweise sind minimale Verzögerungen. Wiederholte Fehler erhöhen ebenfalls das Backoff auf ein 30-Sekunden-Grundverzögerungsplus-Jitter. Ein längerer Provider-Hinweis hat Vorrang, begrenzt auf fünf Minuten. Die Together-`x-ratelimit-reset`-Header wird neben `retry-after` erkannt.

Nach acht fehlgeschlagenen Aufrufrufen hört der Repositorienlauf auf, neue Dateien zu starten. Ein verzögerter Fortschritt erbt die Übersetzungsverzweigung und setzt unvollendetes Werk fort. Der frühere Versuch bleibt in der Sitzungsgeschichte sichtbar, verlinkt durch den Fortschritt. Verzögerungen steigen von einer auf fünf Minuten, mit maximal sechs automatischen Fortschritten. Jüngere aktive Sitzungen haben Vorrang, abgebrochene Sitzungen werden nie wiederbelebt. Validierungsfehler allein beeilen keinen Provider-Recovery.

## Dauerhafter Fortschritt

Erfolgte Dateien und ihre Lockfiles werden in Batches zur Übersetzungsverzweigung veröffentlicht: ein Commit für alle 25 Dateien oder alle 15 Minuten, und ein abschließender Commit, wenn der Lauf endet. Jeder Schub führt die Zug-Anfragen-Prüfungen des Repositorys aus, sodass Batching einen großen Lauf davon hält, einen Pfif per File zu starten. Ein Projekt hat eine einzige Übersetzungs-Zug-Anfrage: ein neuer Commit in der Standardverzweigung verlängert die offene, und übersetzt nur das, was seitdem geändert wurde. Sobald Zug-Anfrage verschmolzen oder geschlossen ist, startet der nächste Lauf einen neuen. Innerhalb unvollender Dateien werden lokal-validierte Segmente und Recovery-Batches ebenfalls sieben Tage im Speicher gespeichert. Diese Kontrollpunkte überstehen einen Worker-Prozess-Stopp. Sie sind auf Konto, Projekt, Eingabe-Dokument, gültiges Credential und Modell, Kontext und Segment oder Reparatur-Versuch begrenzt.

Ein fortgesetzter Lauf kann ein Segment nur wiederverwenden, wenn seine Eingaben immer noch passen. Er validiert das endgültige assemblierte Dokument erneut. Abgelehnte Modell-Antworten sind keine Kontrollpunkte. Ein Dokuments-Upgrade-Validierungsstart beginnt einen Reparatur-Versuch, weil der Validator eventuell nicht eine einzige verantwortliche Segment-ID identifizieren kann.

Überfällige Kontrollpunkte und inaktive Provider-Pacing-Aufzeichnungen werden vom geplanten Sitzung-Recovery-Worker entfernt. Dies sind Operationsaufzeichnungen; Benutzer müssen sie nicht in ihr Repository hinzufügen oder in `L10N.md` konfigurieren.

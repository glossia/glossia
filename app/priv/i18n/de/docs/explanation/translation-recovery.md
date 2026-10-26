%{
  title: "Übersetzungswiederherstellung",
  summary:
    "Wie Glossia Markdown intakt hält und sich von Provider-Drosselung sowie unterbrochenen Übersetzungen erholt.",
  category: "Erklärung",
  section: "translation",
  order: 8
}
---

Glossia validiert den übersetzten Inhalt vor der Veröffentlichung. Die Wiederherstellung bewahrt diese Anforderung: Ein neuer Versuch muss weiterhin die Quellstruktur und erforderlichen Platzhalter erhalten, und jede zusammengebaute Datei durchläuft ihre konfigurierten Validierungsbefehle.

## Markdown-Übersetzung

Glossia rendert ein übersetztes Markdown-Dokument niemals neu. Es durchsucht die Quelle nur nach Inhalt: Absätzen, Abschnitten, Listenpunkten, Tabellenzellen, sichtbaren Attributen von Komponenten und HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), sowie dem Text eines HTML-Elements `<summary>`). Jede Übersetzung wird unter denselben Byte zurückgeschrieben, die ihre Quelle beanspruchte, so dass Code, Ziel-Links, Komponenten, GitHub-Benachrichtigungen, explizite Abschnittsanker wie `{#install}`, Listenmarker und leere Zeilen buchstäblich identisch bleiben.

Jeder Absatz oder Abschnitt wird als vollständiger Satz übersetzt. Inline-Formatierung verwandelt sich in nummerierte Tags: `<gN>...</gN>` umfassen verlinkte oder fettgedruckte Wörter, und `<gN/>` für Inhalte, die nicht verändert werden dürfen, wie beispielsweise Inline-Code oder eine Komponente. Das Modell kann Tags verschieben, um der Wortreihenfolge der Zielsprache zu folgen, muss dabei aber jedes Tag genau einmal erhalten. Jede Anfrage enthält zudem das umgebende Quelldokument und die neuesten Übersetzungen aus derselben Datei zur Referenz.

Eine Einheit, die ein Tag weglässt oder erfährt, wird eigenständig, mit dem Grund, bis zu dreimal erneut gesendet. Einheiten, die als gültig zurückgekommen sind, werden beibehalten. Nach dem Zusammenfügen durchsucht Glossia das Ergebnis und vergleicht seine Struktur mit der Quelle. Eine Übersetzung, die per se zu einem Abschnitt, einer Liste oder einer Hervorhebung umgewandelt würde, hat ihre Inhalte entflohen, was keinen weiteren Modellaufzug erfordert.

## Katalogübersetzung

Gettext-Kataloge werden vor Übersetzung in Sätze zerlegt. Anfragen übernehmen maximal acht Sätze, mit einem Ziel von 8.000 Byte pro Batch. Größere einzelne_strings bleiben intakt. Das Modell gibt ein Array zurück, dass dieselbe Anzahl an Sätzen in derselben Reihenfolge enthält. Glossia prüft Interpolationsvariablen und verwerft leere Übersetzungen.

Köpfe werden im Code unter Verwendung der Pluralregeln der jeweiligen Ziel-Sprache erzeugt. Quelldienst-IDs, Kommentare und Katalogstruktur stammen aus dem geparsten Quelltext. Falls ein Batch fehlerhaften Inhalt zurückgibt, versucht Glossia es einmal erneut, teilt ihn dann in kleinere Batches auf. Erfolgreiche benachbarte Batches müssen nicht erneut übersetzt werden.

## Provider-Drosselung

Glossia koordiniert Übersetzungsanfragen, die dasselbe Credential und Modell verwenden. Eine Rate-Limit-Antwort verlängert ihr gemeinsames Auskühlen und vergrößert die Distanz zwischen neuen Anfragen. Erfolgreicher Verkehr verringert diese Distanz allmählich nach einer Minute, ohne Drosselung. Bereits laufende Anfragen dürfen abgeschlossen werden.

Provider-Wiederholungs-Tipps sind Mindestverzögerungen. Wiederholte Fehler erhöhen zudem das Zurückstellen, bis zu einer Basisverzögerung von 30 Sekunden plus Zufall; ein längerer Provider-Tipp hat Vorrang, begrenzt auf fünf Minuten. Together’s `x-ratelimit-reset`Header wird neben `retry-after` erkannt.

Nach acht erfolglosen Versuchsanfragen stoppt die Repository-Laufenz neue Dateien zu starten. Eine verzögerte Fortsetzung erbt den Übersetzungs-Zweig und setzt ihre unvollendete Arbeit fort. Der vorherige Versuch bleibt in der Sitzungsgeschichte sichtbar, verknüpft durch die Fortsetzung. Verzögerungen steigen von einer Minute auf fünf Minuten, mit höchstens sechs automatischen Fortsetzungen. Neuere aktive Sitzungen nehmen Vorrang, abgebrochene Sitzungen werden nie wiederbeleut. Nur Validierungsfehler planen keine Provider-Wiederherstellung.

## Wiederherstellung nach einem Engine-Release

Eine Sitzung hat zwei unabhängige Versionen: den Repository-Kommission, der gerade übersetzt wird, und das Übersetzungs-Engine-Image, das ihn ausführt. In Kubernetes festschreibt jede Aufgabe exakt den Image-Digest der Web-Replica, die sie geplant hat. Aufgaben überstehen Web-Rollouts und wechseln niemals zwischen Code mitten in der Übersetzung. Eine Aufgabe, die kurz vor einem Rollout geplant wurde, kann daher auf dem vorherigen Engine fertiggestellt werden, selbst nachdem die Web-Anwendung aktualisiert wurde. Die Sessionsdetails zeigen den Engine-Digest; ältere Sitzungen ohne diesen Herkunftsnachweis zeigen „Nicht aufgezeichnet.“.

Alle fünf Minuten prüft Glossia, ob das Deployment vollständig ausgerollt wurde. Nur ein Worker davon gesunden Release kann Engine-Wiederherstellung planen. Falls eine Projekts-Sitzung vor Abschluss des Rolloutsqueued wurde, auf einem älteren aufgezeichneten Engine-Digest lief und innerhalb der letzten sechs Stunden danach versagte, kann Glossia eine Fortsetzung für die aktuelle Version erstellen. Durch Nutzung der Warteschlauftime sind auch Aufgaben abgedeckt, die auf Kapazität warten und erst nach dem Rollout starten. Ein anderer Image-Digest allein löst keine Neued nuclearen Wiederholungen gewöhnlicher Fehler nach unrelevanten Deployments aus. Fertiggestellte Dateien und die offene Übersetzungs-Pull-Anfrage übernehmen; nur unvollendete Arbeit wird erneut übersetzt. Queued Release-Fortsetzungen warten, solange ein Rollout läuft, maximal 15 Minuten. Kubernetes-API- oder Freiheitsbundversุ่นgen stoppen das Senden mit einem expliziten Fehler, statt für einen anhaltenden Rollout missverstanden zu werden.

Wiederherstellung ist bewusst schmal gehalten: Die Sitzung muss mit einem aufgezeichneten Element-Validierungsfehler enden, und jedes fehlerhafte Element in ihrem letzten Versuch muss einen Markdown-Struktur, gehaltenen-Inhalt oder Markdown-Einheit Fehler melden. Unterbrochen oder teilweise abgebrochenen Versuchen kommen nicht in Frage. Provider-Fehler, erschöpftes Guthaben, verweigerte Credentials, Veröffentlichungsfehler, Quelllesefehler, externe Validierungsbefehlsfehler und unbekannte Ursachen werden durch ein Deployment nicht wiederholt. Erfolgreiche, aktive, abgebrochene, überholte und unversionierte Sitzungen bleiben unberührt. Eine neuere Sitzung gewinnt immer, auch wenn der Benutzer sie abgebrochen hat.

Eine Sitzung bekommt maximal eine Fortsetzung auf einer anderen Engine-Version, mit maximal drei Release-Fortsetzungen in einer Abstammungslinie. Falls das neue Engine immer noch versäumt, wird es nicht erneut auf demselben Bild wiederholt, einschließlich nach einem Rollback. Die Abstammungslinie behält ihre zuvor geprüften Engine-Digests bei, und der Launcher prüft sie erneut, bevor er eine gequeuede Aufgabe erstellt. Bestehende Provider-Wiederherstellungs-Limits bleiben über Release-Fortsetzungen bestehen. Veränderbare Image-Tags und Deployments ohne eine konfigurierte Release-Identität ermöglichen keine automatische Engine-Erwiederholung.

## Bestehender Fortschritt

Abgeschlossene Dateien und ihre Lockfiles werden in Batches an den Übersetzungs-Zweig veröffentlicht: ein Commit für alle 25 Dateien oder alle 15 Minuten, sowie ein abschließendes Commit, wenn der Durchlauf endet. Jeder Push führt die Pull-Request-Checks des Repositories durch, sodass Batching einen großen Durchlauf daran hindert, eine Prüfung pro Datei zu starten. Ein Projekt verfügt über einen einzigen Übersetzungs-Pull-Request: ein neuer Commit auf dem Standard-Zweig setzt den offenen fort und übersetzt lediglich das, was seitdem geändert wurde. Sobald dieser Pull-Request zusammengeführt oder geschlossen wurde, startet der nächste Durchlauf einen neuen. In unvollendeten Dateien werden lokal validierte Segmente und Wiederherstellungs-Batches ebenfalls sieben Tage lang in der Datenbank gespeichert. Diese Checkpoints überstehen das Stoppen eines Worker-Prozesses. Sie sind auf das Konto, das Projekt, die Dokumenteneingabe, die gültigen Credentials und Model, den Kontext sowie das Segment oder Reparaturversuch begrenzt.

Ein wiederaufgenommener Durchlauf kann ein Segment nur wiederverwenden, wenn seine Eingaben noch übereinstimmen. Es validiert das endgültige zusammengesetzte Dokument erneut. Abgelehnte Model-Antworten sind keine Checkpoints. Ein Validierungsfehler auf Dokumentebene leitet einen gesonderten Reparaturversuch ein, da der Validator möglicherweise kein einzelnes verantwortliches Segment identifizieren kann.

Abgelaufene Checkpoints und inaktive Provider-Pacing-Aufzeichnungen werden vom geplanten Sitzungswiederherstellungs-Worker entfernt. Dies sind operative Aufzeichnungen; Benutzer müssen diese nicht zum Repository hinzufügen oder in `L10N.md`.

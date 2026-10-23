%{
  title: "Übersetzungswiederherstellung",
  summary:
    "Wie Glossia Markdown intakt hält und sich von Provider-Throttling und unterbrochenen Übersetzungen erholt.",
  category: "Erklärung",
  section: "translation",
  order: 8
}
---

Glossia validiert übersetzten Inhalt vor der Veröffentlichung. Wiederherstellung bewahrt dieses Erfordernis: ein Neuversuch muss die Quellstruktur und erforderlichen Platzhalter weiterhin erhalten, und jede zusammengeführte Datei erfüllt ihre konfigurierten Validierungsbefehle.

## Markdown-Übersetzung

Glossia renderiert ein übersetztes Markdown-Dokument nie erneut. Es analysiert die Quelle lediglich, um den Text zu finden: Absätze, Überschriften, Listenpunkte, Tabellenzellen, die für die Leserschaft sichtbaren Attribute von Komponenten und HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), und den Text eines HTML `<summary>`-Elements. Jede Übersetzung wird in exakt denselben Bytes zurückgeschrieben, die die Quelle einnahm, so dass Code, Link-Ziele, Komponenten, GitHub-Alarme, explizite Überschriften-Verankerungen wie `{#install}`, Listenmarker und Leerzeilen byte-für-byte identisch bleiben.

Jeder Absatz oder jede Überschrift wird als Satz vollständig übersetzt. Inline-Formatierung wird zu nummerierten Tags: `<gN>...</gN>` um verlinkte oder hervorgehobene Wörter, und `<gN/>` für Inhalt, der unverändert bleiben muss, wie Inline-Code oder eine Komponente. Das Modell kann Tags verschieben, um die Wortreihenfolge der Zielsprache zu folgen, muss aber jedes Tag genau einmal behalten. Jede Anfrage enthält auch das umgebende Quelldokument und die neuesten Übersetzungen aus derselben Datei für den Bezug.

Eine Einheit, die ein Tag verliert oder erfindet, wird separat mit dem Grund bis zu dreimal erneut gesendet. Einheiten, die gültig zurückgekehrt sind, werden beibehalten. Nach dem Zusammenfügen analysiert Glossia das Ergebnis und vergleicht seine Struktur mit der Quelle. Eine Übersetzung, die in eine Überschrift, Liste oder Hervorhebung umgewandelt werden würde, hat ihren Text ent_CUSTOMescaped, was keinen weiteren Modellaufruf benötigt.

## Katalogübersetzung

Gettext-Kataloge werden vor der Übersetzung in Strings aufgeteilt. Anfragen enthalten maximal acht Strings, mit einem Ziel von 8.000 Bytes pro Batch. Eine einzelne größere String bleibt intakt. Das Modell gibt ein Array mit derselben Anzahl von Strings in derselben Reihenfolge zurück. Glossia prüft Interpolationsvariablen und lehnt leere Übersetzungen ab.

Überschriften werden im Code mit den Polurregeln der Zielsprache erstellt. Quelldaten-Identifikatoren, Kommentare und Katalogstruktur stammen aus der geparsten Quelle. Wenn ein Batch fehlerhafte Inhalte zurückgibt, versucht Glossia es einmal neu daraufhin, teilt es dann in kleinere Batches auf. Erfolgreiche benachbarte Batches müssen nicht erneut übersetzt werden.

## Provider-Drosselung

Glossia koordiniert Übersetzungsanfragen, die denselben Credential und Modell verwenden. Eine Rate-Limit-Antwort verlängert ihre gemeinsame Abkühlphase und erhöht den Abstand zwischen neuen Anfragen. Erfolgreicher Verkehr verringert diesen Abstand nach einer Minute ohne Drosselung allmählich. Bereits laufende Anfragen sind erlaubt, um fertigzustellen.

Provider-Neustapp-Hinweise sind Mindestverzögerungen. Wiederholte Fehler erhöhen den Backoff ebenfalls, bis zu einer Basisverzögerung von 30 Sekunden plus Jitter; ein längerer Provider-Hinweis hat Vorrang, auf fünf Minuten begrenzt. Together's `x-ratelimit-reset` Header wird gemeinsam mit `retry-after` erkannt.

Nach acht missglückten Anfragversuchen stoppt die Repository-Ausführung das Starten neuer Dateien. Eine verspätete Fortsetzung erbt die Übersetzungs-Branch und nimmt ihre unvollendete Arbeit wieder auf. Der vorherige Versuch bleibt in der Sitzungsverlauf unter der Fortsetzung sichtbar. Verzögerungen steigen von einer auf fünf Minuten, mit maximal sechs automatischen Fortsetzungen. Neuere aktive Sitzungen haben Vorrang, und abgebrochene Sitzungen werden nie wiederbelebt. Validierungsfehler allein planer eine Provider-Wiederherstellung.

## Wiederherstellung nach einer Engine-Veröffentlichung

Eine Session hat zwei unabhängige Versionen: den Repository-Commit, der übersetzt wird, und das Übersetzungs-Engine-Image, das sie ausführt. In Kubernetes hängt jeder Job den exakten Bild-Hash des Web-Replikas fest, das ihn geplant hat. Jobs überstehen Web-Rollouts und wechseln niemals Code mitten durch eine Übersetzung. Ein Job, der direkt vor einem Rollout geplant wurde, kann daher auf dem vorherigen Engine abgeschlossen werden, selbst nachdem die Web-Anwendung aktualisiert wurde. Die Sitzungs-Details zeigen den Engine-Hash; ältere Sitzungen ohne diese Provenienz zeigen „Nicht registriert.“

Alle fünf Minuten überprüft Glossia, ob seine Bereitstellung vollständig abgerollt ist. Nur ein Worker von diesem gesunden Release kann Engine-Wiederherstellung planen. Wenn die neueste Session eines Projekts vor Abschluss dieses Rollouts eingereiht wurde, auf einem älteren, aufgezeichneten Engine-Hash lief und danach in den letzten sechs Stunden fehlgeschlagen ist, kann Glossia auf dem aktuellen Release eine Fortsetzung erstellen. Die Warteschlangenzeit deckt auch Jobs ab, die auf Kapazität warten und erst nach dem Rollout starten. Ein anderer Bild-Hash allein löst keine Neuversuche von gewöhnlichen Fehlern nach unbevollständigen Bereitstellungen aus. Erledigte Dateien und die offene Übersetzungs-Pull-Anfrage werden übertragen; nur unfertige Arbeiten werden erneut übersetzt. Eingestellte Release-Fortsetzungen warten während ein Rollout im Gange ist, maximal 15 Minuten. Kubernetes-API- oder Berechtigungsfehler stoppen den Start mit einem expliziten Fehler, statt als laufender Rollout interpretiert zu werden.

Wiederherstellung ist absichtlich schmal: Die Session muss mit einem aufgezeichneten Element-Validierungsfehler beendet worden sein, und jeder fehlgeschlagene Eintrag in ihrem letzten Versuch muss eine Markdown-Struktur, konservierten Inhalt oder eine Markdown-Einheit-Schaden melden. Unterbrochene oder teilweise abgebrochene Versuche qualifizieren sich nicht. Provider-Fehler, erschöpfte Guthaben, abgelehnte Anmeldeinformationen, Veröffentlichungsfehler, Quelllesefehler, externe Validierungsbefehl-Feınder und unbekannte Ursachen werden von einer Bereitstellung nicht erneut versucht. Erfolgreiche, aktive, abgebrochene, überschriebene und nicht versionierte Sitzungen werden ebenfalls in Ruhe gelassen. Eine neuere Session gewinnt immer, selbst wenn der Benutzer sie abgebrochen hat.

Eine Session bekommt maximal eine Fortsetzung auf einem anderen Engine-Release, mit maximal drei Release-Fortsetzungen in einer Abstammung. Wenn die neue Engine weiter fehlschlägt, wird sie nicht erneut auf derselben Version erneut versucht, einschließlich nach einem Rollback. Die Abstammung behält ihre zuvor versuchten Engine-Hashes, und der Launcher prüft sie erneut, bevor er einen eingereihten Job erstellt. Bestehende Provider-Wiederherstellungsgrenzen werden über Release-Fortsetzungen hinweg erhalten. Veränderbare Bild-Tags und Bereitstellungen ohne konfigurierte Release-Identität aktivieren keine automatische Engine-Wiederherstellung.

## Beständiger Fortschritt

Abgeschlossene Dateien und ihre Lockfiles werden in Batches zur Übersetzungs-Branch veröfentlicht: ein Commit für 25 Dateien oder alle 15 Minuten, sowie ein finaler Commit, wenn die Laufzeit endet. Jeder Push führt die Pull-Anfrage-Checks des Repositorys aus, sodass die Gruppierung verhindert, dass bei einem großen Durchlauf pro Datei ein Prüfungsverlauf gestartet wird. Ein Projekt verfügt über eine einzige Übersetzungs-Pull-Anfrage: ein neuer Commit auf der Standard-Branch setzt die offene fort und übersetzt lediglich das, was seitdem geändert wurde. Sobald diese Pull-Anfrage zusammengeführt oder geschlossen wurde, initialisiert der nächste Lauf eine neue. Innerhalb von unvollendeten Dateien werden lokal validierte Segmente und Wiederherstellungs-Batches zudem in der Datenbank für sieben Tage gespeichert. Diese Checkpoints überstehen das Beenden eines Worker-Prozesses. Sie beziehen sich auf Konto, Projekt, Dokumenteneingabe, gültige Anmeldeinformationen und Modell, Kontext sowie Segment oder Reparaturversuch.

Eine wiederaufgenommene Ausführung kann ein Segment nur wiederverwenden, wenn seine Eingaben noch übereinstimmen. Es validiert das finale zusammengebaute Dokument immer erneut. Abgelehnte Modellantworten sind keine Checkpoints. Ein Validierungsfehler auf Dokumentenebene startet einen separaten Reparaturversuch, da der Validator möglicherweise kein einz nies verantwortliches Segment identifizieren kann.

Abgelaufene Checkpoints und inaktive Provider-Geschwindigkeitsdaten werden vom geplanten Sitzungs-Wiederherstellungs-Worker entfernt. Dies sind operative Daten; Benutzer müssen diese nicht zu ihrem Repository hinzufügen oder in `L10N.md` konfigurieren.

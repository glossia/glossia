%{
  title: "Übersetzungswiederherstellung",
  summary:
    "Wie Glossia Markdown intakt behält und sich von Provider-Throttling und unterbrochenen Übersetzungen erholt.",
  category: "Erklärung",
  section: "translation",
  order: 8
}
---

Glossia validiert den übersetzten Inhalt vor der Veröffentlichung. Wiederherstellung bewahrt diese Anforderung bei: ein Retry muss immer noch die Quellstruktur und erforderlichen Platzhalter erhalten, und jede zusammengesetzte Datei erfüllt ihre konfigurierten Validierungsbefehle.

## Markdown-Übersetzung

Glossia stellt ein übersetztes Markdown-Dokument niemals neu dar. Es analysiert die Quelle nur, um den Inhalt des Dokuments zu finden: Absätze, Überschriften, Listenpunkte, Tabellenzellen, die vom Nutzer sichtbaren Attribute von Komponenten und HTML (`title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, `caption`), und den Text einer HTML-Komponente `<summary>`. Jede Übersetzung wird in genau die Bytes zurückgeschrieben, die ihre Quelle eingenommen hat, so dass Code, Link-Ziele, Komponenten, GitHub-Warnungen, explizite Überschriften-Anker wie `{#install}`, Listenmarker und leere Zeilen byte-für-byte identisch bleiben.

Jeder Absatz oder jede Überschrift wird als vollständiger Satz übersetzt. Zeilenformatierung wird zu nummerierten Tags: `<gN>...</gN>` um verknüpfte oder hervorgehobene Wörter, und `<gN/>` für Inhalt, der unverändert bleiben muss, wie Inline-Code oder eine Komponente. Das Modell kann Tags verschieben, um die Wortfolge der Zielsprache zu folgen, muss aber jedes Tag genau einmal erhalten. Jede Anfrage enthält auch das umgebende Quelldokument und die neuesten Übersetzungen aus der gleichen Datei zur Referenz.

Eine Einheit, die einen Tag löscht oder erfunden hat, wird allein gesendet, mit dem Grund, bis zu dreimal. Einheiten, die als gültig zurückgekommen sind, werden beibehalten. Nach dem Verbinden parasзирует Glossia das Ergebnis und vergleicht seine Struktur mit der Quelle. Eine Übersetzung, die dadurch eine Überschrift, Liste oder Hervorhebung darstellt, hat ihren Erzähltext entflohen, was keinen weiteren Modellruf benötigt.

## Gettext-Katalogübersetzung

Gettext-Kataloge werden als Strings eingelesen und nach der Übersetzung bearbeitet. Anfragen enthalten maximal acht Strings, mit einem Batch-Ziel von 8.000 Bytes. Ein einzelner größerer String bleibt intakt. Das Modell gibt ein Array zurück mit der gleichen Anzahl an Strings in derselben Reihenfolge. Glossia prüft Interpolationsvariablen und lehnt leere Übersetzungen ab.

Header werden mit Code basierend auf den Pluralregeln des Ziellokals erstellt. Nachrichten-Identifikatoren, Kommentare und Katalogstruktur stammen aus dem geparsten Quelltext. Wenn ein Batch fehlerhafte Inhalte zurückgibt, versucht Glossia es einmal, teilt es dann in kleinere Batches auf. Erfolgreiche Nachbarbatches müssen nicht erneut übersetzt werden.

## Provider-Throttling

Glossia koordiniert Übersetzungsanfragen, die dasselbe Credential und Modell verwenden. Eine Rate-Limit-Antwort verlängert ihre gemeinsame Abkühlzeit und vergrößert den Abstand zwischen neuen Anfragen. Erfolgreicher Traffic reduziert diesen Abstand nach einer Minute ohne Drosselung allmählich. Bereits laufende Anfragen dürfen abschließen.

Provider-Retry-Hinweise sind minimale Verzögerungen. Wiederholte Ausfälle erhöhen ebenfalls den Backoff, bis zu einer Basisverzögerung von 30 Sekunden plus Jitter; ein längerer Provider-Hinweis hat Vorrang, begrenzt auf fünf Minuten. Der `x-ratelimit-reset` Header von Together wird neben `retry-after` erkannt.

Nach acht erfolglosen Versuchen stoppt der Repository-Lauf das Starten neuer Dateien. Eine verzögerte Fortsetzung vererbt den Übersetzungsbranch und setzt das unvollendete Werk fort. Der frühere Versuch bleibt im Sitzungsgeschicht sichtbar, verknüpft durch die Fortsetzung. Verzögerungen steigen von einer Minute auf fünf Minuten, mit maximal sechs automatischen Fortsetzungen. Neuere aktive Sitzungen haben Vorrang, und abgesetzte Sitzungen werden niemals wiederbelebt. Nur Validierungsfehler planen keine Wiederherstellung des Anbieters.

## Wiederherstellung nach einem Engine Release

**Edition: Enterprise.** Die Kubernetes-Rollout-Prüfungen und die Wiederherstellung nach einem Engine Release in diesem Abschnitt erfordern [isolierte Übersetzungsrunner](/de/docs/reference/isolated-translation-runners). Die an anderer Stelle auf dieser Seite beschriebene Wiederherstellung für Markdown, Kataloge und Provider sowie der dauerhafte Fortschritt sind auch in Community verfügbar.

Eine Sitzung hat zwei unabhängige Versionen: den Repository-Ausweis, der übersetzt wird, und das Übersetzungs-Engine-Image, welches ihn ausführt. In Kubernetes steuert jeder Job den exakten Image-Digest des Web-Replikas, das ihn geplant hat. Jobs überleben Web-Rollouts und wechseln den Code nie mitten in einer Übersetzung. Ein Job, der kurz vor einem Rollout geplant wurde, kann daher auch auf dem vorherigen Engine abschließen, nachdem die Webanwendung aktualisiert wurde. Die Sitzungsdetails zeigen den Engine-Digest; ältere Sitzungen ohne diese Herkunft zeigen "Nicht verzeichnet."

Jede fünf Minuten prüft Glossia, ob seine Bereitstellung vollends ausrollt. Nur ein Worker aus dieser gesunden Version kann Engine-Wiederherstellung planen. Wenn die neueste Sitzung eines Projekts vor dem Abschluss des Rollouts gepuffert, auf einen älteren aufgeführten Engine-Digest läuft und danach innerhalb von sechs Stunden fehlschlägt, kann Glossia eine Fortsetzung auf der aktuellen Version erstellen. Die Nutzung von Warteschlifenzeit deckt auch Jobs ab, die auf Kapazität warten und erst nach dem Rollout hochfahren. Ein anderer Image-Digest allein löst keine Rückversuche von gewöhnlichen Fehlern nach unzusammenhängenden Bereitstellungen aus. Beendete Dateien und die offene Übersetzungs-Pull-Request gehen über; nur unvollendete Arbeit wird erneut übersetzt. Gepufferte Release-Fortsetzungen warten während eines laufenden Rollouts, maximal 15 Minuten. Kubernetes-API- oder Berechtigungsfehler stoppen den Start mit einem expliziten Fehler, statt fälschlicherweise für einen laufenden Rollout gehalten zu werden.

Wiederherstellung ist absichtlich eng: Die Sitzung muss mit einem aufgezeichneten Einzel-Validierungsfehler enden, und jeder fehlgeschlagene Eintrag in seinem letzten Versuch muss einen Markdown-Struktur-, geschützten-Inhalt- oder Markdown-Einheitenfehler melden. Unterbrochene oder teilweise abgesetzte Versuche qualificieren sich nicht. Anbieterfehler, erschöpftes Guthaben, abgelehnte Credentials, Veröffentlichungsfehler, Quelllesefehler, externe Validierungsbefehlsfehler und unbekannte Ursachen werden von einem Deployment nicht erneut versucht. Erfolgreiche, aktive, abgesetzte, überstürzte und unversionierte Sitzungen bleiben unberührt. Eine neuere Sitzung gewinnt immer, auch wenn der Benutzer sie abgesetzt hat.

Eine Sitzung erhält maximal eine Fortsetzung auf einer anderen Engine-Version, mit maximal drei Release-Fortsetzungen in einer Abstammungslinie. Wenn das neue Engine immer noch fehlschlägt, wird es auf diesemselben Abbild nicht erneut versucht, auch nicht nach einem Rollback. Die Abstammung behält ihre zuvor versuchte Engine-Digests und der Launcher prüft sie erneut, bevor er einen gepufferten Job erstellt. Bestehende Anbieter-Wiederherstellungsgrenzen bleiben über Release-Fortsetzungen erhalten. Veränderbare Image-Tags und -Deployments ohne konfiguriertes Release-Identität aktivieren keine automatische Engine-Wiederherstellung.

## Dauerhafter Fortschritt

Abgeschlossene Dateien und ihre Lockdateien werden in Stapeln auf den Übersetzungszweig veröffentlicht: ein Commit für alle 25 Dateien oder alle 15 Minuten, sowie ein abschließender Commit, wenn der Durchlauf endet. Jeder Push führt die Pull-Request-Prüfungen des Repositories aus; durch Stapeln wird bei großen Durchläufen verhindert, dass pro Datei ein Check-Run gestartet wird. Ein Projekt hat einen einzigen Übersetzungs-Pull-Request: ein neuer Commit auf dem Standardzweig setzt den offenen fort und übersetzt nur das, was seitdem geändert wurde. Sobald dieser Pull-Request zusammengeführt oder geschlossen ist, startet der nächste Durchlauf einen neuen. In unvollendeten Dateien werden lokal validierte Segmente und Wiederherstellungsbatches ebenfalls sieben Tage lang in der Datenbank gespeichert. Diese Sicherungspunkte überleben das Stoppen eines Worker-Prozesses. Sie sind auf den Account, das Projekt, den Dokument-Input, das effektive Credential und Modell, den Kontext sowie das Segment oder den Reparaturversuch beschränkt.

Ein fortgesetzter Durchlauf kann ein Segment nur wiederverwenden, wenn seine Eingaben noch übereinstimmen. Es validiert das finale zusammengesetzte Dokument immer erneut. Abgelehnte Modellantworten sind keine Sicherungspunkte. Ein Validierungsfehler auf Dokumentebene startet einen separaten Reparaturversuch, da der Validator möglicherweise keinen einzelnen verantwortlichen Segment identifizieren kann.

Abgelaufene Sicherungspunkte und inaktive Anbieter-Pacing-Protokolle werden vom geplanten Sitzungswiederherstellungsworker entfernt. Dies sind Betriebsdaten; Benutzer müssen sie weder zu ihren Repositories hinzufügen noch in `L10N.md` konfigurieren.

%{
  title: "Projekteinrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  order: 2
}
---
Das Projekt-Setup bereitet ein verbundenes Repository für Glossia vor. Es beginnt, nachdem ein Benutzer ein Repository ausgewählt hat und mindestens eine Ziel Sprache im **Neues Projekt**-Workflow angegeben.

## Voraussetzungen

- Das Konto verfügt über mindestens ein konfiguriertes Modell.
- Die Glossia GitHub App kann auf das ausgewählte Repository zugreifen.
- Der Benutzer kann Projekte im Konto erstellen.
- Mindestens eine Ziel Sprache wurde ausgewählt.

## Zustände

| Zustand | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Ausstehend** | Das Projekt wurde akzeptiert und wartet auf den Start. | Verfolgen Sie den Fortschritt oder verlassen Sie die Seite und kommen Sie später zurück. |
| **läuft** | Glossia überprüft und aktualisiert das Repository. | Verfolgen Sie die aktuelle Aktivität. |
| **Abgeschlossen** | Die Lokalisierungs-Baseline wurde zusammengestellt und veröffentlicht zur Überprüfung. | Öffnen, überprüfen und zusammenführen Sie den Pull-Request. |

Projekte sind vorläufig, solange das Setup im Zustand **Ausstehend** oder **Läuft** ist. Wenn das Setup nicht beenden oder eine brauchbare Änderung veröffentlichen kann, bereinigt Glossia die Setup-Umgebung und löscht das vorläufige Projekt. Das Repository steht dann im Workflow für **Neue Projekte** wieder bereit, sodass das Setup erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Setup-Karte bleibt im neuen-Projekt-Workflow und im Projekt-Überblick verfügbar. Sie umfasst:

- Ein Status-Abzeichen und einen Fortschrittsbalken.
- Eine kurze Erklärung des aktuellen Zustands.
- Jagentliche Aktivitäten der Repository-Bereitstellung, Inspektion, Dateiänderung, Überprüfung und des Abschlusses.
- Eine klaren Fehlersmeldungen, wenn das Setup nicht abgeschlossen werden kann.

Der Fortschritt wird gespeichert, solange das vorläufige Projekt existiert. Ein endgültiger Fehler verwirft sowohl das Projekt als auch seinen sichtbaren Setup-Fortschritt.

## Abgeschlossenes Ergebnis

Eine erfolgreiche verbundene Einrichtung erstellt einen dedizierten Branch und einen Pull-Request gegen den Standard-Branch des Repositories. Der Pull-Request enthält die generierte Lokalisierungs-Baseline, einschließlich `GLOSSIA.md`-Kontext und die kleinstmöglichen praktischen Änderungen, die zum Laden von lokalisiertem Inhalt erforderlich sind.

Das Setup veröffentlicht keine Zielkataloge, die nur Header enthalten. Wenn ein Lokalisierungs-Framework Zielkataloge vor der Übersetzung benötigt, enthalten diese die extrahierten Quellnachricht-Einträge mit leeren Übersetzungswerten. Werden Zielkataloge noch nicht benötigt, behält das Setup sie für den ersten Übersetzungs-Lauf.

Glossia führt den Pull-Request nicht zusammen. Repository-Wartungsverantwortliche prüfen und führen ihn über ihren normalen GitHub-Prozess zusammen.

Der Projekt-Überblick zeigt eine Setup-Benachrichtigung an, solange dieser Pull-Request offen ist. Die Benachrichtigung wird entfernt, nachdem der Pull-Request zusammengeführt wurde. Wenn der Pull-Request ohne Zusammenführung geschlossen wird, erklärt der Überblick, dass er erneut geöffnet werden muss, bevor das Setup als abgeschlossen betrachtet werden kann.
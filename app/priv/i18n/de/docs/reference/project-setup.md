%{
  title: "Projekt-Einrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  order: 2
}
---
Die Projekteinrichtung bereitet ein verbundenes Repository für Glossia vor. Sie beginnt, nachdem ein Benutzer ein Repository und mindestens eine Zielsprache im **Neues Projekt** Ablauf.

## Voraussetzungen

- Das Konto verfügt über mindestens ein konfiguriertes Modell.
- Die Glossia GitHub-App kann auf das ausgewählte Repository zugreifen.
- Der Benutzer kann Projekte im Konto erstellen.
- Mindestens eine Zielsprache ist ausgewählt.

## Zustände

| Status | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Ausstehend** | Das Projekt wurde akzeptiert und wartet auf den Start. | Verfolgen Sie den Fortschritt oder verlassen Sie die Seite und kommen Sie später zurück. |
| **Läuft** | Glossia prüft und aktualisiert das Repository. | Verfolgen Sie die Live-Aktivität. |
| **Abgeschlossen** | Die Lokalisierungs-Basis wurde vorbereitet und zur Überprüfung veröffentlicht. | Öffnen, überprüfen und zusammenführen Sie den Pull-Request. |

Projekte sind vorläufig, während die Einrichtung ist **Ausstehend** oder **Läuft**. Wenn das Setup nicht erfolgreich abgeschlossen oder eine brauchbare Änderung nicht veröffentlicht werden kann, bereinigt Glossia die Einrichtungsumgebung und löscht das vorläufige Projekt. Das Repository steht danach in dem **Neues Projekt** Ablauf, so dass das Setup erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Einrichtungskarte bleibt im Neuprojekt-Ablauf und in der Projektübersicht verfügbar. Sie umfasst:

- Ein Statusabzeichen und ein Fortschrittsbalken.
- Eine kurze Erklärung des aktuellen Status.
- Kürzliche Repository-Vorbereitung, Inspektion, Dateiänderung, Validierung und Abschlussaktivitäten.
- Eine klare Fehlermeldung, wenn die Einrichtung nicht abgeschlossen werden kann.

Der Fortschritt wird gespeichert, solange das vorläufige Projekt besteht. Ein endgültiges Scheitern verwirft sowohl das Projekt als auch seinen sichtbaren Einrichtungsfortschritt.

## Abgeschlossenes Ergebnis

Eine erfolgreiche, verbundene Einrichtung erstellt einen dedizierten Branch und einen Pull Request gegen den Standardzweig des Repositories. Der Pull Request enthält die generierte Lokalisierungsbasislinie, einschließlich `L10N.md` den Kontext und die kleinsten praktikablen Änderungen, die erforderlich sind, um lokalisierten Inhalt zu laden.

Die Einrichtung veröffentlicht keine Header-only-Zielkataloge. Wenn ein Lokalisierungsframework Zielkataloge vor der Übersetzung benötigt, enthalten diese die extrahierten Quellnachrichteneinträge mit leeren Übersetzungswerten. Wenn Zielkataloge noch nicht erforderlich sind, belässt die Einrichtung sie für den ersten Übersetzungslauf.

Glossia führt den Pull Request nicht zusammen. Repositories-Betreuer prüfen und führen ihn über ihren normalen GitHub-Prozess zusammen.

Der Projektüberblick zeigt einen Hinweis zur Einrichtung, solange dieser Pull Request offen ist. Der Hinweis wird entfernt, nachdem der Pull Request verschmolzen wurde. Wird der Pull Request geschlossen, ohne verschmolzen zu werden, erläutert der Überblick, dass er vor dem Abschluss der Einrichtung erneut geöffnet werden muss.
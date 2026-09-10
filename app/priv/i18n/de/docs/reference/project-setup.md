%{
  title: "Projekt-Einrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  order: 2
}
---
Die Projektvorbereitung richtet ein verknüpftes Repository für Glossia ein. Sie beginnt, nachdem ein Benutzer ein Repository und mindestens eine Zielsprache im **Neues Projekt** Arbeitsablauf.

## Voraussetzungen

- Das Konto verfügt über mindestens ein konfiguriertes Modell.
- Die Glossia GitHub App kann auf das ausgewählte Repository zugreifen.
- Der Benutzer kann Projekte im Konto erstellen.
- Mindestens eine Zielsprache ist ausgewählt.

## Zustände

| Zustand | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Wartend** | Das Projekt wurde akzeptiert und wartet auf den Start. | Verfolgen Sie den Fortschritt oder verlassen Sie die Seite und kehren Sie später zurück. |
| **Laufend** | Glossia prüft und aktualisiert das Repository. | Verfolgen Sie die Live-Aktivität. |
| **Abgeschlossen** | Die Lokalisierungs-Baseline wurde vorbereitet und zur Überprüfung veröffentlicht. | Öffnen, überprüfen und den Pull Request mergen. |

Projekte sind vorläufig, während die Einrichtung **Ausstehend** oder **Laufend**. Wenn das Setup nicht erfolgreich abgeschlossen oder eine nutzbare Änderung nicht veröffentlicht werden kann, bereinigt Glossia die Setup-Umgebung und löscht das vorläufige Projekt. Das Repository steht dann im **Neues Projekt** Ablauf, damit das Setup erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Setup-Karte bleibt im neuen-Projekt-Ablauf und in der Projektübersicht verfügbar. Sie enthält:

- Ein Status-Abzeichen und ein Fortschrittsbalken.
- Eine kurze Erklärung des aktuellen Status.
- Aktive Aktivitäten: jüngste Repository-Vorbereitung, -Inspektion, -Dateiänderung, -Überprüfung und -Abschluss.
- Eine klare Fehlermeldung, wenn die Einrichtung nicht erfolgreich abgeschlossen werden kann.

Der Fortschritt wird gespeichert, solange das vorläufige Projekt existiert. Ein endgültiger Fehler verwirft sowohl das Projekt als auch seinen sichtbaren Einrichtungsfortschritt.

## Abgeschlossenes Ergebnis

Eine erfolgreiche, verbundene Einrichtung erstellt einen dedizierten Branch und einen Pull Request gegen den Standardbranch des Repositories. Der Pull Request enthält die generierte Lokalisierungsbaseline, einschließlich `L10N.md` den Kontext und die kleinsten praktischen Änderungen, die notwendig sind, um lokalisierten Inhalt zu laden.

Die Einrichtung veröffentlicht keine Zielkataloge, die nur Header enthalten. Wenn ein Lokalisierungsframework Zielkataloge vor der Übersetzung benötigt, enthalten diese die extrahierten Quellnachrichteneinträge mit leeren Übersetzungswerten. Wenn Zielkataloge noch nicht erforderlich sind, verbleiben sie für den ersten Übersetzungslauf.

Glossia führt den Pull Request nicht zusammen. Repository-Wartender überprüfen und führen ihn durch ihren normalen GitHub-Prozess zusammen.

Der Projektüberblick zeigt eine Einrichtungshinweis, solange dieser Pull Request offen ist. Der Hinweis wird entfernt, nachdem der Pull Request zusammengeführt wurde. Wenn der Pull Request ohne Zusammenführung geschlossen wird, erklärt der Überblick, dass er vor Abschluss der Einrichtung erneut geöffnet werden muss.
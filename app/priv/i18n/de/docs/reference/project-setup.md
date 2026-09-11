%{
  title: "Projekteinrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  order: 2
}
---
Das Projektsetup richtet ein verknüpftes Repository für Glossia ein. Es beginnt, nachdem ein Benutzer ein Repository und mindestens eine Zielsprache in dem **Neues Projekt** Ablauf.

## Voraussetzungen

- Das Konto verfügt über mindestens ein konfiguriertes Modell.
- Die Glossia GitHub App kann auf das ausgewählte Repository zugreifen.
- Der Benutzer kann Projekte im Konto erstellen.
- Mindestens eine Zielsprache ist ausgewählt.

## Zustände

| Zustand | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Ausstehend** | Das Projekt wurde akzeptiert und wartet auf den Start. | Verfolgen Sie den Fortschritt oder verlassen Sie die Seite und kehren Sie später zurück. |
| **Laufend** | Glossia überprüft und aktualisiert das Repository. | Verfolgen Sie die Live-Aktivität. |
| **Abgeschlossen** | Die Lokalisierungs-Baseline wurde vorbereitet und zur Überprüfung veröffentlicht. | Öffnen, prüfen und den Pull Request zusammenführen. |

Projekte sind vorläufig, solange das Setup ist **Wartend** oder **Laufend**. Wenn die Einrichtung nicht abgeschlossen werden kann oder keine nutzbare Änderung veröffentlichen kann, bereinigt Glossia die Einrichtungsumgebung und löscht das vorübergehende Projekt. Das Repository steht dann in dem **Neues Projekt** Workflow, damit die Einrichtung erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Einrichtungskarte bleibt im neuen-Projekt-Workflow und auf der Projektübersicht verfügbar. Sie umfasst:

- Ein Status-Indikator und eine Fortschrittsleiste.
- Eine kurze Erklärung des aktuellen Status.
- Aktuelle Repository-Vorbereitung, -Inspektion, Dateiänderungen, -Prüfung und Abschlussaktivitäten.
- Eine klare Fehlermeldung, wenn die Einrichtung nicht abgeschlossen werden kann.

Der Fortschritt wird gespeichert, solange das vorläufige Projekt existiert. Ein endgültiger Fehler verwirft sowohl das Projekt als auch seinen sichtbaren Fortschritt bei der Einrichtung.

## Abgeschlossenes Ergebnis

Eine erfolgreiche, verbundene Einrichtung erstellt einen dedizierten Branch und einen Pull-Request gegen den Standard-Branch des Repositoriums. Der Pull-Request enthält die generierte Lokalisierungs-Baseline, einschließlich `L10N.md` Kontext und die kleinsten praktischen Änderungen, die erforderlich sind, um lokalisierten Inhalt zu laden.

Die Einrichtung veröffentlicht keine nur-Header-Zielkataloge. Wenn ein Lokalisierungsframework Zielkataloge vor der Übersetzung benötigt, enthalten diese extrahierten Quellnachrichteneinträge mit leeren Übersetzungswerten. Wenn Zielkataloge noch nicht erforderlich sind, verbleiben sie für den ersten Übersetzungslauf.

Glossia fusioniert den Pull-Request nicht. Die Maintainer des Repositoriums prüfen und fusionieren diesen über ihren normalen GitHub-Prozess.

Die Projektübersicht zeigt einen Hinweis zur Einrichtung, solange dieser Pull-Request offen ist. Der Hinweis wird entfernt, nachdem der Pull-Request fusioniert wurde. Wenn der Pull-Request geschlossen wird, ohne fusioniert zu werden, erklärt die Übersicht, dass dieser vorab erneut geöffnet werden muss, bevor die Einrichtung als abgeschlossen gilt.
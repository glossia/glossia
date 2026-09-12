%{
  title: "Projekt-Einrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  order: 2
}
---
Die Projekteinrichtung bereitet ein verbundenes Repository für Glossia vor. Sie beginnt, nachdem ein Nutzer ein Repository ausgewählt und mindestens eine Zielsprache in der **Neues Projekt** Ablauf.

## Voraussetzungen

- Das Konto verfügt über mindestens ein konfiguriertes Modell.
- Die Glossia GitHub App kann auf das ausgewählte Repository zugreifen.
- Der Nutzer kann Projekte im Konto erstellen.
- Mindestens eine Zielsprache ist ausgewählt.

## Zustände

| Zustand | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Ausstehend** | Das Projekt wurde akzeptiert und wartet auf den Start. | Fortschritt verfolgen oder die Seite verlassen und später zurückkehren. |
| **In Bearbeitung** | Glossia überprüft und aktualisiert das Repositorium. | Verfolgen Sie die Live-Aktivität. |
| **Abgeschlossen** | Die Lokalisierungs-Baseline wurde vorbereitet und zur Prüfung veröffentlicht. | Öffnen, überprüfen und zusammenführen Sie den Pull-Request. |

Projekte sind vorläufig, während das Setup ist **ausstehend** oder **Laufend**. Wenn der Setup nicht erfolgreich abgeschlossen werden oder keine nutzbare Änderung veröffentlichen kann, bereinigt Glossia die Setup-Umgebung und löscht das vorläufige Projekt. Das Repository steht dann in dem **Neues Projekt** Ablauf, so dass der Setup erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Setup-Karte bleibt im neuen Projekt-Ablauf und auf der Projektübersicht verfügbar. Sie enthält:

- Ein Statusabzeichen und ein Fortschrittsbalken.
- Eine kurze Erklärung des aktuellen Zustands.
- Kürzliche Repository-Vorbereitung, Inspektion, Dateiänderung, Prüfung und Abschlussaktivität.
- Eine klare Fehlermeldung, wenn die Einrichtung nicht abgeschlossen werden kann.

Der Fortschritt wird gespeichert, solange das vorläufige Projekt besteht. Ein endgültiger Fehler verwirft sowohl das Projekt als auch den sichtbaren Fortschritt in der Einrichtung.

## Abgeschlossenes Ergebnis

Ein erfolgreicher, verbundener Einrichtungsvorgang erstellt einen dedizierten Branch und einen Pull-Request für den Standard-Branch des Repositoriums. Der Pull-Request enthält die generierte Lokalisierungsbasis, einschließlich `L10N.md` Kontext und die kleinsten praktischen Änderungen, die benötigt werden, um lokalisierten Inhalt einzuladen.

Die Einrichtung veröffentlicht keine header-nur-Zielkataloge. Wenn ein Lokalisierungsframework Zielkataloge vor der Übersetzung benötigt, enthalten diese die extrahierten Einträge der Quellnachrichten mit leeren Übersetzungswerten. Wenn Zielkataloge noch nicht erforderlich sind, belässt die Einrichtung sie für den ersten Übersetzungslauf.

Glossia bindet den Pull-Request nicht ein. Die Maintainer des Repositoriums prüfen und binden ihn über ihren normalen GitHub-Prozess ein.

Die Projektübersicht zeigt eine Einrichtungsmeldung an, solange dieser Pull-Request offen ist. Die Meldung wird entfernt, nachdem der Pull-Request eingearbeitet wurde. Wenn der Pull-Request geschlossen wird, ohne einzuarbeiten, erklärt die Übersicht, dass er erneut geöffnet werden muss, bevor die Einrichtung als abgeschlossen betrachtet werden kann.
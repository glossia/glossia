%{
  title: "Projekt-Einrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  order: 2
}
---
Die Projekteinrichtung bereitet ein verbundenes Repositorium für Glossia vor. Es beginnt, nachdem ein Benutzer ein Repositorium und mindestens eine Zielsprache in dem **Neues Projekt** Ablauf.

## Voraussetzungen

- Das Konto verfügt über mindestens ein konfiguriertes Modell.
- Die Glossia GitHub App kann auf das ausgewählte Repositorium zugreifen.
- Der Benutzer kann im Konto Projekte erstellen.
- Mindestens eine Zielsprache wurde ausgewählt.

## Zustände

| Zustand | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Ausstehend** | Das Projekt wurde akzeptiert und wartet auf den Start. | Verfolgen Sie den Fortschritt oder verlassen Sie die Seite und kehren Sie später zurück. |
| **In Bearbeitung** | Glossia prüft und aktualisiert das Repositorium. | Verfolge die Live-Aktivität. |
| **Abgeschlossen** | Die Lokalisierungs-Basislinie wurde vorbereitet und zur Prüfung veröffentlicht. | Öffnen, prüfen und den Pull-Request zusammenführen. |

Projekte sind vorläufig, während die Einrichtung ist **Ausstehend** oder **In Bearbeitung**. Wenn die Einrichtung nicht abgeschlossen werden kann oder keine verwendbare Änderung veröffentlichen kann, räumt Glossia die Einrichtungsumgebung auf und löscht das vorläufige Projekt. Das Repository wird dann verfügbar **Neues Projekt** Workflow, sodass die Einrichtung erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Einrichtungskarte bleibt im Neuprojekt-Workflow und in der Projektübersicht verfügbar. Sie enthält:

- Ein Status-Abzeichen und ein Fortschrittsbalken.
- Eine kurze Erklärung des aktuellen Zustands.
- Aktive Aktivitäten zur Repository-Vorbereitung, Inspektion, Dateiänderung, Prüfung und Fertigstellung.
- Eine klare Fehlermeldung, wenn die Einrichtung nicht abgeschlossen werden kann.

Der Fortschritt wird gespeichert, solange das provisorische Projekt besteht. Ein endgültiger Fehler verwirft sowohl das Projekt als auch seinen sichtbaren Einrichtungsfortschritt.

## Abgeschlossenes Ergebnis

Eine erfolgreiche, vernetzte Einrichtung erstellt einen dedizierten Branch und einen Pull-Request gegenüber dem Standard-Branch des Repositories. Der Pull-Request enthält die generierte Lokalisierungsbasis, einschließlich `L10N.md` Kontext und die kleinsten praktischen Änderungen, die zum Laden lokalisierter Inhalte benötigt werden.

Die Einrichtung veröffentlicht keine nur-Header-Zielkataloge. Wenn ein Lokalisierungsframework Zielkataloge vor der Übersetzung benötigt, enthalten diese die extrahierten Quellnachrichteneinträge mit leeren Übersetzungswerten. Wenn Zielkataloge noch nicht benötigt werden, belässt die Einrichtung sie für den ersten Übersetzungsdurchlauf.

Glossia fügt den Pull-Request nicht zusammen. Repository-Maintainer prüfen und führen ihn über ihren normalen GitHub-Prozess zusammen.

Der Projektoberblick zeigt einen Hinweis zur Einrichtung, solange dieser Pull-Request offen ist. Der Hinweis wird entfernt, nachdem der Pull-Request zusammengeführt wurde. Wird der Pull-Request geschlossen, ohne zusammengeführt worden zu sein, erklärt der Überblick, dass er erneut geöffnet werden muss, bevor die Einrichtung als abgeschlossen gilt.
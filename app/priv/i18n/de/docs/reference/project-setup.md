%{
  title: "Projekt-Einrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  section: "translation",
  order: 2
}
---
Projekt-Setup bereitet ein verknüpftes Repository für Glossia vor. Nachdem ein Benutzer ein Repository in dem **Neues Projekt** Ablauf, wählen Sie einen der beiden Setup-Modi aus.

## Setup-Modi

| Modus | Was Glossia tut | Wann Sie es wählen |
|---|---|---|
| **Automatisiertes Setup** | Untersucht das Repository und erstellt einen Pull-Request mit der generierten `L10N.md` Konfiguration für die ausgewählten Ziel-Sprachen. | Das Repository hat noch keine Lokalisierungskonfiguration. |
| **Manuelle Konfiguration** | Erstellt das Projekt sofort. Es untersucht das Repository nicht, ändert es nicht oder öffnet keinen Pull-Request. | Das Repository hat bereits eine `L10N.md` Konfigurationsdatei, oder ein Maintainer schreibt sie. |

Die unten beschriebenen Zustände, Fortschrittsinformationen und Pull-Request gelten nur für die automatisierte Einrichtung.

## Manuelle Konfiguration

Ein manuell konfiguriertes Projekt hat keinen Einrichtungsstatus. Es ist sofort nach der Erstellung nutzbar und wird nie durch eine fehlgeschlagene Einrichtung verworfen.

Glossia startet einen Übersetzungslauf beim nächsten Push in den Standardzweig des Repositorys. Der Lauf übersetzt in jedes darin deklarierte Ziel des [`L10N.md`](/docs/reference/l10n-md) Dateien, da keine Zielsprachen im **Neues Projekt** Workflow.

Bis zum ersten Übersetzungslauf zeigt die Projektübersicht eine Benachrichtigung, dass Glossia auf einen Push wartet, der eine `L10N.md` Datei.

## Voraussetzungen

- Das Konto hat mindestens ein konfiguriertes Modell.
- Die Glossia GitHub-App kann auf das ausgewählte Repository zugreifen.
- Der Benutzer kann Projekte im Konto erstellen.
- Für die automatische Einrichtung ist mindestens eine Zielsprache ausgewählt.

## Zustände

| Status | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Ausstehend** | Das Projekt wurde akzeptiert und wartet auf den Start. | Folgen Sie dem Fortschritt oder verlassen Sie die Seite und kehren Sie später zurück. |
| **Laufend** | Glossia prüft das Repository und aktualisiert es. | Verfolgen Sie die Live-Aktivität. |
| **Abgeschlossen** | Die Lokalisierungsbasis wurde vorbereitet und zur Überprüfung veröffentlicht. | Öffnen, überprüfen und den Pull Request zusammenführen. |

Projekte sind vorläufig, solange die Einrichtung **Ausstehend** oder **Laufend**. Wenn die Einrichtung nicht abgeschlossen oder eine nutzbare Änderung nicht veröffentlicht werden kann, bereinigt Glossia die Einrichtungsumgebung und löscht das vorläufige Projekt. Das Repository wird dann im **Neues Projekt** Workflow, sodass die Einrichtung erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Setup-Karte bleibt im Neu-Projekt-Workflow und auf der Projektübersicht verfügbar. Sie enthält:

- Ein Statusabzeichen und eine Fortschrittsleiste.
- Eine kurze Erklärung des aktuellen Zustands.
- Kürzliche Repository-Vorbereitung, Inspektion, Dateiänderungen, Prüfungen und Abschlussaktivitäten.
- Eine klare Fehlermeldung, wenn der Setup nicht abgeschlossen werden kann.

Der Fortschritt wird gespeichert, solange das vorläufige Projekt besteht. Ein endgültiger Fehler verwirft sowohl das Projekt als auch seinen sichtbaren Setup-Fortschritt.

## Vollendetes Ergebnis

Ein erfolgreicher verbundener Setup erstellt einen dedizierten Branch und einen Pull-Request gegen den Standard-Branch des Repositories. Der Pull-Request enthält die generierte Lokalisierungs-Baseline, einschließlich `L10N.md` Kontext und die kleinsten praktischen Änderungen, die zum Laden von lokalisiertem Inhalt erforderlich sind.

Setup veröffentlicht keine nur-Header-Zieltabellen. Wenn ein Lokalisierungsframework Zieltabellen vor der Übersetzung benötigt, enthalten diese die extrahierten Quellnachrichteneinträge mit leeren Übersetzungswerten. Wenn Zieltabellen noch nicht erforderlich sind, belässt Setup diese für den ersten Übersetzungsablauf.

Glossia führt den Pull Request nicht zusammen. Repository-Betreuer prüfen und führen diesen über ihren normalen GitHub-Prozess zusammen.

Die Projektübersicht zeigt einen Setup-Hinweis an, während dieser Pull Request noch offen ist. Der Hinweis wird entfernt, nachdem der Pull Request zusammengeführt wurde. Wenn der Pull Request geschlossen wird, ohne zusammengeführt zu werden, erläutert die Übersicht, dass er vor Abschluss der Setup-Prozedur neu geöffnet werden muss.
%{
  title: "Projekteinrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  section: "translation",
  order: 2
}
---

Das Projektsetup bereitet ein verbundenes Repository für Glossia vor. Nach Auswahl eines Repositories im **Neuen Projekt**-Workflow wählen Sie einen von zwei Einrichtungsmodi.

## Einrichtungsmodi

| Modus | Was Glossia tut | Wann Sie es wählen |
|---|---|---|
| **Automatische Einrichtung** | Überprüft das Repository und eröffnet einen Pull Request mit der generierten `L10N.md`-Konfiguration für die ausgewählten Ziel-Sprachen. | Das Repository verfügt noch über keine Lokalisierungs-Konfiguration. |
| **Manuelle Konfiguration** | Erstellt das Projekt sofort. Es führt keine Prüfung des Repositories durch, ändert es nicht und erstellt keinen Pull Request. | Das Repository verfügt bereits über eine `L10N.md`-Datei, oder ein Maintainer wird sie erstellen. |

Die unten beschriebenen Zustände, Fortschrittsinformationen und der Pull Request beziehen sich ausschließlich auf den automatisierten Setup.

## Manuelle Konfiguration

Ein manuell konfiguriertes Projekt hat keinen Einrichtungszustand. Es kann sofort nach der Erstellung verwendet werden und wird bei einer fehlgeschlagenen Einrichtung nie verworfen.

Glossia startet mit dem nächsten Push auf den Standardzweig des Repositories einen Übersetzungs-Lauf. Der Lauf übersetzt in jedes in den Repository-Dateien [`L10N.md`](/docs/reference/l10n-md) deklarierte Ziel, da im **Neuen Projekt**-Workflow keine Zielsprachen ausgewählt wurden.

Bis zum ersten Übersetzungs-Lauf zeigt der Projektübersicht eine Erklärungsnotiz an, dass Glossia auf einen Push wartet, der eine `L10N.md`-Datei enthält.

## Voraussetzungen

- Das Konto verfügt über mindestens ein konfiguriertes Modell.
- Die Glossia GitHub App kann auf das ausgewählte Repository zugreifen.
- Der Benutzer kann im Konto Projekte erstellen.
- Bei der automatischen Einrichtung ist mindestens eine Zielsprache ausgewählt.

## Zustände

| Zustand | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Ausstehend** | Das Projekt wurde akzeptiert und wartet auf den Start. | Verfolgen Sie den Fortschritt oder verlassen Sie die Seite und kehren Sie später zurück. |
| **Laufend** | Glossia prüft und aktualisiert das Repository. | Verfolgen Sie die Live-Aktivität. |
| **Abgeschlossen** | Die Lokalisierungs-Grundlinie wurde vorbereitet und zur Überprüfung veröffentlicht. | Den Pull Request öffnen, prüfen und zusammenführen. |

Projekte sind vorläufig, solange die Einrichtung **Ausstehend** oder **Laufend** ist. Wenn die Einrichtung nicht abgeschlossen werden kann oder keine nutzbare Änderung veröffentlichen kann, bereinigt Glossia die Einrichtungsumgebung und löscht das vorläufige Projekt. Das Repository steht dann im **Neuen Projekt**-Workflow erneut zur Verfügung, sodass eine Einrichtung erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Einrichtungskarte bleibt im Workflow für neue Projekte und in der Projektübersicht verfügbar. Dazu gehören:

- Ein Status-Abzeichen und ein Fortschrittsbalken.
- Eine kurze Erklärung des aktuellen Zustands.
- Aktive Repository-Vorbereitung, -Inspektion, Dateiveränderung, -Prüfung und -Abschluss.
- Eine klare Fehlermeldung, wenn die Einrichtung nicht abgeschlossen werden kann.

Der Fortschritt wird gespeichert, solange das vorläufige Projekt existiert. Ein finales Scheitern verwerft dabei sowohl das Projekt als auch seinen sichtbaren Einrichtungsfortschritt.

## Abschluss-Ergebnis

Eine erfolgreiche verbundene Einrichtung erstellt einen dedizierten Branch und einen Pull Request gegenüber dem Standardzweig des Repositories. Der Pull Request enthält die generierte Lokalisierungs-Grundlinie, einschließlich `L10N.md`-Kontext und die kleinsten praktischen Änderungen, die zum Laden von lokalisiertem Inhalt notwendig sind.

Die Einrichtung veröffentlicht keine nicht nur den Header enthaltenden Zielkataloge. Wenn ein Lokalisierungs-Framework Zielkataloge vor der Übersetzung benötigt, enthalten diese Kataloge die extrahierten Quellnachrichteneinträge mit leeren Übersetzungswerten. Falls Zielkataloge noch nicht erforderlich sind, lässt die Einrichtung sie für den ersten Übersetzungs-Lauf stehen.

Glossia fusioniert den Pull Request nicht. Maintainer des Repositories prüfen und fusionieren ihn über ihren normalen GitHub-Prozess.

Die Projektübersicht zeigt einen Einrichtungshinweis, solange dieser Pull Request offen ist. Der Hinweis wird entfernt, nachdem der Pull Request zusammengeführt wurde. Wenn der Pull Request geschlossen wird, ohne zusammengeführt zu werden, erklärt die Übersicht, dass er neu eröffnet werden muss, bevor die Einrichtung als abgeschlossen betrachtet werden kann.

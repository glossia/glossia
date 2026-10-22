%{
  title: "Projekt-Einrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  section: "translation",
  order: 2
}
---

Die Projekteinrichtung bereitet ein verknüpotes repository für Glossia vor. Nachdem ein Benutzer in dem **Neues Projekt**-Flow ein Repository auswählt, wählt er eine der beiden Einrichtungsarten.

## Einrichtungsarten

| Art | Was Glossia tut | Wann man sie wählt |
|---|---|---|
| **Automatisierte Einrichtung** | Prüft das Repository und öffnet einen Pull Request mit der generierten `L10N.md`-Konfiguration für die ausgewählten Zielsprachen. | Das Repository hat noch keine Lokalisierungs-Konfiguration. |
| **Manuelle Konfiguration** | Erstellt das Projekt sofort. Das Repository wird nicht geprüft, verändert oder ein Pull Request wird nicht geöffnet. | Das Repository hat bereits eine `L10N.md`-Datei, oder ein Unterhaltender wird sie schreiben. |

Die unten beschriebenen Zustände, Fortschrittsinformationen und der Pull Request gelten nur für die automatisierte Einrichtung.

## Manuelle Konfiguration

Ein manuell konfiguriertes Projekt hat keinen Einrichtungsstatus. Es kann sofort nach der Erstellung verwendet werden und wird bei einer fehlgeschlagenen Einrichtung nie verworfen.

Glossia startet einen Übersetzungsablauf beim nächsten Push in den Standardzweig des Repositorys. Der Ablauf übersetzt in jedes Ziel, das in den Repository-[`L10N.md`](/docs/reference/l10n-md)-Dateien dekliniert ist, weil in dem **Neues Projekt**-Flow keine Zielsprachen ausgewählt sind.

Bis zum ersten Übersetzungsablauf zeigt die Projektübersicht eine Benachrichtigung, die erklärt, dass Glossia auf einen Push wartet, der eine `L10N.md`-Datei enthält.

## Voraussetzungen

- Der Benutzerkonto hat mindestens ein konfiguriertes Modell.
- Die Glossia GitHub App kann auf das ausgewählte Repository zugreifen.
- Der Benutzer kann Projekte im Konto erstellen.
- Für die automatisierte Einrichtung ist mindestens eine Zielsprache ausgewählt.

## Zustände

| Zustand | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **In Wartestellung** | Das Projekt wurde akzeptiert und wartet darauf, zu starten. | Fortschritt verfolgen oder die Seite verlassen und später zurückkehren. |
| **Läuft** | Glossia prüft und aktualisiert das Repository. | Verfolgen Sie die Live-Aktivität. |
| **Vollendet** | Die Lokalisierungs-Baseline wurde erstellt und für die Überprüfung veröffentlicht. | Öffnen, überprüfen und den Pull Request zusammenführen. |

Projekte sind vorläufig, solange die Einrichtung **In Wartestellung** oder **Läuft** ist. Wenn die Einrichtung nicht abgeschlossen werden kann oder eine nutzbare Änderung nicht veröffentlichen kann, reinigt Glossia die Einrichtungsumgebung und löscht das vorläufige Projekt. Das Repository wird dann im **Neues Projekt**-Flow verfügbar, so dass die Einrichtung erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Einrichtungskarte bleibt im Neuen-Projekt-Flow und auf der Projektübersicht verfügbar. Sie enthält:

- Ein Zustandsabzeichen und einen Fortschrittsbalken.
- Eine kurze Erklärung des aktuellen Zustands.
- Kürzlich Repositorv-Vorbereitung, Prüfung, Datei-Änderung, Check und Abschlussaktivität.
- Eine klare Fehlermeldung, wenn die Einrichtung nicht abgeschlossen werden kann.

Fortschritt wird gespeichert, solange das vorläufige Projekt existiert. Ein endgültiger Fehler verwirft sowohl das Projekt als auch seinen sichtbaren Einrichtungsfortschritt.

## Abgeschlossenes Ergebnis

Eine erfolgreiche verbundene Einrichtung erstellt einen dedizierten Branch und einen Pull Request gegen den Standardzweig des Repositorys. Der Pull Request enthält die generierte Lokalisierungs-Baseline, inklusive `L10N.md`-Kontext und die kleinsten praktischen Änderungen, die erforderlich sind, um lokalisierten Inhalt zu laden.

Die Einrichtung veröffentlicht keine Header-only-Zieleiter. Wenn das lokalisierungstechnische Framework Zielleiter vor der Übersetzung benötigt, enthalten die Kataloge die extrahierten Quell-Nachrichteneinträge mit leeren Übersetzungswerten. Wenn noch keine Zielleiter benötigt werden, hinterlässt die Einrichtung diese für den ersten Übersetzungsablauf.

Glossia verschließt den Pull Request nicht. Repository-Betreuer überprüfen und verschließen ihn über ihren normalen GitHub-Prozess.

Die Projektübersicht zeigt eine Einrichtungs-Benachrichtigung an, solange dieser Pull Request offen ist. Die Benachrichtigung wird entfernt, nachdem der Pull Request verschlossen wurde. Wenn der Pull Request geschlossen wird, ohne verschlossen zu werden, erklärt die Übersicht, dass er wieder geöffnet werden muss, bevor die Einrichtung als abgeschlossen betrachtet werden kann.

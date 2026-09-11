%{
  title: "Projekteinrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  order: 2
}
---
Projektsetup bereitet ein für Glossia verbundenes Repository vor. Es beginnt, nachdem ein Benutzer ein Repository und mindestens eine Zielsprache ausgewählt hat, in der **Neues Projekt** Ablauf.

## Voraussetzungen

- Das Konto verfügt über mindestens ein konfiguriertes Modell.
- Die Glossia GitHub-App kann auf das ausgewählte Repository zugreifen.
- Der Benutzer kann Projekte im Konto erstellen.
- Mindestens eine Zielsprache wurde ausgewählt.

## Zustände

| Status | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Ausstehend** | Das Projekt wurde akzeptiert und wartet auf den Start. | Verfolgen Sie den Fortschritt oder verlassen Sie die Seite und kommen Sie später zurück. |
| **Läuft** | Glossia prüft und aktualisiert das Repository. | Verfolgen Sie die Live-Aktivität. |
| **Abgeschlossen** | Die Lokalisierungs-Baseline wurde vorbereitet und zur Prüfung veröffentlicht. | Öffnen, überprüfen und den Pull Request zusammenführen. |

Projekte sind vorläufig, solange Setup **Ausstehend** oder **Laufend**. Wenn die Einrichtung nicht abgeschlossen oder eine nutzbare Änderung veröffentlicht werden kann, bereinigt Glossia die Einrichtungs-Umgebung und löscht das vorläufige Projekt. Das Repository steht dann in der **Neues Projekt** Fluss, damit die Einrichtung erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Einrichtungskarte bleibt im neuen Projekt-Fluss und in der Projektübersicht verfügbar. Sie enthält:

- Ein Status-Abzeichen und eine Fortschrittsleiste.
- Eine kurze Erklärung des aktuellen Zustands.
- Aktuelle Repository-Vorbereitung, -Inspektion, Dateiänderung, Prüfung und Abschlussaktivität.
- Eine klare Fehlermeldung, wenn die Einrichtung nicht abgeschlossen werden kann.

Fortschritt wird gespeichert, solange das vorläufige Projekt existiert. Ein endgültiger Fehler verwirft sowohl das Projekt als auch seinen sichtbaren Einrichtungsfortschritt.

## Abgeschlossenes Ergebnis

Eine erfolgreiche, verbundene Einrichtung erstellt einen dedizierten Branch und einen Pull-Request gegen den Standard-Branch des Repositorys. Der Pull-Request enthält die generierte Lokalisierungsbaseline, einschließlich `L10N.md` Kontext und die kleinsten praktikablen Änderungen, die zum Laden von lokalisiertem Inhalt notwendig sind.

Die Einrichtung veröffentlicht keine Header-Only-Zielkataloge. Wenn ein Lokalisierungsframework Zielkataloge vor der Übersetzung benötigt, enthalten diese die extrahierten Quellnachrichteneinträge mit leeren Übersetzungswerten. Wenn Zielkataloge noch nicht benötigt werden, hinterlässt die Einrichtung sie für den ersten Übersetzungslauf.

Glossia führt den Pull-Request nicht zusammen. Repository-Betreuer überprüfen und übernehmen ihn durch ihren normalen GitHub-Prozess.

Die Projektübersicht zeigt einen Einrichtungshinweis, solange dieser Pull-Request offen ist. Der Hinweis wird entfernt, nachdem der Pull-Request zusammengeführt wurde. Wenn der Pull-Request geschlossen wird, ohne zusammengeführt worden zu sein, erklärt die Übersicht, dass er wieder eröffnet werden muss, bevor die Einrichtung als abgeschlossen betrachtet werden kann.
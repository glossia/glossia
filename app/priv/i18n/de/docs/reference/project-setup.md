%{
  title: "Projekt-Einrichtung",
  summary: "Zustände, Fortschrittsinformationen und Ergebnisse der Repository-Einrichtung.",
  category: "Referenz",
  order: 2
}
---
Die Projekt-Einrichtung bereitet ein angebundenes Repository für Glossia vor. Sie beginnt, nachdem ein Benutzer ein Repository und mindestens eine Zielsprache im Ablauf **Neues Projekt** ausgewählt hat.

## Voraussetzungen

- Das Konto verfügt über mindestens ein konfiguriertes Modell.
- Die Glossia-GitHub-App kann auf das ausgewählte Repository zugreifen.
- Der Benutzer kann Projekte im Konto erstellen.
- Mindestens eine Zielsprache ist ausgewählt.

## Zustände

| Zustand | Bedeutung | Verfügbare Aktion |
|---|---|---|
| **Ausstehend** | Das Projekt wurde angenommen und wartet auf den Start. | Den Fortschritt verfolgen oder die Seite verlassen und später zurückkehren. |
| **Wird ausgeführt** | Glossia überprüft und aktualisiert das Repository. | Die Live-Aktivität verfolgen. |
| **Abgeschlossen** | Die Lokalisierungs-Baseline wurde vorbereitet und zur Überprüfung veröffentlicht. | Den Pull-Request öffnen, überprüfen und zusammenführen. |

Projekte sind vorläufig, solange die Einrichtung **Ausstehend** oder **Wird ausgeführt** ist. Wenn die Einrichtung nicht abgeschlossen werden oder keine verwendbare Änderung veröffentlichen kann, bereinigt Glossia die Einrichtungsumgebung und löscht das vorläufige Projekt. Das Repository wird anschließend im Ablauf **Neues Projekt** wieder verfügbar, sodass die Einrichtung erneut versucht werden kann.

## Sichtbarer Fortschritt

Die Einrichtungskarte bleibt im Ablauf für neue Projekte und in der Projektübersicht verfügbar. Sie enthält:

- Ein Status-Badge und einen Fortschrittsbalken.
- Eine kurze Erklärung des aktuellen Zustands.
- Aktuelle Aktivitäten zur Repository-Vorbereitung, -Überprüfung, -Dateiänderung, -Kontrolle und zum Abschluss.
- Eine eindeutige Fehlermeldung, wenn die Einrichtung nicht abgeschlossen werden kann.

Der Fortschritt wird gespeichert, solange das vorläufige Projekt existiert. Ein fataler Fehler verwirft sowohl das Projekt als auch den sichtbaren Einrichtungsfortschritt.

## Abgeschlossenes Ergebnis

Eine erfolgreich angebundene Einrichtung erstellt einen dedizierten Branch und einen Pull-Request für den Standard-Branch des Repositorys. Der Pull-Request enthält die generierte Lokalisierungs-Baseline, einschließlich des Kontexts `GLOSSIA.md` und der kleinstmöglichen praktischen Änderungen, die zum Laden lokalisierter Inhalte erforderlich sind.

Die Einrichtung veröffentlicht keine Zielkataloge, die nur Header enthalten. Wenn ein Lokalisierungs-Framework vor der Übersetzung Zielkataloge erfordert, enthalten die Kataloge die extrahierten Einträge der Quellnachrichten mit leeren Übersetzungswerten. Wenn Zielkataloge noch nicht erforderlich sind, belässt die Einrichtung diese für den ersten Übersetzungslauf.

Glossia führt den Pull-Request nicht zusammen. Repository-Maintainer überprüfen und führen ihn über ihren normalen GitHub-Prozess zusammen.

Die Projektübersicht zeigt einen Einrichtungshinweis an, solange dieser Pull-Request geöffnet ist. Der Hinweis wird entfernt, nachdem der Pull-Request zusammengeführt wurde. Wenn der Pull-Request geschlossen wird, ohne zusammengeführt worden zu sein, wird in der Übersicht erklärt, dass er erneut geöffnet werden muss, bevor die Einrichtung als abgeschlossen betrachtet werden kann.
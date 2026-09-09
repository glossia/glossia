%{
  title: "Erste Schritte",
  summary:
    "Verbinden Sie ein Repository und bereiten Sie dessen erste Lokalisierungseinrichtung vor.",
  category: "Anleitungen",
  order: 1
}
---
Dieses Tutorial verbindet ein GitHub-Repositorium mit Glossia, wählt die ersten Zielsprachen aus und erstellt eine Lokalisierungsgrundlage für Ihr Team zur Prüfung.

## Vor dem Start

Du benötigst:

- Ein Glossia-Konto, in dem du Einstellungen und Projekte verwalten kannst.
- Ein GitHub-Repositorium, auf das du der Glossia GitHub App die Berechtigung zum Lesen und Aktualisieren erteilen kannst.
- Ein Provider-Schlüssel für ein unterstütztes [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Ein Accountmodell konfigurieren

Öffnen **Einstellungen**, dann **Modelle**, und auswählen **Neues Modell**.

1. Geben Sie dem Modell einen kurzen Namen, wie `translation-default`.
2. Öffnen Sie den Modell-Selektor und geben Sie einen Teil eines Provider- oder Modellnamens ein, um die Liste zu filtern.
3. Wählen Sie das Modell aus, das Glossia verwenden soll.
4. Geben Sie den Provider-Schlüssel ein und speichern Sie das Modell.

Der kurze Name ermöglicht es Repositories, sich auf dieses Kontomodell zu beziehen, ohne Provider-Anmeldedaten in die Versionskontrolle zu geben. Siehe [Einrichten eines Modell-Providers](/docs/how-to/configure-a-model-provider) für weitere Details.

## 2\. Starten Sie ein Projekt

Zurück zu **Projekten** und wählen Sie **Neues Projekt**.

Wenn Glossia den Zugriff auf das Repository anfordert, folgen Sie dem Link zu GitHub und gewähren Sie der Glossia GitHub App Zugriff auf das Repository. Nach der Rückkehr zu Glossia, öffnen Sie es erneut. **Neues Projekt** wenn nötig.

## 3\. Wählen Sie ein Repository

Wählen Sie das Repository aus, das Sie lokalisieren möchten. Glossia listet nur Repositories auf, die über die GitHub-App-Installation Ihres aktuellen Kontos verfügbar sind.

Weiter zum Sprachschritt.

## 4\. Wählen Sie Zielsprachen

Wählen Sie eine oder mehrere Sprachen, die aus dem Quellinhalt des Repositories generiert werden sollen, und starten Sie dann die Einrichtung.

## 5\. Verfolgen Sie den Fortschritt der Einrichtung

Behalten Sie die Einrichtungsseite offen, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und die jüngsten Aktivitäten, einschließlich der Vorbereitung des Repositories, der Dateiinspektion, Änderungen, Prüfungen und des Abschlusses.

Sie können die Seite verlassen und zur Projektübersicht zurückkehren, ohne den Einrichtungsstatus zu verlieren. Falls die Einrichtung fehlschlägt, erklärt dieselbe Karte, welche Punkte Beachtung benötigen, und bietet **Einrichtung wiederholen**.

## 6\. Ergebnis prüfen

Wenn die Einrichtung abgeschlossen ist, öffnen Sie die Projektübersicht und überprüfen Sie den für das Repository erstellten Pull-Request. Die vorgeschlagene Basis enthält normalerweise:

- Eine Wurzel `L10N.md` Datei mit Quell-Sprache, Quellpfaden und Zielsprachen.
- Die minimalen Änderungen an der Anwendung oder am Inhalt, die notwendig sind, um lokalisierte Dateien zu laden.
- Jede leichte Validierung, die bereits im Repository verfügbar war.

Überprüfen und führen Sie den Pull-Request über Ihren normalen GitHub-Workflow zusammen. Zukünftige Übersetzungsläufe verwenden den zusammengeführten `L10N.md` Kontext.

Der Projektüberblick hält den Setup-Pull-Request sichtbar, bis er zusammengeführt ist. Wenn er geschlossen wird, ohne zusammengeführt zu werden, öffnen Sie ihn über den Link in der Setup-Notiz erneut.

## Nächste Schritte

- [Eine neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Verstehen Sie die Projekteinrichtungszustände](/docs/reference/project-setup)
- [Erfahren Sie, wie Account-Modelle funktionieren](/docs/explanation/account-models)
%{
  title: "Erste Schritte",
  summary:
    "Verbinden Sie ein Repository und bereiten Sie die erste Lokalisierungseinrichtung vor.",
  category: "Anleitungen",
  order: 1
}
---
Dieses Tutorial verbindet ein GitHub-Repository mit Glossia, wählt die ersten Zielsprachen aus und erstellt eine Lokalisierungs-Baseline für Ihr Team zur Überprüfung.

## Bevor Sie beginnen

Sie benötigen:

- Ein Glossia-Konto, in dem Sie Einstellungen und Projekte verwalten können.
- Ein GitHub-Repository, für das Sie der Glossia GitHub App Lese- und Aktualisierungsberechtigungen erteilen können.
- Ein Anbieter-Schlüssel für ein unterstütztes [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Ein Kontomodell einrichten

Öffnen **Einstellungen**, dann **Modelle**, und wählen **Neues Modell**.

1. Geben Sie dem Modell einen kurzen Handle, wie `translation-default`.
2. Öffnen Sie die Modellauswahl und geben Sie einen Teil des Provider- oder Modellnamens ein, um die Liste zu filtern.
3. Wählen Sie das Modell, das Glossia verwenden soll.
4. Geben Sie den Provider-Schlüssel ein und speichern Sie das Modell.

Der Handle ermöglicht Repositories, sich auf dieses Kontomodell zu beziehen, ohne die Provider-Zugangsdaten in die Versionskontrolle zu legen. Siehe [Modell-Provider konfigurieren](/docs/how-to/configure-a-model-provider) für weitere Details.

## 2\. Starten Sie ein Projekt

Zurück zu **Projekten** und wählen Sie **Neues Projekt**.

Wenn Glossia den Zugriff auf das Repository anfragt, folgen Sie dem Link zu GitHub und gewähren Sie der Glossia GitHub App Zugriff auf das Repository. Nach Rückkehr zu Glossia, öffnen Sie **Neues Projekt** falls erforderlich.

## 3\. Ein Repository auswählen

Wählen Sie das Repository aus, das Sie übersetzen möchten. Glossia listet nur Repositories auf, die über die GitHub App-Installation des aktuellen Kontos verfügbar sind.

Weiter zum Sprachschritt.

## 4\. Zielsprachen auswählen

Wählen Sie eine oder mehrere Sprachen, die aus dem Quellinhalt des Repositories generiert werden sollen, und starten Sie die Einrichtung.

## 5\. Einrichtungsfortschritt verfolgen

Halten Sie die Einrichtungsseite offen, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und die jüngsten Aktivitäten, einschließlich der Repository-Vorbereitung, der Dateiinspektion, Änderungen, Überprüfungen und der Fertigstellung.

Sie können die Seite verlassen und zur Projektübersicht zurückkehren, ohne den Einrichtungszustand zu verlieren. Fehlt die Einrichtung, erklärt die gleiche Karte, was Beachtung bedarf, und bietet **Einrichtung erneut versuchen**.

## 6\. Das Ergebnis überprüfen

Wenn die Einrichtung abgeschlossen ist, öffnen Sie die Projektübersicht und überprüfen Sie die für das Repository erstellte Pull Request. Der vorgeschlagene Baseline enthält in der Regel:

- Eine root `L10N.md` Datei mit Quellsprache, Quellpfaden und Zielsprachen.
- Die minimalen Änderungen der Anwendung oder des Inhalts, die erforderlich sind, um lokalisierte Dateien zu laden.
- Eine leichte Validierung, die bereits im Repository verfügbar war.

Überprüfen und zusammenführen Sie den Pull-Request über Ihren normalen GitHub-Workflow. Zukünftige Übersetzungsläufe verwenden den zusammengeführten `L10N.md` Kontext.

Die Projektübersicht hält den Einrichtung-Pull-Request sichtbar, bis er zusammengeführt ist. Wenn er geschlossen wird, ohne zusammengeführt zu werden, öffnen Sie ihn erneut über den Link in der Einrichtungsnachricht.

## Nächste Schritte

- [Neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Zustände der Projekteinrichtung verstehen](/docs/reference/project-setup)
- [Erfahren Sie, wie Account-Modelle funktionieren](/docs/explanation/account-models)
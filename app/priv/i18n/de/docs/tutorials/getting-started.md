%{
  title: "Erste Schritte",
  summary:
    "Verbinden Sie ein Repository und richten Sie die erste Lokalisierungseinrichtung ein.",
  category: "Anleitungen",
  order: 1
}
---
Dieses Tutorial verknüpft ein GitHub-Repository mit Glossia, wählt die ersten Zielsprachen und erstellt eine Lokalisierungsbasis für Ihr Team zur Prüfung.

## Bevor Sie beginnen

Benötigt:

- Ein Glossia-Konto, auf dem Sie Einstellungen und Projekte verwalten können.
- Ein GitHub-Repository, für das Sie der Glossia GitHub App Berechtigungen zum Lesen und Aktualisieren erteilen können.
- Ein Anbieter-Schlüssel für ein unterstütztes [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Ein Konto-Modell konfigurieren

Öffnen **Einstellungen**, dann **Modelle**, und wählen Sie **Neues Modell**.

1. Geben Sie dem Modell einen kurzen Bezeichner, wie `translation-default`.
2. Öffnen Sie die Modell-Auswahl und geben Sie einen Teil des Anbieter- oder Modellnamens ein, um die Liste zu filtern.
3. Wählen Sie das Modell aus, das Glossia verwenden soll.
4. Geben Sie den Anbieter-Schlüssel ein und speichern Sie das Modell.

Der Bezeichner ermöglicht Repositories, sich auf dieses Konto-Modell zu beziehen, ohne Anbieter-Zugangsdaten in die Versionskontrolle zu schreiben. Siehe [Modell-Anbieter konfigurieren](/docs/how-to/configure-a-model-provider) für weitere Details.

## 2\. Starte ein Projekt

Zurück zu **Projekten** und wählen Sie **Neues Projekt**.

Wenn Glossia den Zugriff auf das Repository anfordert, folgen Sie dem Link zu GitHub und gewähren Sie der Glossia GitHub App Zugriff auf das Repository. Nach der Rückkehr zu Glossia, öffnen Sie **Neues Projekt** falls erforderlich.

## 3\. Ein Repository auswählen

Wählen Sie das Repository aus, das Sie übersetzen möchten. Glossia listet ausschließlich Repositories auf, die über die GitHub-App-Installation des aktuellen Kontos verfügbar sind.

Weiter zum nächsten Sprachschritt.

## 4\. Ziel­sprachen auswählen

Wählen Sie eine oder mehrere Sprachen aus, die aus den Quellinhalten des Repositorys generiert werden sollen, und starten Sie die Einrichtung.

## 5\. Einrichtungsfortschritt verfolgen

Lassen Sie die Einrichtungsseite offen, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und die neuesten Aktivitäten, einschließlich Repository-Vorbereitung, Dateiprüfung, Änderungen, Überprüfungen und Abschluss.

Sie können die Seite verlassen und zur Projektübersicht zurückkehren, ohne den Einrichtungsstatus zu verlieren. Wenn die Einrichtung fehlschlägt, erklärt dieselbe Karte, was zu beachten ist, und bietet **Einrichtung wiederholen**.

## 6\. Ergebnis überprüfen

Wenn die Einrichtung abgeschlossen ist, öffnen Sie die Projektübersicht und überprüfen Sie den für das Repository erstellten Pull-Request. Der vorgeschlagene Basisstand enthält normalerweise:

- Eine Wurzel- `L10N.md` Datei mit Quellsprache, Quellpfaden und Zielsprachen.
- Die kleinstmöglichen Änderungen an Inhalt oder Anwendung, die zum Laden von lokalisierten Dateien erforderlich sind.
- Jede leichte Validierung, die bereits im Repository verfügbar war.

Überprüfen und zusammenführen Sie die Pull Request über Ihren normalen GitHub-Workflow. Zukünftige Übersetzungsdurchläufe nutzen den zusammengeführten `L10N.md` Kontext.

Der Projektüberblick hält die Setup-Pull Request sichtbar, bis sie zusammengeführt ist. Falls sie geschlossen wird, ohne dass sie zusammengeführt wurde, öffnen Sie sie erneut über den Link in der Setup-Benachrichtigung.

## Nächste Schritte

- [Neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Projektsetup-Zustände verstehen](/docs/reference/project-setup)
- [Lernen Sie, wie Kontenmodelle funktionieren](/docs/explanation/account-models)
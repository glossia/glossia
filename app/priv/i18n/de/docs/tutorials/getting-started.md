%{
  title: "Erste Schritte",
  summary:
    "Verbinden Sie ein Repository und bereiten Sie dessen erste Lokalisierungseinrichtung vor.",
  category: "Anleitungen",
  order: 1
}
---
Dieses Tutorial verknüpft ein GitHub-Repository mit Glossia, wählt die ersten Zielsprachen aus und bereitet eine Lokalisierungsgrundlage für Ihr Team zur Überprüfung vor.

## Bevor Sie beginnen

Sie benötigen:

- Ein Glossia-Konto, in dem Sie Einstellungen und Projekte verwalten können.
- Ein GitHub-Repository, für das Sie der Glossia GitHub App die Berechtigung erteilen können, es zu lesen und zu aktualisieren.
- Ein Provider-Schlüssel für ein unterstütztes [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Konfigurieren Sie ein Kontomodell

Öffnen Sie **Einstellungen**, dann **Modelle**, und wählen Sie **Neues Modell**.

1. Geben Sie dem Modell einen kurzen Handle, zum Beispiel `translation-default`.
2. Öffnen Sie das Modell-Auswahlmenü und geben Sie einen Teil eines Anbieters- oder Modellnamens ein, um die Liste zu filtern.
3. Wählen Sie das Modell aus, das Glossia verwenden soll.
4. Geben Sie den Anbieter-Schlüssel ein und speichern Sie das Modell.

Der Handle ermöglicht Repositories, sich auf dieses Konto-Modell zu beziehen, ohne Credentials für den Anbieter in die Versionskontrolle zu speichern. Siehe [Einen Modellanbieter einrichten](/docs/how-to/configure-a-model-provider) für weitere Details.

## 2\. Starten Sie ein Projekt

Zurück zu **Projekten** und wählen Sie **Neues Projekt**.

Wenn Glossia Zugriff auf das Repository anfordert, folgen Sie dem Link zu GitHub und gewähren Sie der Glossia GitHub App Zugriff auf das Repository. Nachdem Sie zu Glossia zurückgekehrt sind, öffnen Sie **Neues Projekt** falls erforderlich.

## 3\. Repository auswählen

Wählen Sie das Repository aus, das Sie lokalisieren möchten. Glossia listet nur Repositories auf, die über die Installation der GitHub App des aktuellen Kontos verfügbar sind.

Weiter zum Sprachschritt.

## 4\. Zielsprachen auswählen

Wählen Sie eine oder mehrere Sprachen aus, die aus dem Quellinhalt des Repositorys erstellt werden sollen, und starten Sie die Einrichtung.

## 5\. Einrichtungsfortschritt verfolgen

Halten Sie die Einrichtungsseite offen, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und die neuesten Aktivitäten, einschließlich Repository-Vorbereitung, Dateiinspektion, Änderungen, Prüfungen und Abschluss.

Sie können die Seite verlassen und zur Projektoübersicht zurückkehren, ohne den Einrichtungsstatus zu verlieren. Fiel die Einrichtung fehl, erklärt die gleiche Karte, was bearbeitet werden muss und bietet **Einrichtung neu starten**.

## 6\. Ergebnisse überprüfen

Wenn die Einrichtung abgeschlossen ist, öffnen Sie die Projektoübersicht und überprüfen Sie den für das Repository erstellten Pull Request. Die vorgeschlagene Baseline umfasst normalerweise:

- Eine Wurzel- `L10N.md` Datei mit Quellsprache, Quellpfaden und Zielsprachen.
- Die minimalen Änderungen an der Anwendung oder am Inhalt, die erforderlich sind, um lokalisierte Dateien zu laden.
- Jede leichte Validierung, die bereits im Repository verfügbar war.

Überprüfen und verschmelzen Sie den Pull-Request über Ihren normalen GitHub-Workflow. Zukünftige Übersetzungsläufe verwenden den verschmolzenen `L10N.md` Kontext.

Die Projektübersicht behält den Setup-Pull-Request sichtbar, bis er verschmolzen ist. Wenn er geschlossen wird, ohne verschmolzen zu werden, öffnen Sie ihn erneut über den Link in der Setup-Benachrichtigung.

## Nächste Schritte

- [Eine neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Projekt-Setup-Zustände verstehen](/docs/reference/project-setup)
- [Erfahren Sie, wie Kontomodelle funktionieren](/docs/explanation/account-models)
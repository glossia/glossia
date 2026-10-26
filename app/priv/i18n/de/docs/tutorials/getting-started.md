%{
  title: "Erste Schritte",
  summary:
    "Verbinden Sie ein Repository und richten Sie dessen erste Lokalisierungseinrichtung ein.",
  category: "Anleitungen",
  order: 1
}
---

Dieses Tutorial verknüpft ein GitHub-Repository mit Glossia, wählt die ersten Zielsprachen aus und erstellt eine Lokalisierungsgrundlinie, die Ihr Team überprüfen kann.

## Bevor Sie beginnen

Sie benötigen:

- Ein Glossia-Konto, in dem Sie Einstellungen und Projekte verwalten können.
- Ein GitHub-Repository, für das Sie der Glossia GitHub App Lese- und Schreibberechtigung erteilen können.
- Ein Provider-Schlüssel für ein unterstütztes [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model).

## 1. Konfigurieren eines Kontomodells

Öffnen Sie **Einstellungen**, dann **Modelle**, und wählen Sie **Neues Modell** aus.

1. Geben Sie dem Modell einen kurzen Namen, beispielsweise `translation-default`.
2. Öffnen Sie den Modell-Auswahler und geben Sie einen Teil des Namenes eines Anbieters oder Modells ein, um die Liste zu filtern.
3. Wählen Sie das Modell aus, das Glossia verwenden soll.
4. Geben Sie den Provider-Schlüssel ein und speichern Sie das Modell.

Dieser Name ermöglicht Repositories, sich auf dieses Kontomodell zu beziehen, ohne Provider-Anmeldedaten in die Versionskontrolle zu legen. Weitere Details finden Sie unter [Ein Modellanbieter konfigurieren](/docs/how-to/configure-a-model-provider).

## 2. Ein Projekt starten

Fahren Sie zu **Projekte** und wählen Sie **Neues Projekt** aus.

Wenn Glossia nach Zugriff auf das Repository fragt, befolgen Sie den Link zu GitHub und erteilen Sie der Glossia GitHub App Zugriff auf das Repository. Nach der Rückkehr nach Glossia öffnen Sie **Neues Projekt** erneut, falls notwendig.

## 3. Ein Repository auswählen

Wählen Sie das Repository aus, das Sie lokalisieren möchten. Glossia listet nur Repositories auf, die über die GitHub App-Installation des aktuellen Kontos verfügbar sind.

## 4. Konfiguration des Projekts wählen

Wählen Sie **Automatisierte Einrichtung** aus, um Glossia die Überprüfung des Repositories und den Vorschlag der Lokalisierungs-Konfiguration über einen Pull Request zu ermöglichen. Dieses Tutorial folgt diesem Weg.

Wenn das Repository bereits eine `L10N.md`-Datei enthält oder Sie diese lieber selbst schreiben möchten, wählen Sie **Manuelle Konfiguration** statt. Glossia erstellt das Projekt sofort und Sie können die restlichen Schritte überspringen. Siehe [Projektaufbau](/docs/reference/project-setup) für die Details, was jeder Modus tut.

## 5. Zielsprachen wählen

Wählen Sie eine oder mehrere Sprachen aus, die aus dem Quellinhalt des Repositorys erstellt werden sollen, und starten Sie die Einrichtung.

## 6. Fortschritt der Einrichtung verfolgen

Bleiben Sie auf der Einrichtung-Seite, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und die jüngsten Aktivitäten, einschließlich Repository-Vorbereitung, Dateiüberprüfung, Änderungen, Prüfungen und Abschluss.

Sie können die Seite verlassen und zur Projektübersicht zurückkehren, ohne den Einrichtungszustand zu verlieren. Wenn die Einrichtung fehlschlägt, lesen Sie die Fehlermeldung. Glossia verwirft das vorläufige Projekt; beheben Sie die Voraussetzung und starten Sie erneut über **Neues Projekt**. Siehe [Wiederholung der Projekteinrichtung](/docs/how-to/retry-project-setup).

## 7. Das Ergebnis überprüfen

Wenn die Einrichtung abgeschlossen ist, öffnen Sie die Projektübersicht und überprüfen Sie den für das Repository erstellten Pull Request. Die vorgeschlagene Grundlinie umfasst normalerweise:

- Eine Wurzel-`L10N.md`-Datei mit Quellensprache, Quellpfaden und Zielsprachen.
- Die minimalen Änderungen an der Anwendung oder am Inhalt, die zum Laden lokalisiertierter Dateien erforderlich sind.
- Jede leichte Validierung, die bereits im Repository verfügbar war.

Prüfen und fusionieren Sie den Pull Request über Ihren normalen GitHub-Workflow. Künftige Übersetzungsläufe verwenden den `L10N.md`-Kontext.

Die Projektübersicht hält den Einrichtungen-Pull Request sichtbar, bis er fusioniert wurde. Wenn er ohne Fusionierung geschlossen wird, öffnen Sie ihn erneut über den Link im Einrichtungshinweis.

## Nächste Schritte

- [Eine neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Projekt-Einrichtungszustände verstehen](/docs/reference/project-setup)
- [Lernen Sie, wie Kontomodell funktionieren](/docs/explanation/account-models)

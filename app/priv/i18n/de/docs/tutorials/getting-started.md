%{
  title: "Erste Schritte",
  summary:
    "Verbinden Sie ein Repository und bereiten Sie die erste Lokalisierungseinrichtung vor.",
  category: "Anleitungen",
  order: 1
}
---
Dieses Tutorial verbindet ein GitHub-Repository mit Glossia, wählt die ersten Zielsprachen aus und bereitet eine Lokalisierungs-Basis für Ihr Team zur Überprüfung vor.

## Bevor Sie beginnen

Sie benötigen:

- Ein Glossia-Konto, in dem Sie Einstellungen und Projekte verwalten können.
- Ein GitHub-Repository, für das Sie der Glossia GitHub App Zugriff zum Lesen und Aktualisieren gewähren können.
- Ein Anbieter-Schlüssel für ein unterstütztes [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Ein Kontomodell konfigurieren

Öffnen **Einstellungen**, dann **Modelle**, und wählen Sie **Neues Modell**.

1. Geben Sie dem Modell einen kurzen Alias, wie zum Beispiel `translation-default`.
2. Öffnen Sie den Modell-Selector und geben Sie einen Teil des Anbieter- oder Modellnamens ein, um die Liste zu filtern.
3. Wählen Sie das Modell aus, das Sie in Glossia verwenden möchten.
4. Geben Sie den Anbieter-Schlüssel ein und speichern Sie das Modell.

Der Alias ermöglicht Repositorien, sich auf dieses Account-Modell zu beziehen, ohne Anbieterschlüssel in der Versionskontrolle zu hinterlegen. Siehe [Modellanbieter konfigurieren](/docs/how-to/configure-a-model-provider) für weitere Details.

## 2\. Starten Sie ein Projekt

Zurück zu **Projekten** und wählen Sie **Neues Projekt**.

Wenn Glossia den Zugriff auf das Repositorium anfordert, folgen Sie dem Link zu GitHub und gewähren Sie der Glossia GitHub App den Zugriff auf das Repositorium. Nach dem Zurückkehren zu Glossia, öffnen Sie **Neues Projekt** falls erforderlich.

## 3\. Wählen Sie ein Repository

Wählen Sie das Repository aus, das Sie lokalisiert möchten. Glossia listet nur Repositories auf, die über die GitHub-App-Installation des aktuellen Kontos verfügbar sind.

## 4\. Wählen Sie, wie das Projekt eingerichtet wird

Wählen Sie **Automatisierte Einrichtung** damit Glossia das Repository untersucht und die Lokalisierungskonfiguration in einem Pull Request vorschlägt. Dieses Tutorial folgt diesem Pfad.

Wenn das Repository bereits `L10N.md` Datei, oder Sie bevorzugen es, es selbst zu schreiben, wählen Sie **Manuelle Konfiguration** Stattdessen. Glossia erstellt das Projekt sofort und Sie können die verbleibenden Schritte überspringen. Siehe [Projekt einrichten](/docs/reference/project-setup) für das, was jeder Modus tut.

## 5\. Wählen Sie Zielsprachen

Wählen Sie eine oder mehrere Sprachen aus, die aus den Quelldaten des Repositorys erstellt werden sollen, und starten Sie die Einrichtung.

## 6\. Verfolgen Sie den Fortschritt der Einrichtung.

Behalten Sie die Einrichtungsseite geöffnet, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und die jüngsten Aktivitäten, einschließlich der Repository-Vorbereitung, der Dateiüberprüfung, Änderungen, Prüfungen und des Abschlusses.

Sie können die Seite verlassen und zur Projektübersicht zurückkehren, ohne den Einrichtungsstatus zu verlieren. Falls die Einrichtung fehlschlägt, lesen Sie die Fehlermitteilung. Glossia verwirft das vorläufige Projekt; beheben Sie die Voraussetzung und beginnen Sie erneut durch **Neues Projekt**. Siehe [Projekt-Einrichtung wiederholen](/docs/how-to/retry-project-setup).

## 7\. Ergebnis überprüfen

Wenn die Einrichtung abgeschlossen ist, öffnen Sie die Projektübersicht und überprüfen Sie den für das Repository erstellten Pull Request. Die vorgeschlagene Baseline enthält normalerweise:

- Eine Wurzel `L10N.md` Datei mit Quellsprache, Quellpfaden und Zielsprachen.
- Die kleinsten Änderungen an der Anwendung oder am Inhalt, die benötigt werden, um lokalisierte Dateien zu laden.
- Jede leichtgewichtige Validierung, die bereits im Repository verfügbar war.

Überprüfen und zusammenführen Sie den Pull-Request über Ihren normalen GitHub-Workflow. Zukünftige Übersetzungsläufe verwenden den verschmolzenen `L10N.md` Kontext.

Die Projektübersicht hält den Einrichtungs-Pull-Request sichtbar, bis er zusammengeführt wurde. Wenn er geschlossen ist, ohne zusammengeführt zu sein, öffnen Sie ihn erneut über den Link im Hinweis zur Einrichtung.

## Nächste Schritte

- [Eine neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Projekt-Einrichtungsphasen verstehen](/docs/reference/project-setup)
- [Lernen Sie, wie Kontenmodelle funktionieren](/docs/explanation/account-models)
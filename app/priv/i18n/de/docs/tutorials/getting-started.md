%{
  title: "Erste Schritte",
  summary: "Verbinde ein Repository und richte dessen erste Lokalisierungseinrichtung ein.",
  category: "Anleitungen",
  order: 1
}
---
Dieses Tutorial verbindet ein GitHub-Repository mit Glossia, wählt seine ersten Zielsprachen aus und bereitet eine Lokalisierungs-Baseline für Ihr Team zur Überprüfung vor.

## Bevor Sie beginnen

Sie benötigen:

- Ein Glossia-Konto, in dem Sie Einstellungen und Projekte verwalten können.
- Ein GitHub-Repository, auf das die Glossia GitHub-App die Berechtigung zum Lesen und Aktualisieren erteilen kann.
- Ein Anbieter-Schlüssel für ein unterstütztes [Großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Ein Account-Modell konfigurieren

Öffnen Sie **Einstellungen**, dann **Modelle** und wählen Sie **Neues Modell**.

1. Geben Sie dem Modell einen kurzen Handle, beispielsweise `translation-default`.
2. Öffnen Sie den Modell-Auswahl und geben Sie einen Teil eines Anbieter- oder Modellnamens ein, um die Liste zu filtern.
3. Wählen Sie das Modell aus, das Glossia verwenden soll.
4. Geben Sie den Anbieter-Schlüssel ein und speichern Sie das Modell.

Der Handle ermöglicht Repositories, sich auf dieses Account-Modell zu beziehen, ohne Einstellungen mit Anbieterzugangsdaten in die Quellverwaltung einzufügen. Siehe [Ein Modell-Anbieter konfigurieren](/docs/how-to/configure-a-model-provider) für weitere Details.

## 2\. Ein Projekt starten

Wechseln Sie zurück zu **Projekte** und wählen Sie **Neues Projekt**.

Wenn Glossia nach Repository-Zugriff fragt, folgen Sie dem Link zu GitHub und erteilen Sie der Glossia GitHub-App Zugriff auf das Repository. Nach der Rückkehr zu Glossia öffnen Sie **Neues Projekt** erneut, falls erforderlich.

## 3\. Ein Repository auswählen

Wählen Sie das Repository aus, das lokalisiert werden soll. Glossia listet nur Repositories auf, die über die GitHub-App-Installation des aktuellen Kontos verfügbar sind.

Gehen Sie zum Sprachschritt fort.

## 4\. Zielsprachen auswählen

Wählen Sie eine oder mehrere Sprachen aus, die aus dem Quellinhalt des Repositories erstellt werden sollen, und starten Sie die Einrichtung.

## 5\. Dem Einrichtungsfortschritt folgen

Halten Sie die Einrichtungsseite offen, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und jüngste Aktivitäten, einschließlich Repositoriumsvorbereitung, Dateianalyse, Änderungen, Prüfungen und Abschluss.

Sie können die Seite verlassen und zur Projektübersicht zurückkehren, ohne den Einrichtungszustand zu verlieren. Wenn die Einrichtung fehlschlägt, erklärt die gleiche Karte, was benötigt wird, und bietet die Möglichkeit, **Einrichtung neu versuchen**.

## 6\. Das Ergebnis überprüfen

Wenn die Einrichtung abgeschlossen ist, öffnen Sie die Projektübersicht und überprüfen Sie den für das Repository erstellten Pull-Request. Die vorgeschlagene Baseline umfasst normalerweise:

- Eine `GLOSSIA.md`GLOSSIA.md\`-Datei mit der Quellsprache, Quellpfaden und den Zielsprachen.
- Die kleinsten Anwendungs- oder Inhaltsänderungen, die erforderlich sind, um lokalisierte Dateien zu laden.
- Alle leichten Validierungen, die im Repository bereits verfügbar waren.

Überprüfen und führen Sie den Pull-Request unter Verwendung Ihres normalen GitHub-Workflows zusammen. Zukünftige Übersetzungs-Läufe verwenden den zusammengeführten `GLOSSIA.md`-Kontext.

Die Projektübersicht behält den Einrichtung-Pull-Request bis zur Zusammenführung sichtbar. Wenn er ohne Zusammenführung geschlossen wurde, öffnen Sie ihn neu über den Link in der Einrichtungsmitteilung.

## Nächste Schritte

- [Eine neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Projektzustände der Einrichtung verstehen](/docs/reference/project-setup)
- [Erfahren Sie, wie Account-Modelle funktionieren](/docs/explanation/account-models)
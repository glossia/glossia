%{
  title: "Erste Schritte",
  summary: "Verbinden Sie ein Repository und bereiten Sie dessen erstes Lokalisierungs-Setup vor.",
  category: "tutorials",
  order: 1
}
---
Dieses Tutorial verbindet ein GitHub-Repository mit Glossia, wählt die ersten Zielsprachen aus und bereitet eine Lokalisierungs-Baseline für die Überprüfung durch Ihr Team vor.

## Bevor Sie beginnen

Sie benötigen:

- Ein Glossia-Konto, in dem Sie Einstellungen und Projekte verwalten können.
- Ein GitHub-Repository, für das Sie der Glossia-GitHub-App die Berechtigung zum Lesen und Aktualisieren erteilen können.
- Einen Provider-Schlüssel für ein unterstütztes [Large Language Model](https://en.wikipedia.org/wiki/Large_language_model).

## 1. Konfigurieren Sie ein Konto-Modell

Öffnen Sie die **Einstellungen**, wählen Sie dann **Modelle** und klicken Sie auf **Neues Modell**.

1. Weisen Sie dem Modell ein kurzes Handle zu, wie beispielsweise `translation-default`.
2. Öffnen Sie die Modellauswahl und geben Sie einen Teil des Provider- oder Modellnamens ein, um die Liste zu filtern.
3. Wählen Sie das Modell aus, das Glossia verwenden soll.
4. Geben Sie den Provider-Schlüssel ein und speichern Sie das Modell.

Über dieses Handle können Repositories auf dieses Konto-Modell verweisen, ohne dass Provider-Anmeldedaten in der Versionsverwaltung hinterlegt werden müssen. Weitere Informationen finden Sie unter [Einen Modell-Provider konfigurieren](/docs/how-to/configure-a-model-provider).

## 2. Starten Sie ein Projekt

Kehren Sie zu **Projekte** zurück und wählen Sie **Neues Projekt**.

Wenn Glossia Zugriff auf das Repository anfordert, folgen Sie dem Link zu GitHub und gewähren Sie der Glossia-GitHub-App Zugriff auf das Repository. Öffnen Sie nach der Rückkehr zu Glossia bei Bedarf erneut **Neues Projekt**.

## 3. Wählen Sie ein Repository aus

Wählen Sie das Repository aus, das Sie lokalisieren möchten. Glossia listet nur Repositories auf, die über die Installation der GitHub-App des aktuellen Kontos verfügbar sind.

Fahren Sie mit dem Schritt zur Sprachauswahl fort.

## 4. Wählen Sie die Zielsprachen aus

Wählen Sie eine oder mehrere Sprachen aus, die aus dem Quellinhalt des Repositories generiert werden sollen, und starten Sie die Einrichtung.

## 5. Verfolgen Sie den Einrichtungsfortschritt

Lassen Sie die Einrichtungsseite geöffnet, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und die letzten Aktivitäten an, einschließlich Repository-Vorbereitung, Dateiüberprüfung, Änderungen, Prüfungen und Abschluss.

Sie können die Seite verlassen und zur Projektübersicht zurückkehren, ohne den Einrichtungsstatus zu verlieren. Falls die Einrichtung fehlschlägt, erklärt dieselbe Karte, worauf zu achten ist, und bietet die Option **Einrichtung wiederholen** an.

## 6. Überprüfen Sie das Ergebnis

Wenn die Einrichtung abgeschlossen ist, open die Projektübersicht und überprüfen Sie den für das Repository erstellten Pull Request. Die vorgeschlagene Baseline enthält im Normalfall Folgendes:

- Eine `GLOSSIA.md`-Datei im Stammverzeichnis mit Quellsprache, Quellpfaden und Zielsprachen.
- Die kleinstmöglichen Anwendungs- oder Inhaltsänderungen, die zum Laden lokalisierter Dateien erforderlich sind.
- Alle leichtgewichtigen Validierungen, die bereits im Repository verfügbar waren.

Überprüfen Sie den Pull Request und führen Sie ihn über Ihren normalen GitHub-Workflow zusammen. Zukünftige Übersetzungsläufe verwenden den zusammengeführten `GLOSSIA.md`-Kontext.

Die Projektübersicht hält den Einrichtungs-Pull-Request so lange sichtbar, bis er zusammengeführt wurde. Falls er geschlossen wird, ohne zusammengeführt worden zu sein, öffnen Sie ihn erneut über den Link im Einrichtungshinweis.

## Nächste Schritte

- [Eine neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Projekt-Einrichtungsstatus verstehen](/docs/reference/project-setup)
- [Die Funktionsweise von Konto-Modellen verstehen](/docs/explanation/account-models)
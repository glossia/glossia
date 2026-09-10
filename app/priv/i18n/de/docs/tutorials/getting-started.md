%{
  title: "Erste Schritte",
  summary:
    "Verbinden Sie ein Repository und richten Sie die erste Lokalisierungseinrichtung ein.",
  category: "Tutoriale",
  order: 1
}
---
Dieser Leitfaden verbindet ein GitHub-Repository mit Glossia, wählt dessen erste Zielsprachen aus und erstellt eine Lokalisierungs-Baseline zur Überprüfung für Ihr Team.

## Bevor Sie beginnen

Sie benötigen:

- Ein Glossia-Konto, in dem Sie Einstellungen und Projekte verwalten können.
- Ein GitHub-Repository, auf das Sie der Glossia GitHub App die Berechtigung einräumen können, zu lesen und zu aktualisieren.
- Ein Provider-Schlüssel für ein unterstütztes [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Ein Konto-Modell konfigurieren

Öffnen **Einstellungen**, dann **Modelle**, und auswählen **Neues Modell**.

1. Geben Sie dem Modell eine kurze Bezeichnung, wie z. B. `translation-default`.
2. Öffnen Sie den Modellauswahldialog und geben Sie einen Teil des Provider- oder Modellnamens ein, um die Liste zu filtern.
3. Wählen Sie das Modell aus, das Sie von Glossia verwenden möchten.
4. Geben Sie den Provider-Schlüssel ein und speichern Sie das Modell.

Die Bezeichnung ermöglicht es Repositories, sich auf dieses Kontomodell zu beziehen, ohne dass Anbieterzugangsdaten in der Versionskontrolle gespeichert werden. Siehe [Einen Modellanbieter konfigurieren](/docs/how-to/configure-a-model-provider) für weitere Details.

## 2\. Projekt starten

Zurück zu **Projekten** und wählen Sie **Neues Projekt**.

Wenn Glossia nach Zugriff auf das Repository fragt, folgen Sie dem Link zu GitHub und gewähren Sie der Glossia GitHub App Zugriff auf das Repository. Nach der Rückkehr zu Glossia erneut öffnen **Neues Projekt** falls notwendig.

## 3\. Ein Repository wählen

Wählen Sie das Repository aus, das Sie lokalisieren möchten. Glossia listet nur Repositories auf, die über die Installation der GitHub-App des aktuellen Kontos verfügbar sind.

Weiter zur Sprachauswahl.

## 4\. Zielsprachen auswählen

Wählen Sie eine oder mehrere Sprachen aus, die aus dem Quellinhalt des Repositories erstellt werden sollen, und starten Sie die Einrichtung.

## 5\. Einrichtungsfortschritt verfolgen

Halten Sie die Einrichtungsseite offen, während Glossia das Projekt vorbereitet. Die Fortschrittskarte zeigt den aktuellen Status und die jüngsten Aktivitäten, einschließlich Repository-Vorbereitung, Dateiinspektion, Änderungen, Prüfungen und Abschluss.

Sie können die Seite verlassen und zur Projektübersicht zurückkehren, ohne den Setup-Zustand zu verlieren. Wenn das Setup fehlschlägt, erklärt die gleiche Karte, was beachtet werden muss, und bietet **Setup erneut versuchen**.

## 6\. Ergebnis überprüfen

Wenn das Setup abgeschlossen ist, öffnen Sie die Projektübersicht und überprüfen Sie den Pull-Request, der für das Repository erstellt wurde. Die vorgeschlagene Baseline enthält normalerweise:

- Eine root- `L10N.md` Datei mit Quellsprache, Quellpfaden und Zielsprachen.
- Die kleinsten Anwendungs- oder Inhaltänderungen, die erforderlich sind, um lokalisierte Dateien zu laden.
- Jede leichtgewichtige Validierung, die bereits im Repository verfügbar war.

Überprüfen und zusammenführen Sie den Pull Request über Ihren normalen GitHub-Arbeitsablauf. Zukünftige Übersetzungsläufe verwenden die `L10N.md` Kontext.

Der Projektoverblick hält den Setup-Pull Request sichtbar, bis er zusammengeführt wurde. Wenn er ohne Zusammenführung geschlossen wird, öffnen Sie ihn erneut über den Link in der Setup-Benachrichtigung.

## Nächste Schritte

- [Neue Sprache hinzufügen](/docs/how-to/add-a-new-language)
- [Projekt-Setup-Zustände verstehen](/docs/reference/project-setup)
- [Erfahren Sie, wie Kontomodellen funktionieren](/docs/explanation/account-models)
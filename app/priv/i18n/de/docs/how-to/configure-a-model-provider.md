%{
  title: "Modellanbieter konfigurieren",
  summary: "Kontomodell hinzufügen und sicher aus Repositorien referenzieren.",
  category: "Anleitung",
  order: 3
}
---
Projekteinrichtung und Übersetzungsläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen **Einstellungen** und auswählen **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie eine eindeutige Kennung ein, wie zum Beispiel `translation-default`.
4. Öffnen Sie die Modell-Auswahl und geben Sie einen Teil des Anbieter- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell und geben Sie dessen Anbieter-Schlüssel ein.
6. Modell speichern.

Die Kennung bleibt stabil, auch wenn Sie später das dahinterliegende Anbietermodell ändern. Das erste dem Konto hinzugefügte Modell wird dessen Standardmodell.

## Referenziere das Modell aus einem Repository.

Stelle `model` in den relevanten `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Provider-Schlüssel bleibt in den Kontoeinstellungen.

## Wähle das Modell, das standardmäßig verwendet wird.

Wenn `L10N.md` wird weggelassen `model`, Glossia verwendet das Standardmodell des Kontos. Um es zu ändern, öffnen Sie das Modell, das Standard werden soll, und auswählen **Als Standard festlegen**.

Für vorhersehbares Verhalten über mehrere Modelle hinweg verweisen Sie explizit auf ein Handle in `L10N.md`.

Sie können ein anderes `model` Handle in einer verschachtelten `L10N.md` für einen Inhaltsbereich, oder in `L10N/<locale>.md` für eine Zielsprache. Glossia verwendet die passendste Einstellung für jedes Dokument und Zielsprache. Es teilt die Arbeit nicht automatisch unter konfigurierten Modellen auf.

Wenn ein expliziter Handle im Konto nicht existiert, wird die Übersetzung mit einem Fehler unterbrochen. Es wird nicht auf ein anderes Modell umgeschaltet.

## Ändern oder rotieren Sie einen Anbieterschlüssel

Öffnen **Einstellungen**, auswählen **Modelle**, und öffnen Sie den Modell-Handle. Geben Sie einen neuen Anbieterschlüssel ein und speichern Sie. Wenn Sie das Schlüsselfeld leer lassen, bleibt der aktuelle Schlüssel erhalten.

Repositories, die auf diesen Handle verweisen, müssen nicht geändert werden.
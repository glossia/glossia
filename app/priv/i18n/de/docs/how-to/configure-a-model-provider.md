%{
  title: "Modellanbieter konfigurieren",
  summary: "Fügen Sie ein Account-Modell hinzu und beziehen Sie es sicher aus Repositorien.",
  category: "Anleitung",
  order: 3
}
---
Projekteinrichtung und Übersetzungsabläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Ein Modell hinzufügen

1. Öffnen **Einstellungen** und wählen Sie **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie einen eindeutigen Handle ein, wie zum Beispiel `translation-default`.
4. Öffnen Sie die Modellauswahl und geben Sie einen Teil eines Anbieter- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell und geben Sie dessen Anbieter-Schlüssel ein.
6. Modell speichern.

Der Handle bleibt stabil, auch wenn Sie das dahinterstehende Anbieter-Modell später ändern. Das erste für ein Konto hinzugefügte Modell wird dessen Standardmodell.

## Verweisen Sie auf das Modell aus einem Repository

Festlegen `model` im relevanten `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository enthält nur das Handle. Der Provider-Schlüssel bleibt in den Kontoeinstellungen.

## Wählen Sie das Standardmodell aus

Wenn `L10N.md` überspringt `model`, Glossia verwendet das Standardmodell des Kontos. Um es zu ändern, öffnen Sie das Modell, das Standard werden soll, und wählen **Als Standard festlegen**.

Für vorhersehbares Verhalten über mehrere Modelle verweisen Sie explizit auf einen Handle in `L10N.md`.

Sie können einen anderen `model` Handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich, oder in `L10N/<locale>.md` Für eine Ziel-Lokalisierung. Glossia verwendet die passendste anwendbare Einstellung für jedes Dokument und jede Lokalisierung. Es teilt die Arbeit nicht automatisch unter konfigurierten Modellen auf.

Wenn kein explizites Handle im Konto existiert, endet die Übersetzung mit einem Fehler. Es greift nicht auf ein anderes Modell zurück.

## Anbieter-Schlüssel ändern oder rotieren

Öffnen **Einstellungen**, wählen **Modelle**, und öffnen Sie das Modell-Handle. Geben Sie einen neuen Anbieter-Schlüssel ein und speichern Sie. Wenn Sie das Schlüsselfeld leer lassen, bleibt der aktuelle Schlüssel erhalten.

Repositorien, die den Handle referenzieren, müssen nicht geändert werden.
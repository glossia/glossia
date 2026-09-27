%{
  title: "Model-Provider konfigurieren",
  summary: "Accountmodell hinzufügen und sicher aus Repositorien referenzieren.",
  category: "Anleitung",
  section: "Übersetzung",
  order: 3
}
---
Projekteinrichtung und Übersetzungsläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen **Einstellungen** und wählen Sie aus **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie einen eindeutigen Handle ein, z. B. `translation-default`.
4. Öffnen Sie die Modellwahl und geben Sie einen Teil des Namens eines Providers oder Modells ein, um die Liste zu filtern.
5. Wählen Sie ein Modell aus und geben Sie dessen Provider-Schlüssel ein.
6. Speichern Sie das Modell.

Der Handle bleibt stabil, auch wenn Sie das dahinterliegende Provider-Modell später ändern. Das zuerst zum Konto hinzugefügte Modell wird dessen Standard.

## Beziehe das Modell aus einem Repository

Setze `model` in dem relevanten `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Provider-Key bleibt in den Kontoeinstellungen.

## Wählen Sie, welches Modell standardmäßig verwendet wird

Wenn `L10N.md` übersieht `model`, Glossia verwendet das Standardmodell des Kontos. Um es zu ändern, öffnen Sie das Modell, das als Standardmodell werden soll, und wählen **Als Standard festlegen**.

Für vorhersehbares Verhalten über mehrere Modelle hinweg verweisen Sie explizit auf einen Handle in `L10N.md`.

Sie können einen anderen `model` Handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich oder in `L10N/<locale>.md` für ein Zielsprachgebiet. Glossia wendet für jedes Dokument und Sprachgebiet die passendste Einstellung an. Es teilt die Arbeit nicht automatisch auf die konfigurierten Modelle auf.

Falls in dem Konto kein expliziter Handle existiert, stoppt die Übersetzung mit einem Fehler. Es wird nicht auf ein anderes Modell zurückgefallen.

## Provider-Schlüssel ändern oder rotieren

Öffnen **Einstellungen**, auswählen **Modelle**, und öffnen Sie den Model-Handle. Geben Sie einen neuen Provider-Schlüssel ein und speichern. Wird das Schlüsselfeld leer belassen, bleibt der aktuelle Schlüssel erhalten.

Repositorien, die auf den Handle verweisen, müssen nicht geändert werden.
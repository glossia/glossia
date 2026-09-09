%{
  title: "Konfigurieren Sie einen Modellanbieter",
  summary: "Fügen Sie ein Konto-Modell hinzu und referenzieren Sie es sicher aus Repositorien.",
  category: "Anleitung",
  order: 3
}
---
Die Projekt-Einrichtung und Übersetzungsläufe verwenden Modelle, die für Ihr aktuelles Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen **Einstellungen** und auswählen **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie eine eindeutige Kennung ein, wie zum Beispiel `translation-default`.
4. Öffnen Sie den Modellselektor und geben Sie einen Teil des Anbieter- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell und geben Sie dessen Anbieter-Schlüssel ein.
6. Speichern Sie das Modell.

Die Kennung bleibt auch stabil, wenn Sie später das dahinterliegende Anbieter-Modell ändern. Das zuerst einem Konto hinzugefügte Modell wird zum Standard.

## Verweisen Sie auf das Modell aus einem Repository

Festlegen `model` in den relevanten `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Provider-Schlüssel bleibt in den Kontoeinstellungen.

## Wählen Sie, welches Modell standardmäßig verwendet wird

Wenn `L10N.md` übersieht `model`, Glossia verwendet das Standardmodell des Kontos. Um es zu ändern, öffnen Sie das Modell, das Standard werden soll, und wählen Sie **Als Standard festlegen**.

Für ein vorhersehbares Verhalten über mehrere Modelle verweisen Sie explizit auf ein handle in `L10N.md`.

Sie können ein anderes `model` handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich, oder in `L10N/<locale>.md` für eine Zielsprache. Glossia verwendet für jedes Dokument und jede Zielsprache die am besten passende Einstellung. Es teilt die Arbeit unter konfigurierte Modelle nicht automatisch auf.

Wenn kein explizites Handle im Konto existiert, wird die Übersetzung mit einem Fehler abgebrochen. Es wird nicht auf ein anderes Modell zurückgegriffen.

## Provider-Schlüssel ändern oder rotieren

Öffnen **Einstellungen**, auswählen **Modelle**, und öffnen Sie den Modell-Handle. Geben Sie einen neuen Provider-Schlüssel ein und speichern. Das Leerlassen des Schlüsselfelds behält den aktuellen Schlüssel.

Repositorien, die auf den Handle verweisen, müssen nicht geändert werden.
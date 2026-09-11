%{
  title: "Modellanbieter konfigurieren",
  summary: "Ein Account-Modell hinzufügen und es sicher aus Repositorien referenzieren.",
  category: "Anleitung",
  order: 3
}
---
Projektsetup und Übersetzungsabläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind.

## Modell hinzufügen

1. Öffnen **Einstellungen** und wählen **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie eine eindeutige Kennung ein, wie zum Beispiel `translation-default`.
4. Öffnen Sie das Modell-Auswahlmenü und geben Sie einen Teil eines Anbieter- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell aus und geben Sie dessen Anbieter-Schlüssel ein.
6. Speichern Sie das Modell.

Die Kennung bleibt stabil, selbst wenn Sie später das dahinterliegende Anbieter-Modell ändern. Das erste Modell, das einem Konto hinzugefügt wird, wird dessen Standardmodell.

## Verweisen Sie auf das Modell aus einem Repository

Festlegen `model` in der relevanten `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Provider-Schlüssel bleibt in den Kontoeinstellungen erhalten.

## Wählen Sie, welches Modell standardmäßig verwendet wird

Wenn `L10N.md` auslässt `model`, Glossia nutzt das Standardmodell des Kontos. Um dies zu ändern, öffnen Sie das Modell, das Standard werden soll, und wählen **Als Standard festlegen**.

Für vorhersehbares Verhalten mit mehreren Modellen verweisen Sie explizit auf ein Handle in `L10N.md`.

Sie können ein anderes `model` Handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich oder in `L10N/<locale>.md` für eine Zielsprache. Glossia verwendet die passendste verfügbare Einstellung für jedes Dokument und jede Zielsprache. Es teilt die Arbeit nicht automatisch unter den konfigurierten Modellen auf.

Wenn ein expliziter Handle im Konto nicht vorhanden ist, wird die Übersetzung mit einem Fehler gestoppt. Es wird nicht auf ein anderes Modell zurückgegriffen.

## Anbieterschlüssel ändern oder rotieren

Öffnen **Einstellungen**, auswählen **Modelle**, und öffnen Sie das Modell-Handle. Geben Sie einen neuen Anbieterschlüssel ein und speichern Sie. Lassen Sie das Schlüsselfeld leer, um den aktuellen Schlüssel beizubehalten.

Repositorien, die sich auf diesen Handle beziehen, müssen nicht geändert werden.
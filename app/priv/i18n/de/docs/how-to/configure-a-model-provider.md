%{
  title: "Konfigurieren Sie einen Modellanbieter",
  summary: "Fügen Sie ein Account-Modell hinzu und beziehen Sie es sicher aus Repositorien.",
  category: "Tutorials",
  order: 3
}
---
Projekt-Einrichtung und Übersetzungsabläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen **Einstellungen** und wählen Sie **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie eine eindeutige Kennung ein, wie `translation-default`.
4. Öffnen Sie den Modell-Selector und geben Sie einen Teil des Provider- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell aus und geben Sie seinen Provider-Schlüssel ein.
6. Speichern Sie das Modell.

Die Kennung bleibt stabil, auch wenn Sie das dahinterliegende Provider-Modell später ändern. Das zuerst einem Konto hinzugefügte Modell wird dessen Standardmodell.

## Referenzieren Sie das Modell aus einem Repository

Legen Sie `model` in den relevanten `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Provider-Schlüssel bleibt in den Kontoeinstellungen.

## Wählen Sie das Standardmodell aus

Wenn `L10N.md` überspringt `model`Glossia verwendet das Standardmodell des Kontos. Um es zu ändern, öffnen Sie das Modell, das standardmäßig werden soll, und wählen Sie **Als Standard festlegen**.

Für ein vorhersehbares Verhalten über mehrere Modelle hinweg verweisen Sie auf ein Handle explizit in `L10N.md`.

Sie können einen anderen `model` Handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich oder in `L10N/<locale>.md` Für eine Ziel-Lokale verwendet. Glossia verwendet die passendste Einstellung für jedes Dokument und jede Lokale. Es teilt die Arbeit nicht automatisch zwischen den konfigurierten Modellen auf.

Wenn kein explizites Handle im Konto existiert, stoppt die Übersetzung mit einem Fehler. Es wird nicht auf ein anderes Modell zurückgegriffen.

## Provider-Schlüssel ändern oder rotieren

Öffnen **Einstellungen**, auswählen **Modelle**, und öffnen Sie das Modell-Handle. Geben Sie einen neuen Provider-Schlüssel ein und speichern. Lassen Sie das Schlüsselfeld leer, um den aktuellen Schlüssel beizubehalten.

Repositorien, die auf den Handle verweisen, müssen nicht geändert werden.
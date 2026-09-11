%{
  title: "Modellanbieter konfigurieren",
  summary: "Kontomodell hinzufügen und es sicher aus Repositories verweisen",
  category: "Anleitung",
  order: 3
}
---
Die Projekteinrichtung und Übersetzungsabläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen **Einstellungen** und wählen **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie einen eindeutigen Handle ein, z. B. `translation-default`.
4. Öffnen Sie den Modell-Auswähler und geben Sie einen Teil des Anbieters- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell und geben Sie dessen Anbieter-Schlüssel ein.
6. Modell speichern.

Der Handle bleibt auch bei einer späteren Änderung des dahinterliegenden Anbieter-Modells stabil. Das zuerst einem Konto hinzugefügte Modell wird dessen Standardmodell.

## Referenzieren Sie das Modell aus einem Repository

Festlegen `model` in der jeweiligen `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Provider-Schlüssel verbleibt in den Kontoeinstellungen.

## Wählen Sie das Modell, das standardmäßig verwendet wird.

Wenn `L10N.md` unterlässt `model`, Glossia verwendet das Standardmodell des Kontos. Um dies zu ändern, öffnen Sie das Modell, das als Standard dienen soll, und wählen Sie **Als Standard festlegen**.

Für vorhersagbares Verhalten über mehrere Modelle, verweise explizit auf einen Handle in `L10N.md`.

Sie können einen anderen `model` Handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich oder in `L10N/<locale>.md` für eine Ziel-Lokalisierung. Glossia verwendet das passende, anwendbare Setting für jedes Dokument und jede Lokalisierung. Es teilt die Arbeit nicht automatisch zwischen den konfigurierten Modellen auf.

Wenn kein explizites Handle im Konto existiert, bricht die Übersetzung mit einem Fehler ab. Es greift nicht auf ein anderes Modell zurück.

## Provider-Schlüssel ändern oder erneuern

Öffnen **Einstellungen**, auswählen **Modelle**, und öffnen Sie das Modell-Handle. Geben Sie einen neuen Provider-Schlüssel ein und speichern Sie. Lassen Sie das Schlüsselfeld leer, um den aktuellen Schlüssel beizubehalten.

Repositorien, die auf den Handle verweisen, müssen nicht geändert werden.
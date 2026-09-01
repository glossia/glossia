%{
  title: "Modellanbieter konfigurieren",
  summary: "Fügen Sie ein Kontomodell hinzu und beziehen Sie es sicher aus Repositories.",
  category: "Anleitung",
  order: 3
}
---
Para die Projekteinrichtung und Translationen werden Modelle verwendet, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Ein Modell hinzufügen

1. Öffnen Sie **Einstellungen** und wählen Sie **Modelle**.
2. Wählen Sie **Neues Modell**.
3. Geben Sie einen eindeutigen Handle ein, beispielsweise `translation-default`.
4. Öffnen Sie die Modellauswahl und geben Sie einen Teil des Anbieters- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell und geben Sie dessen Anbieter-Schlüssel ein.
6. Speichern Sie das Modell.

Der Handle bleibt stabil, auch wenn Sie später das dahinterliegende Anbieter-Modell ändern. Das erste hinzugefügte Modell auf einem Konto wird dessen Standardmodell.

## Verweisen Sie auf das Modell aus einem Repository

Setzen Sie `model` im relevanten `GLOSSIA.md` Frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Anbieter-Schlüssel verbleibt in den Kontoeinstellungen.

## Wählen Sie aus, welches Modell standardmäßig verwendet wird

Wenn `GLOSSIA.md` den Wert für `model` weglässt, verwendet Glossia das Standardmodell des Kontos. Um dies zu ändern, öffnen Sie das Modell, das als Standard werden soll, und wählen Sie **Als Standard festlegen**.

Für vorhersehbares Verhalten über mehrere Modelle hinweg verweisen Sie auf einen Handle explizit in `GLOSSIA.md`.

Sie können einen anderen `model`-Handle in einem verschachtelten `GLOSSIA.md` für einen Inhaltsbereich oder in `GLOSSIA/<locale>.md` für eine Zielsprache platzieren. Glossia verwendet für jedes Dokument und jedes Zielsprachen die nächstgelegene zutreffende Einstellung. Es teilt die Arbeit nicht automatisch zwischen den konfigurierten Modellen auf.

Wenn ein expliziter Handle im Konto nicht existiert, wird der Übersetzungsvorgang bei einem Fehler abgebrochen. Es greift nicht auf ein anderes Modell zurück.

## Ändern oder erneuern Sie einen Anbieter-Schlüssel

Öffnen Sie **Einstellungen**, wählen Sie **Modelle**, und öffnen Sie den Modell-Handle. Geben Sie einen neuen Anbieter-Schlüssel ein und speichern Sie. Ein leerer Schlüssel behält den aktuellen Schlüssel.

Repositorien, die auf den Handle verweisen, müssen sich nicht ändern.
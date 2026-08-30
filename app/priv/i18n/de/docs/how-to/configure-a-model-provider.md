%{
  title: "Ein Modellanbieter konfigurieren",
  summary: "Fügen Sie ein Konto-Modell hinzu und verweisen Sie es sicher aus Repositories.",
  category: "Anleitung",
  order: 3
}
---
Projekteinrichtung und Übersetzungsabläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie vor der Erstellung eines Projekts mindestens ein Modell.

## Ein Modell hinzufügen

1. Öffnen Sie **Einstellungen** und wählen Sie **Modelle**.
2. Wählen Sie **Neues Modell**.
3. Geben Sie einen eindeutigen Bezeichner ein, z. B. `translation-default`.
4. Öffnen Sie den Modellauswahl-Dialog und tippen Sie einen Teil eines Anbieter- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell aus und geben Sie dessen Anbieterschlüssel ein.
6. Speichern Sie das Modell.

Der Bezeichner bleibt stabil, auch wenn Sie später das dahinterliegende Anbietermodell ändern. Das zuerst einem Konto hinzugefügte Modell wird dessen Standardmodell.

## Verweisen Sie auf das Modell aus einem Repository

Setzen Sie `model` in das relevante `GLOSSIA.md` Frontmatter ein:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Bezeichner. Der Anbieterschlüssel verbleibt in den Konto-Einstellungen.

## Wählen Sie aus, welches Modell standardmäßig verwendet wird

Wenn `GLOSSIA.md` `model` weglässt, verwendet Glossia das Standardmodell des Kontos. Um dies zu ändern, öffnen Sie das Modell, das Standard werden soll, und wählen Sie **Als Standard festlegen**.

Für ein vorhersehbares Verhalten über mehrere Modelle hinweg verweisen Sie explizit auf einen Bezeichner in `GLOSSIA.md`.

Sie können einen anderen `model`-Bezeichner in einer verschachtelten `GLOSSIA.md` für einen bestimmten Inhaltsbereich oder in `GLOSSIA/<locale>.md` für eine Ziel-Lokalisierung platzieren. Glossia verwendet die zutreffendste Einstellung für jedes Dokument und jede Lokalisierung. Es verteilt die Arbeit nicht automatisch auf die konfigurierten Modelle.

Wenn ein expliziter Bezeichner im Konto nicht existiert, endet die Übersetzung mit einem Fehler. Es wird nicht auf ein anderes Modell zurückgewiesen.

## Ändern oder wechseln Sie einen Anbieterschlüssel

Öffnen Sie **Einstellungen**, wählen Sie **Modelle** aus und öffnen Sie den Modellbezeichner. Geben Sie einen neuen Anbieterschlüssel ein und speichern Sie. Lassen Sie das Schlüsselfeld leer, um den aktuellen Schlüssel zu behalten.

Repositorien, die sich auf den Bezeichner beziehen, müssen sich nicht ändern.
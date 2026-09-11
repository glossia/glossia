%{
  title: "Konfigurieren Sie einen Modell-Provider",
  summary: "Fügen Sie ein Kontomodell hinzu und verweisen Sie es sicher aus Repositories.",
  category: "Anleitung",
  order: 3
}
---
Projekteinrichtung und Übersetzungsabläufe verwenden Modelle, die für Ihr aktuelles Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen **Einstellungen** und auswählen **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie eine eindeutige Kennung ein, z. B. `translation-default`.
4. Öffnen Sie die Modell-Auswahl und geben Sie einen Teil des Anbieter- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell und geben Sie dessen Anbieter-Schlüssel ein.
6. Modell speichern.

Die Kennung bleibt stabil, auch wenn Sie das dahinterliegende Anbietermodell später ändern. Das erste hinzugefügte Modell eines Kontos wird dessen Standardmodell.

## Beziehen Sie das Modell aus einem Repository

Festlegen `model` in der relevanten `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository enthält nur den Handle. Der Provider-Schlüssel bleibt in den Kontoeinstellungen.

## Wählen Sie, welches Modell standardmäßig verwendet wird

Wenn `L10N.md` überspringt `model`, Glossia verwendet das Standardmodell des Kontos. Um es zu ändern, öffnen Sie das Modell, das zum Standard werden soll und wählen **Als Standard festlegen**.

,Für vorhersehbares Verhalten in mehreren Modellen verweisen Sie explizit auf einen handle in `L10N.md`.

Sie können einen anderen `model` handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich, oder in `L10N/<locale>.md` für eine Ziel-Lokalisierung. Glossia nutzt für jedes Dokument und jede Ziel-Lokalisierung die passendste Einstellung. Es verteilt die Arbeit nicht automatisch zwischen den konfigurierten Modellen.

Wenn ein expliziter Handle im Konto nicht existiert, endet die Übersetzung mit einem Fehler. Es findet kein Rückgriff auf ein anderes Modell statt.

## Anbieter-Schlüssel ändern oder rotieren

Öffnen **Einstellungen**, auswählen **Modelle**, und öffnen Sie den Modell-Handle. Geben Sie einen neuen Anbieter-Schlüssel ein und speichern. Wenn das Schlüsselfeld leer bleibt, bleibt der aktuelle Schlüssel erhalten.

Repositorien, die auf den Handle verweisen, brauchen keine Änderung.
%{
  title: "Modellanbieter konfigurieren",
  summary: "Fügen Sie ein Kontomodell hinzu und verweisen Sie aus Repositories sicher darauf.",
  category: "how-to",
  order: 3
}
---
Die Projekteinrichtung und Übersetzungsläufe verwenden Modelle, die für das aktuelle Glossia-Konto konfiguriert sind. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Ein Modell hinzufügen

1. Öffnen Sie die **Einstellungen** und wählen Sie **Modelle** aus.
2. Wählen Sie **Neues Modell** aus.
3. Geben Sie ein eindeutiges Handle ein, wie z. B. `translation-default`.
4. Öffnen Sie die Modellauswahl und geben Sie einen Teil des Anbieternamens oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell aus und geben Sie den zugehörigen Anbieterschlüssel ein.
6. Speichern Sie das Modell.

Das Handle bleibt stabil, selbst wenn Sie das dahinterliegende Anbietermodell später ändern. Das erste zu einem Konto hinzugefügte Modell wird als Standardmodell festgelegt.

## Referenzieren des Modells aus einem Repository

Legen Sie `model` im relevanten `GLOSSIA.md`-Frontmatter fest:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur das Handle. Der Anbieterschlüssel verbleibt in den Kontoeinstellungen.

## Auswählen, welches Modell standardmäßig verwendet wird

Wenn `GLOSSIA.md` `model` auslässt, verwendet Glossia das Standardmodell des Kontos. Um dies zu ändern, öffnen Sie das Modell, das zum Standard werden soll, und wählen Sie **Als Standard festlegen** aus.

Für ein vorhersagbares Verhalten über mehrere Modelle hinweg referenzieren Sie ein Handle explizit in `GLOSSIA.md`.

Sie können ein anderes `model`-Handle in einer verschachtelten `GLOSSIA.md` für einen bestimmten Inhaltsbereich oder in `GLOSSIA/<locale>.md` für ein bestimmtes Ziel-Locale hinterlegen. Glossia verwendet die am nächsten liegende anwendbare Einstellung für jedes Dokument und jedes Locale. Eine automatische Aufteilung der Arbeit auf die konfigurierten Modelle erfolgt nicht.

Wenn ein explizites Handle im Konto nicht existiert, bricht die Übersetzung mit einem Fehler ab. Es erfolgt kein Rückfall auf ein anderes Modell.

## Ändern oder Rotieren eines Anbieterschlüssels

Öffnen Sie die **Einstellungen**, wählen Sie **Modelle** aus und öffnen Sie das Modell-Handle. Geben Sie einen neuen Anbieterschlüssel ein und speichern Sie diesen. Wenn Sie das Feld für den Schlüssel leer lassen, wird der aktuelle Schlüssel beibehalten.

Repositories, die das Handle referenzieren, müssen nicht geändert werden.
%{
  title: "Modellanbieter konfigurieren",
  summary: "Account-Modell hinzufügen und darauf sicher aus Repositorien verweisen.",
  category: "Anleitung",
  order: 3
}
---
Projektsetup und Übersetzungsläufe verwenden für das aktuelle Glossia-Konto konfigurierte Modelle. Konfigurieren Sie mindestens ein Modell, bevor Sie ein Projekt erstellen.

## Modell hinzufügen

1. Öffnen **Einstellungen** und auswählen **Modelle**.
2. Auswählen **Neues Modell**.
3. Geben Sie einen eindeutigen Handle ein, wie `translation-default`.
4. Öffnen Sie den Modellpicker und geben Sie einen Teil eines Anbieter- oder Modellnamens ein, um die Liste zu filtern.
5. Wählen Sie ein Modell und geben Sie dessen Anbieter-Schlüssel ein.
6. Modell speichern.

Der Handle bleibt stabil, auch wenn Sie das dahinterliegende Anbietermodell später ändern. Das erste einem Konto hinzugefügte Modell wird dessen Standardmodell.

## Referenzieren Sie das Modell aus einem Repository

Festlegen `model` in der relevanten `L10N.md` frontmatter:

```yaml
---
model: translation-default
---
```

Das Repository speichert nur den Handle. Der Provider-Schlüssel bleibt in den Konto-Einstellungen.

## Wählen Sie aus, welches Modell standardmäßig verwendet wird

Wann `L10N.md` unterlässt `model`, Glossia verwendet das Standardmodell des Kontos. Um dies zu ändern, öffnen Sie das Modell, das als Standard festgelegt werden soll, und wählen **Als Standard festlegen**.

Für vorhersehbares Verhalten bei mehreren Modellen verweisen Sie explizit in `L10N.md`.

Sie können einen anderen `model` Handle in einem verschachtelten `L10N.md` für einen Inhaltsbereich oder in `L10N/<locale>.md` für eine Zielsprache. Glossia verwendet die passendste Einstellung für jedes Dokument und jede Zielsprache. Es teilt die Arbeit nicht automatisch zwischen konfigurierten Modellen auf.

Wenn kein expliziter Handle im Konto existiert, bricht die Übersetzung mit einem Fehler ab. Es wird nicht auf ein anderes Modell zurückgegriffen.

## Anbieterschlüssel ändern oder rotieren

Öffnen **Einstellungen**, auswählen **Modelle**, und öffnen Sie den Modell-Handle. Geben Sie einen neuen Anbieterschlüssel ein und speichern. Lassen Sie das Schlüsselfeld leer, um den aktuellen Schlüssel beizubehalten.

Repositorien, die auf den Handle verweisen, müssen nicht geändert werden.
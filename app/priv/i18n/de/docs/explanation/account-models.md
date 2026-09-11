%{
  title: "Konto-Modelle",
  summary:
    "Warum Modellanbieter einmal pro Konto konfiguriert werden und durch ein Handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt Repository-Anweisungen von Modell-Anbieter-Zugangsdaten. Repositories beschreiben, was übersetzt werden soll, während Konten bestimmen, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit verrichtet.

## Warum Modelle Konten zugeordnet sind

Ein Team übersetzt oft mehrere Repositories mit derselben Anbieterbeziehung. Kontenbezogene Modelle ermöglichen es Administratoren, einen Anbieter-Schlüssel zu rotieren oder das zugrundeliegende Modell einmal umzuschalten, ohne jedes Repository zu bearbeiten.

Diese Grenze hält auch Zugangsdaten aus der Versionskontrolle heraus. Ein Repository enthält einen lesbaren Bezeichner wie z. B. `translation-default`, sondern nicht den Anbieter-Schlüssel.

## Bezeichner liefern eine stabile Intention.

Das `model` Feld in `L10N.md` bezieht sich auf einen Accountmodell-Handle:

```yaml
model: translation-default
```

Der Handle drückt die Intention des Repositorys aus. Ein Administrator kann später ändern, welches Anbietermodell der Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokumentübersetzung ein konfiguriertes Modell. Das Hinzufügen mehrerer Modelle erzeugt kein Ensemble, keine Fallback-Kette oder eine automatische Qualitätsstufe. Der Repository-Autor wählt seinen Zweck durch stabile Handles wie `translation-default`, `long-form`, oder `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und die Zielsprache:

1. Die nächste `L10N/<locale>.md` Datei, die definiert `model` hat für diese Zielsprache Vorrang.
2. Ansonsten die nächste `L10N.md` Datei, die definiert `model` hat für das Verzeichnis Vorrang.
3. Eltern `L10N.md` Einstellungen werden vererbt, wenn eine Datei in einem näheren Verzeichnis kein Modell definiert.
4. Wenn keine anwendbare Kontextdatei einen Handle definiert, verwendet Glossia die Kontovorlage.

Ein explizit konfigurierter Handle muss vorhanden sein. Glossia meldet einen Fehler für einen unbekannten Handle anstatt stillschweigend zur Kontovorlage zu wechseln.

## Standardauswahl

Die Projekt-Einrichtung benötigt ein Modell, bevor ein Repository ein eigenes hat `L10N.md`. Glossia wählt daher die Kontovorlage aus. Das erste hinzugefügte Modell eines Kontos wird zum Standard, und ein Administrator kann ein anderes Modell auf dessen Einstellungsseite als Standard festlegen.

Sobald ein Repository hat `L10N.md`Durch eine explizite Handle ist die Entscheidung für Prüfer klar. Durch Weglassen `model` bleibt das Repository auf der Standardeinstellung des Kontos.

## Die Grenze menschlicher Prüfung

Die Modell-Ausgabe ist vorgeschlagene Arbeit, keine automatische Zusammenführung. Die Setup- und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull Request veröffentlicht werden, damit das Team sie prüfen kann. Dies bewahrt die gleiche Qualitäts- und Verantwortungsabgrenzung, die Teams bereits für Code verwenden.
%{
  title: "Account-Modelle",
  summary:
    "Warum Modellanbieter einmal pro Konto konfiguriert werden und über Handle referenziert werden.",
  category: "Erklärung",
  section: "Plattform",
  order: 2
}
---
Glossia trennt Repositoryanweisungen von den Credentials des Modelldienstleisters. Repositories beschreiben, was übersetzt werden soll, während Konten entscheiden, [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle Konten gehören

Ein Team übersetzt oft mehrere Repositories mit derselben Provider-Beziehung. Konto-spezifische Modelle ermöglichen es Administratoren, einen Provider-Schlüssel zu rotieren oder das zugrunde liegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Grenze hält auch Credentials aus der Versionsverwaltung fern. Ein Repository enthält eine lesbare Handle wie `translation-default`sonder nicht den Provider-Schlüssel.

## Handles bieten stabile Intents.

Das `model` Feld in `L10N.md` bezieht sich auf einen Account-Modell-Handle:

```yaml
model: translation-default
```

Der Handle repräsentiert die Absicht des Repositories. Ein Administrator kann später aktualisieren, welches Provider-Modell dieser Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokumentübersetzung genau ein konfiguriertes Modell. Das Hinzufügen mehrerer Modelle erzeugt kein Ensemble, keine Fallback-Kette oder keine automatische Qualitätsebene. Der Repository-Autor wählt seinen Zweck durch stabile Handles aus wie `translation-default`, `long-form`oder `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und die Ziel-Lokalisierung:

1. Die nächstgelegene `L10N/<locale>.md` Datei, die definiert `model` hat Vorrang für diese Lokalisierung.
2. Ansonsten, die nächstgelegene `L10N.md` Datei, die definiert `model` hat Vorrang für dessen Verzeichnis.
3. Eltern `L10N.md` Einstellungen werden vererbt, wenn eine näherliegende Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei einen Handle deklariert, verwendet Glossia den Standardwert des Kontos.

Ein explizit konfigurierter Handle muss vorhanden sein. Glossia meldet einen Fehler für einen unbekannten Handle, statt stillschweigend auf den Standardwert des Kontos umzuschalten.

## Standardauswahl

Das Projektsetup benötigt ein Modell, bevor ein Repository sein eigenes hat `L10N.md`. Glossia wählt daher den Standardwert des Kontos. Das erste Modell, das einem Konto hinzugefügt wird, wird Standard, und ein Administrator kann ein anderes Modell als Standard auf dessen Einstellungsseite festlegen.

Sobald ein Repository hat `L10N.md`, die Verwendung eines expliziten Handles macht seine Wahl für die Rezensenten klar. Das Weglassen `model` behält das Repository auf dem Konto-Standard.

## Die Grenze der menschlichen Überprüfung

Die Modellausgabe ist vorgeschlagene Arbeit, kein automatischer Merge. Setup- und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull-Request zur Überprüfung durch das Team veröffentlicht werden. Dies bewahrt die gleiche Qualitäts- und Verantwortungsgrenze, die Teams bereits für Code nutzen.
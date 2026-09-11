%{
  title: "Konto-Modelle",
  summary:
    "Warum Modellanbieter einmalig pro Konto konfiguriert und per handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt Repository-Anweisungen von Modellanbieter-Zugangsdaten. Repositorien beschreiben, was übersetzt werden soll, während Konten entscheiden, welche [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle Konten zugeordnet sind

Ein Team übersetzt oft mehrere Repositorien mit der gleichen Anbieterbeziehung. Kontenbezogene Modelle ermöglichen Administratoren, einen Anbieterschlüssel zu rotieren oder das zugrundeliegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Trennung hält Zugangsdaten ebenfalls außerhalb der Versionskontrolle. Ein Repository enthält einen lesbaren Bezeichner wie z. B. `translation-default`", nicht der Anbieterschlüssel.

## Bezeichner bieten stabile Absicht.

Das `model` Feld in `L10N.md` bezieht sich auf einen Account-Handle:

```yaml
model: translation-default
```

Der Handle drückt die Absicht des Repositories aus. Ein Administrator kann später ändern, welches Provider-Modell dieser Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokumentenübersetzung ein konfiguriertes Modell. Das Hinzufügen mehrerer Modelle erstellt kein Ensemble, keine Fallback-Kette oder eine automatische Qualitätsebene. Der Repository-Autor wählt sein Ziel durch stabile Handles wie `translation-default`, `long-form`Or `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und das Ziel-Lokal:

1. Die nächstgelegene `L10N/<locale>.md` Datei, die deklariert `model` gewinnt für dieses Ziel-Lokal.
2. Andernfalls die nächstgelegene `L10N.md` Datei, die deklariert `model` gewinnt für ihr Verzeichnis.
3. Eltern `L10N.md` Einstellungen werden vererbt, wenn keine nähergelegte Datei ein Modell festlegt.
4. Wenn keine anwendbare Kontextdatei einen Handle festlegt, verwendet Glossia die Standardeinstellung des Kontos.

Ein explizit konfigurierter Handle muss existieren. Glossia meldet bei einem unbekannten Handle einen Fehler statt stillschweigend auf die Standardeinstellung des Kontos umzuschalten.

## Standardauswahl

Projektsetup benötigt ein Modell, bevor ein Repository ein eigenes `L10N.md`. Glossia wählt daher die Standardeinstellung des Kontos. Das erste hinzugefügte Modell eines Kontos wird zum Standard, und ein Administrator kann ein anderes Modell über dessen Einstellungsseite zum Standard setzen.

Sobald ein Repository hat `L10N.md`, durch die explizite Referenz wird die Entscheidung für Prüfer deutlich. Das Auslassen `model` bleibt das Repository im Standard des Kontos.

## Die Grenze der menschlichen Überprüfung

Die Modellausgabe ist vorgeschlagene Arbeit, keine automatische Merge. Setup- und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull Request zur Prüfung veröffentlicht werden. Dies bewahrt die gleiche Qualitäts- und Verantwortungsgrenze, die Teams bereits für Code nutzen.
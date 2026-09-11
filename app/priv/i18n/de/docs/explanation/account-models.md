%{
  title: "Konto-Modelle",
  summary:
    "Warum Modellanbieter einmal pro Konto konfiguriert und per Handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt Repository-Anweisungen von Modell-Anbieter-Credentials. Repositories beschreiben, was übersetzt werden soll, während Konten entscheiden, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle den Konten angehören

Ein Team übersetzt häufig mehrere Repositories mit derselben Anbieter-Beziehung. Kontospezifische Modelle ermöglichen es Administratoren, einen Anbieter-Schlüssel zu rotieren oder das darunterliegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Trennung hält zudem Credentials aus der Versionskontrolle. Ein Repository enthält eine lesbare Handle wie `translation-default`, nicht der Anbieter-Schlüssel.

## Handles bieten eine stabile Intention.

Das `model` Feld in `L10N.md` bezieht sich auf einen Accountmodell-Handle:

```yaml
model: translation-default
```

Der Handle drückt die Absicht des Repositories aus. Ein Administrator kann später festlegen, welches Provider-Modell dieser Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokumentübersetzung ein konfiguriertes Modell. Das Hinzufügen mehrerer Modelle erstellt weder ein Ensemble, eine Fallback-Kette noch eine automatische Qualitätsstufe. Der Repository-Autor wählt seinen Zweck über stabile Handles wie `translation-default`Das zusammengeführte Dokument hat zuvor die Validierung nicht bestanden: Die Markdown-Text-Literal-Wiederherstellung muss ein JSON-String-Array der gleichen Länge zurückgeben. `long-form`, oder `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und die Zielsprache:

1. Das nächstgelegene `L10N/<locale>.md` Datei, die definiert `model` gewinnt für diese Zielsprache.
2. Andernfalls das nächstgelegene `L10N.md` Datei, die definiert `model` gewinnt für ihr Verzeichnis.
3. Elterndatei `L10N.md` Einstellungen werden vererbt, wenn eine nähere Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei einen Handle deklariert, verwendet Glossia den Kontostandard.

Ein explizit konfigurierter Handle muss existieren. Glossia meldet einen Fehler für einen unbekannten Handle, anstatt stillschweigend auf den Kontostandard zu wechseln.

## Standardauswahl

Das Projektsetup benötigt ein Modell, bevor ein Repository sein eigenes hat. `L10N.md`Glossia wählt daher den Kontostandard aus. Das erste zu einem Konto hinzugefügte Modell wird zum Standard, und ein Administrator kann ein anderes Modell als Standard von dessen Einstellungsseite festlegen.

Sobald ein Repository `L10N.md`, über explizite Handle wird die Wahl für Reviewer deutlich. Auslassen `model` hält das Repository beim Konto-Standard.

## Die menschliche Prüfgrenze

Die Modellausgabe ist vorgeschlagene Arbeit, keine automatische Zusammenführung. Setup- und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull-Request zur Überprüfung durch das Team veröffentlicht werden. Dies bewahrt dieselbe Qualitäts- und Verantwortungsgrenze, die Teams bereits für Code nutzen.
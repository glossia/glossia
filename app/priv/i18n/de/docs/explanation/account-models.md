%{
  title: "Account-Modelle",
  summary:
    "Warum Modell-Provider einmal pro Account konfiguriert werden und über einen Handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt Repositories-Anweisungen von Modell-Anbieter-Anmeldedaten. Repositories beschreiben, was übersetzt werden soll, während Konten entscheiden, welches [Großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle Accounts gehören

Ein Team übersetzt oft mehrere Repositories mit der gleichen Anbieter-Beziehung. Für Konten zugewiesene Modelle ermöglichen es Administratoren, einen Anbieter-Schlüssel zu rotieren oder das zugrunde liegende Modell einmal ohne Bearbeitung jedes Repositories zu wechseln.

Diese Grenze hält Anmeldedaten auch außerhalb der Versionskontrolle. Ein Repository enthält eine lesbare Bezeichnung wie `translation-default`, nicht den Anbieter-Schlüssel.

## Handles garantieren stabile Intention

Das `model`-Feld in `L10N.md` verweist auf ein Konten-Modell-Handle:

```yaml
model: translation-default
```

Das Handle drückt die Intention des Repositoriums aus. Ein Administrator kann später überschreiben, welches Anbieter-Modell dieses Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokumentübersetzung ein konfiguriertes Modell. Das Hinzufügen mehrerer Modelle erstellt kein Ensemble, eine Fallback-Kette oder eine automatische Qualitätsebene. Der Repository-Autor wählt seinen Zweck über stabile Handles wie `translation-default`, `long-form` oder `japanese-specialist` aus.

Die Auswahl folgt der Kontexthierarchie für das Dokument und die Ziel-Lokalisierung:

1. Die am nächstengelegene `L10N/<locale>.md`-Datei, die `model` deklariert, hat für dieses Lokale Vorrang.
2. Andernfalls gewinnt die am nächstengelegene `L10N.md`-Datei, die `model` deklariert, für ihr Verzeichnis.
3. Übergeordnete `L10N.md`-Einstellungen werden vererbt, wenn eine nähergelegene Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei ein Handle deklariert, verwendet Glossia den Standardwert des Kontos.

Ein explizit konfiguriertes Handle muss existieren. Glossia meldet einen Fehler bei einem unbekannten Handle anstatt stillschweigend auf den Konten-Standardwert zu wechseln.

## Standardauswahl

Die Projekteinrichtung benötigt ein Modell, bevor ein Repository seine eigene `L10N.md` hat. Glossia wählt daher den Konten-Standardwert aus. Das erste hinzugefügte Modell für ein Konto wird Standard, und ein Administrator kann ein anderes Modell aus dessen Einstellungsseite zum Standard machen.

Sobald ein Repository eine `L10N.md` hat, macht ein explizites Handle seine Auswahl für Prüfer deutlich. Das Auslassen von `model` hält das Repository beim Konten-Standardwert.

## Die Grenze der menschlichen Überprüfung

Modell-Ausgaben sind vorgeschlagene Arbeit, keine automatische Zusammenführung. Setup- und Übersetzungsaktivitäten bleiben in Glossia sichtbar, während Repository-Änderungen über einen Pull Request für die Überprüfung durch das Team veröffentlicht werden. Dies bewahrt die gleiche Qualitäts- und Verantwortungsgrenze, die Teams bereits für Code verwenden.
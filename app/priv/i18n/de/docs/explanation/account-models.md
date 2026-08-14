%{
  title: "Kontomodelle",
  summary: "Warum Modellanbieter einmal pro Konto konfiguriert und über ein Handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt Repository-Anweisungen von den Zugangsdaten des Modellanbieters. Repositories beschreiben, was übersetzt werden soll, während Konten entscheiden, welches [große Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle zu Konten gehören

Ein Team übersetzt oft mehrere Repositories mit derselben Anbieterbeziehung. Kontobezogene Modelle ermöglichen es Administratoren, einen Anbieterschlüssel zu rotieren oder das zugrunde liegende Modell einmalig zu wechseln, ohne jedes Repository bearbeiten zu müssen.

Diese Abgrenzung hält auch Zugangsdaten aus der Versionsverwaltung fern. Ein Repository enthält ein lesbares Handle wie `translation-default` und nicht den Anbieterschlüssel.

## Handles bieten eine stabile Absicht

Das Feld `model` in `GLOSSIA.md` bezieht sich auf ein Modell-Handle des Kontos:

```yaml
model: translation-default
```

Das Handle drückt die Absicht des Repositorys aus. Ein Administrator kann später aktualisieren, welches Anbietermodell dieses Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet ein konfiguriertes Modell für jede Dokumentübersetzung. Das Hinzufügen mehrerer Modelle erstellt kein Ensemble, keine Fallback-Kette und keine automatische Qualitätsstufe. Der Repository-Autor wählt deren Zweck über stabile Handles wie `translation-default`, `long-form` oder `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und die Ziel-Locale:

1. Die am nächsten gelegene `GLOSSIA/<locale>.md`-Datei, die `model` deklariert, gewinnt für diese Locale.
2. Andernfalls gewinnt die am nächsten gelegene `GLOSSIA.md`-Datei, die `model` deklariert, für ihr Verzeichnis.
3. Übergeordnete `GLOSSIA.md`-Einstellungen werden vererbt, wenn eine näher gelegene Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei ein Handle deklariert, verwendet Glossia den Standardwert des Kontos.

Ein explizit konfiguriertes Handle muss existieren. Glossia meldet einen Fehler für ein unbekanntes Handle, anstatt stillschweigend auf den Standardwert des Kontos zu wechseln.

## Standardauswahl

Die Projekteinrichtung erfordert ein Modell, bevor ein Repository über ein eigenes `GLOSSIA.md` verfügt. Glossia wählt daher den Standardwert des Kontos aus. Das erste zu einem Konto hinzugefügte Modell wird zum Standardmodell, und ein Administrator kann ein anderes Modell über dessen Einstellungsseite zum Standardmodell machen.

Sobald ein Repository über `GLOSSIA.md` verfügt, macht die Verwendung eines expliziten Handles die Auswahl für Reviewer deutlich. Das Weglassen von `model` belässt das Repository beim Standardwert des Kontos.

## Die Grenze der menschlichen Überprüfung

Modellausgaben sind vorgeschlagene Arbeiten, kein automatischer Merge. Einrichtungs- und Übersetzungsaktivitäten bleiben in Glossia sichtbar, während Repository-Änderungen über einen Pull-Request zur Überprüfung durch das Team veröffentlicht werden. Dies bewahrt dieselbe Qualitäts- und Eigentumsgrenze, die Teams bereits für Code verwenden.
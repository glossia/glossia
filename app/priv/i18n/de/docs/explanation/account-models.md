%{
  title: "Accountmodelle",
  summary: "Warum Modellanbieter einmal pro Account konfiguriert und über handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt Repository-Anweisungen von Modellanbieter-Zugangsdaten. Repositories beschreiben, was übersetzt werden soll, während Accounts entscheiden, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle zu Accounts gehören

Ein Team übersetzt häufig mehrere Repositories im Rahmen desselben Anbieter-Bezugs. Modelle im Account-Bereich ermöglichen Administratoren, einen Provider-Schlüssel zu rotieren oder das zugrunde liegende Modell einmalig zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Grenze verhindert auch, dass Zugangsdaten in die Versionskontrolle gelangen. Ein Repository enthält einen lesbaren Handle wie `translation-default`, nicht den Provider-Schlüssel.

## Handles bieten einen stabilen Zweck

Das `model`-Feld in `GLOSSIA.md` bezieht sich auf ein Account-Modell-Handle:

```yaml
model: translation-default
```

Das Handle drückt die Intention des Repositorys aus. Ein Administrator kann später aktualisieren, welches Provider-Modell dieses Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokumentübersetzung ein konfiguriertes Modell. Das Hinzufügen mehrerer Modelle erstellt kein Ensemble, keine Fallback-Kette oder einen automatischen Qualitätsstufen. Der Repository-Autor wählt seinen Zweck über stabile Handles wie `translation-default`, `long-form` oder `japanese-specialist` aus.

Die Auswahl folgt der Kontexthierarchie für das Dokument und die Ziel-Lokalität:

1. Die nächste `GLOSSIA/<locale>.md`-Datei, die `model` angibt, hat für diese Ziel-Lokalität Vorrang.
2. Ansonsten hat die nächste `GLOSSIA.md`-Datei, die `model` angibt, Vorrang für ihr Verzeichnis.
3. Eltern-Einstellungen von `GLOSSIA.md` werden vererbt, wenn eine nähere Datei kein Modell angibt.
4. Wenn keine anwendbare Kontextdatei ein Handle angibt, nutzt Glossia das Account-Standardmodell.

Ein explizit konfiguriertes Handle muss vorhanden sein. Glossia meldet einen Fehler für ein unbekanntes Handle, statt stillschweigend auf das Account-Standardmodell umzustellen.

## Standardauswahl

Die Projektvorbereitung benötigt ein Modell, bevor ein Repository seine eigene `GLOSSIA.md` besitzt. Glossia wählt daher das Account-Standardmodell aus. Das erste Modell, das einem Account hinzugefügt wird, wird zum Standard, und ein Administrator kann ein anderes Modell auf seiner Einstellungsseite zum Standard machen.

Sobald ein Repository `GLOSSIA.md` besitzt, macht die Verwendung eines expliziten Handles die Entscheidung für Reviewer klar. Das Weglassen von `model` hält das Repository am Account-Standardmodell.

## Die Grenze der menschlichen Prüfung

Modellausgabe ist vorgeschlagene Arbeit, keine automatische Zusammenführung. Setup- und Übersetzungsaktivitäten bleiben in Glossia sichtbar, während Repository-Änderungen über einen Pull-Request veröffentlicht werden, damit das Team prüfen kann. Dies bewahrt die gleiche Qualitäts- und Verantwortungsgrenze, die Teams bereits für Code verwenden.
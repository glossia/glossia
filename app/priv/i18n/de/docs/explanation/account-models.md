%{
  title: "Account-Modelle",
  summary:
    "Warum Modellanbieter einmal pro Account konfiguriert und über Handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt die Anweisungen für Repositories von den Anmeldeinformationen der Modellanbieter. Repositorien beschreiben, was übersetzt werden soll, während Konten entscheiden, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit leistet.

## Warum Modelle Konten zugeordnet sind

Ein Team übersetzt oft mehrere Repositorien mit dem selben Provider. Modelle, die dem Konto zugeordnet sind, ermöglichen Administratoren, einen Provider-Schlüssel zu rotieren oder das zugrundeliegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Grenze hält Anmeldeinformationen zudem aus der Versionskontrolle heraus. Ein Repository enthält eine lesbare Kennung wie `translation-default`, nicht den Provider-Schlüssel.

## Handles sorgen für stabile Absicht

Das Feld `model` in `GLOSSIA.md` verweist auf eine für das Konto zugewiesene Modell-Kennung:

```yaml
model: translation-default
```

Die Kennung drückt die Absicht des Repositoriums aus. Ein Administrator kann später aktualisieren, welches Angebot-Modell diese Kennung auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jedes Dokument eine konfigurierte Übersetzung ein Modell. Das Hinzufügen mehrerer Modelle erzeugt kein Ensemble, keine Fallback-Kette oder eine automatische Qualitätsebene. Der Repository-Autor wählt den Zweck durch stabile Kennungen wie `translation-default`, `long-form` oder `japanese-specialist` aus.

Die Auswahl folgt der Kontext-Hierarchie für die Zuordnung der Datei und die Zielsprache:

1. Die naheliegendste `GLOSSIA/<locale>.md`-Datei, die `model` definiert, gewinnt für diese Lokalisierung.
2. Andernfalls gewinnt die naheliegendste `GLOSSIA.md`-Datei, die `model` definiert, für ihr Verzeichnis.
3. Elterneinstellungen von `GLOSSIA.md` werden vererbt, wenn eine näherliegende Datei kein Modell definiert.
4. Wenn keine anwendbare Kontextdatei eine Kennung definiert, verwendet Glossia die Standardeinstellung des Kontos.

Eine explizit konfigurierte Kennung muss existieren. Glossia meldet einen Fehler bei einer unbekannten Kennung anstatt stillschweigend auf die Standardeinstellung des Kontos zu wechseln.

## Standardauswahl

Die Projekt-Einrichtung benötigt ein Modell, bevor ein Repository sein eigenes `GLOSSIA.md` hat. Glossia wählt daher die Kontostandardauswahl. Das erste Modell, das einem Konto hinzugefügt wird, wird Standard, und ein Administrator kann von seiner Einstellungsseite ein anderes Modell zum Standard machen.

Sobald ein Repository `GLOSSIA.md` besitzt, macht die Verwendung einer expliziten Kennung die Auswahl für Prüfer klar. Das Weglassen von `model` hält das Repository auf der Konto-Standardauswahl.

## Die Grenze der menschlichen Prüfung

Die Modellausgabe ist vorgeschlagene Arbeit, keine automatische Zusammenführung. Setup- und Übersetzungsaktivitäten bleiben in Glossia sichtbar, während Repository-Änderungen über einen Pull Request für das Team zur Prüfung veröffentlicht werden. Dies bewahrt die gleiche Qualitäts- und Verantwortungsgrenze, die Teams bereits für Code nutzen.
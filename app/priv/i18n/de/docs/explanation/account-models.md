%{
  title: "Konto-Modelle",
  summary:
    "Warum Modellanbieter einmalig pro Konto konfiguriert und über Handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt Repository-Anweisungen von Modell-Anbieter-Zugangsdaten. Repositorys beschreiben, was übersetzt werden soll, während Konten entscheiden, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle den Konten zugeordnet sind

Ein Team übersetzt häufig mehrere Repositories mit derselben Provider-Beziehung. Account-spezifische Modelle ermöglichen es Administratoren, einen Provider-Schlüssel zu rotieren oder das zugrundeliegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Abgrenzung hält auch Zugangsdaten aus der Versionskontrolle fern. Ein Repository enthält einen lesbaren Handle wie `translation-default`, nicht der Provider-Schlüssel.

## Handles bieten stabile Absichten.

Das `model` Feld in `L10N.md` bezieht sich auf einen Account-Modell-Handle:

```yaml
model: translation-default
```

Das Handle drückt die Absicht des Repositorys aus. Ein Administrator kann später aktualisieren, welches Anbieter-Modell dieses Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia nutzt für jede Dokumentübersetzung ein konfiguriertes Modell. Das Hinzufügen mehrerer Modelle schafft kein Ensemble, eine Fallback-Kette oder eine automatische Qualitätsstufe. Der Repository-Autor wählt seinen Zweck durch stabile Handles wie `translation-default`, `long-form`, oder\] `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und die Ziel-Lokalisierung:

1. Die nächstgelegene `L10N/<locale>.md` Datei, die definiert `model` gilt für diese Ziel-Lokalisierung.
2. Andernfalls, die nächstgelegene `L10N.md` Datei, die definiert `model` gilt für sein Verzeichnis.
3. Eltern `L10N.md` Einstellungen werden vererbt, wenn keine näherliegende Datei ein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei einen handle deklariert, verwendet Glossia die Standardeinstellung des Kontos.

Ein explizit konfiguriertes handle muss vorhanden sein. Glossia meldet bei einem unbekannten handle einen Fehler statt stillschweigend auf den Konto-Standard umzuschalten.

## Standardauswahl

Die Projekteinrichtung benötigt ein Modell, bevor das Repository über sein eigenes verfügt. `L10N.md`. Glossia wählt daher den Konto-Standard. Das erste hinzugefügte Modell eines Kontos wird zum Standard, und ein Administrator kann ein anderes Modell von dessen Einstellungsseite zum Standard machen.

Sobald ein Repository hat `L10N.md`, wenn ein explizites Handle verwendet wird, wird die Wahl für Prüfer klar. Auslassen `model` behält das Repository auf dem Standards des Kontos.

## Die Grenze der menschlichen Überprüfung

Die Modellausgabe ist vorgeschlagene Arbeit, kein automatisches Zusammenführen. Setup- und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull-Request für die Teamprüfung veröffentlicht werden. Dies bewahrt die gleiche Qualitäts- und Verantwortungsgrenze auf, die Teams bereits für Code verwenden.
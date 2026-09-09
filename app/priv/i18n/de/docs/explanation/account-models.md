%{
  title: "Account-Modelle",
  summary:
    "Warum Modellanbieter einmal pro Account konfiguriert und über Handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt Repository-Anweisungen von Modellanbieter-Zugangsdaten. Repositories beschreiben, was übersetzt werden soll, während Konten festlegen, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle zu Konten gehören

Ein Team übersetzt oft mehrere Repositories mit derselben Provider-Beziehung. Account-Modelle ermöglichen es Administratoren, einen Provider-Schlüssel zu rotieren oder das zugrunde liegende Modell einmal zu wechseln, ohne jedes Repository zu bearbeiten.

Diese Grenze hält Credentials ebenfalls aus der Versionskontrolle heraus. Ein Repository enthält einen lesbaren Handle wie `translation-default`, nicht der Provider-Schlüssel.

## Handles bieten stabile Absicht.

Das `model` Feld `L10N.md` bezieht sich auf einen Account-Modell-Handle:

```yaml
model: translation-default
```

Der Handle drückt die Absicht des Repositories aus. Ein Administrator kann später anpassen, welches Provider-Modell dieser Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokumentübersetzung ein konfiguriertes Modell. Das Hinzufügen mehrerer Modelle erzeugt kein Ensemble, keine Fallback-Kette oder eine automatische Qualitätsstufe. Der Repository-Autor wählt seinen Zweck durch stabile Handles wie `translation-default`, `long-form`, oder `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und das Ziellokal:

1. Die nächste `L10N/<locale>.md` Datei, die angibt `model` gewinnt für dieses Ziellokal.
2. Ansonsten, die nächste `L10N.md` Datei, die angibt `model` gewinnt für das Verzeichnis.
3. Eltern `L10N.md` Einstellungen werden vererbt, wenn eine nähere Datei kein Modell deklariert.
4. Wenn keine anwendbare Kontextdatei ein Handle deklariert, verwendet Glossia den Standard des Kontos.

Ein explizit konfiguriertes Handle muss existieren. Glossia meldet einen Fehler bei einem unbekannten Handle, anstatt stillschweigend auf den Standard des Kontos zu wechseln.

## Standardauswahl

Das Projektsetup benötigt ein Modell, bevor ein Repository über ein eigenes Modell verfügt. `L10N.md`. Glossia wählt daher den Konto-Standard aus. Das zuerst einem Konto hinzugefügte Modell wird zum Standard, und ein Administrator kann ein anderes Modell als Standard auf dessen Einstellungsseite festlegen.

Sobald ein Repository verfügt `L10N.md`, macht eine explizite Handle die getroffene Entscheidung für die Rezensenten deutlich. Das Weglassen `model` belässt das Repository im Kontostandard.

## Die Grenze der manuellen Prüfung

Die Modellausgabe ist vorgesehene Arbeit, keine automatische Zusammenführung. Einrichtungs- und Übersetzungsaktivität bleibt in Glossia sichtbar, während Repository-Änderungen über einen Pull-Request für das Team zur Überprüfung veröffentlicht werden. Dies bewahrt den gleichen Qualitäts- und Verantwortungsbereich, den Teams bereits für Code verwenden.
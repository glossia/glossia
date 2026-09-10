%{
  title: "Kontomodell",
  summary:
    "Warum Modellanbieter einmal pro Konto konfiguriert und über das Handle referenziert werden.",
  category: "Erklärung",
  order: 2
}
---
Glossia trennt Repository-Anweisungen von Modell-Anbieter-Credentials. Repositories beschreiben, was übersetzt werden soll, während Konten entscheiden, welches [großes Sprachmodell](https://en.wikipedia.org/wiki/Large_language_model) die Arbeit ausführt.

## Warum Modelle Konten gehören

Ein Team übersetzt oft mehrere Repositories mit derselben Bezugsbeziehung zum Anbieter. Konto-basierte Modelle ermöglichen Administratoren, einen Anbieterschlüssel zu rotieren oder das zugrundeliegende Modell einmal umzuschalten, ohne jedes Repository zu bearbeiten.

Diese Grenze hält auch Credentials außerhalb von Source Control. Ein Repository enthält einen lesbaren Verweis wie `translation-default`, nicht der Anbieterschlüssel.

## Handles liefern eine stabile Absicht.

Das `model` Feld in `L10N.md` bezieht sich auf einen Account-Modell-Handle:

```yaml
model: translation-default
```

Der Handle drückt den Zweck des Repositories aus. Ein Administrator kann später aktualisieren, welches Anbietersmodell dieses Handle auswählt, während die Repository-Konfiguration stabil bleibt.

## Wie mehrere Modelle verwendet werden

Glossia verwendet für jede Dokumentübersetzung ein konfiguriertes Modell. Das Hinzufügen mehrerer Modelle erstellt kein Ensemble, keine Fallback-Kette oder eine automatische Qualitätsstufe. Der Repository-Autor bestimmt seinen Zweck über stabile Handles wie `translation-default`Das neu zusammengesetzte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Text-Literalen muss ein JSON-String-Array gleicher Länge zurückgeben. `long-form`Das neu zusammengesetzte Dokument hat zuvor die Validierung nicht bestanden: Die Wiederherstellung von Markdown-Text-Literalen lieferte ungültiges JSON zurück. `japanese-specialist`.

Die Auswahl folgt der Kontexthierarchie für das Dokument und die Zielsprache:

1. Die nächstgelegene `L10N/<locale>.md` Datei, die dies angibt, `model` gilt für diese Zielsprache.
2. Ansonsten, die nächstgelegene `L10N.md` Datei, die dies angibt, `model` gilt für das Verzeichnis.
3. Eltern `L10N.md` Die Einstellungen werden vererbt, wenn eine näher stehende Datei kein Modell deklariert.
4. Wenn kein anwendbarer Kontext eine Handle deklariert, verwendet Glossia die Standardeinstellung des Kontos.

Eine explizit konfigurierte Handle muss vorhanden sein. Glossia meldet einen Fehler für eine unbekannte Handle, statt schweigend auf die Standardeinstellung des Kontos umzuschalten.

## Standardauswahl

Für die Projekteinrichtung wird ein Modell benötigt, bevor ein Repository sein eigenes besitzt `L10N.md`. Glossia wählt daher die Standardeinstellung des Kontos. Das erste hinzugefügte Modell eines Kontos wird Standard, und ein Administrator kann ein anderes Modell von dessen Einstellungsseite als Standard setzen.

Sobald ein Repository `L10N.md`, durch die Nutzung eines expliziten Handles wird die Wahl der Reviewer deutlich. Das Weglassen `model` beibehält das Repository auf dem Konto-Standard.

## Die menschliche Prüfungsgrenze

Der Modelloutput ist vorgeschlagene Arbeit, keine automatische Zusammenführung. Aufbau und Übersetzungsaktivitäten bleiben in Glossia sichtbar, während Repository-Änderungen über einen Pull-Request für das Team zur Prüfung veröffentlicht werden. Dies bewahrt die gleiche Qualitäts- und Verantwortungsgrenze, die Teams bereits für Code nutzen.
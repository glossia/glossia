%{
  title: "Schrittweise Verfeinerung",
  summary:
    "Warum sich die Inhaltsqualität im Laufe der Zeit einpendelt, nicht in einem einzelnen Durchlauf.",
  category: "Erklärung",
  order: 1
}
---
Erste Entwürfe von [große Sprachmodelle](https://en.wikipedia.org/wiki/Large_language_model) sind strukturell korrekt, können aber Nuancen, Ton oder domänenspezifische Wortwahl übersehen. Das ist beabsichtigt. Glossia behandelt die Inhaltserstellung genauso wie Softwareteams Code: stellen Sie eine funktionierende Version bereit, überprüfen Sie diese und verbessern Sie diese iterativ.

## Der Verfeinerungszyklus

1. **Entwurf**: Glossia generiert einen ersten strukturell gültigen Entwurf basierend auf Ihren Quelldateien und dem Kontext in `L10N.md`.
2. **Überprüfung**: Ihr Team markiert Probleme über Pull-Requests und Diffs, denselben Workflow, den Sie bereits für Code verwenden.
3. **Verfeinerung**: Aktualisierte Kontextdateien, Terminologiekorrekturen und Review-Feedback fließen in den nächsten Durchlauf ein.
4. **Annäherung**: Mit jedem Zyklus verringert sich die Distanz zur Produktionsqualität. Das System lernt die Stimme Ihres Produkts durch den bereitgestellten Kontext kennen.

## Warum dies funktioniert

Der wichtige Einblick besteht darin, dass sich der Kontext ansammelt. Jeder Review-Kommentar, der zu einer aktualisierten `L10N.md` oder einem korrigierten Terminiologie-Eintrag führt, verbessert alle zukünftigen Durchläufe, nicht nur die Datei, die die Review ausgelöst hat.

Dies folgt dem gleichen Prinzip wie Kaizen in der Fertigung und der sukzessiven Approximation im Ingenieurwesen: Starten Sie mit einer mehr als ausreichenden Baseline und verbessern Sie diese systematisch durch menschliches Urteil in der Schleife.

## Praktische Implikationen

- Erwarten Sie keine Perfektion beim ersten Durchlauf. Planen Sie ein oder zwei Review-Kreisläufe ein.
- Investieren Sie Zeit in das Schreiben klarer Kontextdateien. Sie bieten die höchste Hebelwirkung, die Sie vornehmen können.
- Verwenden Sie die Server-Übersetzungssitzung, um zu verfolgen, welche Dateien wurden 
  übersprungen oder fehlgeschlagen.
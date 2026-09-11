%{
  title: "Schrittweise Verfeinerung",
  summary:
    "Warum die Inhaltsqualität sich im Laufe der Zeit verbessert, nicht in einem einzigen Durchlauf.",
  category: "Erklärung",
  order: 1
}
---
Erste Entwürfe von [große Sprachmodelle](https://en.wikipedia.org/wiki/Large_language_model) sind strukturell korrekt, können aber Nuancen, Töne oder domänenspezifische Formulierungen übersehen. Das ist beabsichtigt. Glossia behandelt die Inhaltserstellung genauso wie Software-Teams den Code bearbeiten: Veröffentlichen Sie eine funktionierende Version, überprüfen Sie sie und verbessern Sie sie iterativ.

## Der Verfeinerungszyklus

1. **Entwurf**: Glossia generiert einen strukturell korrekten ersten Entwurf basierend auf Ihren Quelldateien und dem Kontext in `L10N.md`.
2. **Überprüfen**: Ihr Team meldet Probleme über Pull-Requests und Diffs, den gleichen Workflow, den Sie ohnehin für Code nutzen.
3. **Verfeinern**: Aktualisierte Kontextdateien, Terminologiekorrekturen und Review-Feedback fließen in den nächsten Durchlauf ein.
4. **Konvergenz**: Jeder Zyklus verkürzt den Abstand zur Produktionsqualität. Das System lernt die Stimme Ihres Produkts anhand Ihres Kontexts.

## Warum das funktioniert

Der grundlegende Gedanke ist, dass sich Kontext anhäuft. Jeder Review-Kommentar, der zu einer Aktualisierung führt, `L10N.md` oder ein korrigierter Terminologiereintrag verbessert alle zukünftigen Durchläufe, nicht nur die Datei, die den Review ausgelöst hat.

Dies folgt demselben Prinzip wie Kaizen in der Fertigung und der schrittweisen Annäherung im Ingenieurwesen: Starten Sie mit einer guten Basis und verbessern Sie sie systematisch durch menschliches Urteil im Prozess.

## Praktische Implikationen

- Erwarten Sie keine Perfektion beim ersten Lauf. Planen Sie eine oder zwei Überprüfungsrunden ein.
- Investieren Sie Zeit in die Erstellung klarer Kontextdateien. Dies ist die Verbesserung mit dem größten Hebel, die Sie vornehmen können.
- Verwenden Sie die Server-Übersetzungssitzung, um zu verfolgen, welche Dateien übersetzt wurden,
  übersprungen, oder fehlgeschlagen.
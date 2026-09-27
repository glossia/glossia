%{
  title: "Schrittweise Verfeinerung",
  summary:
    "Warum sich die Inhaltsqualität im Laufe der Zeit verbessert, nicht in einem einzigen Durchlauf.",
  category: "Erklärung",
  section: "Übersetzung",
  order: 1
}
---
Erste Entwürfe von [großen Sprachmodellen](https://en.wikipedia.org/wiki/Large_language_model) sind strukturell korrekt, können aber Nuancen, Tonfall oder fachspezifische Formulierung verpassen. Das ist beabsichtigt. Glossia behandelt die Inhaltserstellung genauso wie Softwareteams Code: Veröffentlichen Sie eine funktionierende Version, prüfen Sie diese und verbessern Sie sie iterativ.

## Der Verfeinerungszyklus

1. **Entwurf**: Glossia generiert einen strukturell gültigen Erstentwurf basierend auf Ihren Quelldateien und dem Kontext in `L10N.md`.
2. **Überprüfung**: Ihr Team meldet Probleme über Pull-Anfragen und Diffs, denselben Workflow, den Sie bereits für Code verwenden.
3. **Verfeinern**: Aktualisierte Kontextdateien, Glossar-Korrekturen und Review-Feedback fließen in den nächsten Durchlauf ein.
4. **Konvergieren**: Jeder Zyklus verringert den Abstand zur Produktionsqualität. Das System lernt den Tonfall Ihres Produkts über den Kontext, den Sie bereitstellen.

## Warum das funktioniert

Die Schlüsselerkenntnis ist, dass sich Kontext ansammelt. Jeder Review-Kommentar, der zu einer Aktualisierung führt, `L10N.md` oder ein korrigierter Glossar-Eintrag verbessert alle zukünftigen Durchläufe, nicht nur die Datei, die den Review ausgelöst hat.

Dies folgt demselben Prinzip wie Kaizen in der Fertigung und der schrittweisen Approximation im Ingenieurwesen: Starten Sie mit einer ausreichend guten Basis und verbessern Sie diese systematisch mit menschlicher Urteilsfähigkeit im Loop.

## Praktische Implikationen

- Erwarten Sie keine Perfektion beim ersten Durchlauf. Planen Sie einen oder zwei Überprüfungszyklen ein.
- Investieren Sie Zeit in die Erstellung klarer Kontextdateien. Sie sind die Verbesserung mit dem größten Hebel, die Sie vornehmen können.
- Verwenden Sie die Server-Übersetzungssitzung, um zu verfolgen, welche Dateien übersetzt wurden,
  übersprungen, oder fehlgeschlagen.
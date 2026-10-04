%{
  title: "Schrittweise Verfeinerung",
  summary:
    "Warum sich die Inhaltsqualität im Laufe der Zeit verbessert, nicht in einem einzigen Durchlauf.",
  category: "Erklärung",
  section: "translation",
  order: 1
}
---
Erstentwürfe von [großen Sprachmodellen](https://en.wikipedia.org/wiki/Large_language_model) sind zwar strukturell korrekt, können aber Nuancen, Ton oder fachspezifische Formulierungen übersehen. Das ist beabsichtigt. Glossia behandelt die Inhaltsgenerierung genauso, wie Software-Teams Code behandeln: Stellen Sie eine funktionierende Version bereit, überprüfen Sie sie und verbessern Sie sie iterativ.

## Der Verfeinerungszyklus

1. **Entwurf**: Glossia erzeugt eine strukturell gültige erste Fassung basierend auf Ihren Quelldateien und dem Kontext in `L10N.md`.
2. **Review**: Ihr Team meldet Probleme über Pull-Requests und Diffs, denselben Workflow, den Sie bereits für Code nutzen.
3. **Verfeinern**: Aktualisierte Kontextdateien, Glossarkorrekturen und Review-Feedback fließen in den nächsten Durchlauf ein.
4. **Konvergieren**: Jeder Zyklus verkürzt den Abstand zur Produktionsqualität. Das System lernt die Stimme Ihres Produkts durch den Kontext, den Sie bereitstellen.

## Warum das funktioniert

Der Schlüsselaspekt ist, dass sich Kontext anhäuft. Jeder Review-Kommentar, der zu einem aktualisierten `L10N.md` oder ein korrigierter Glossar-Eintrag verbessert alle zukünftigen Durchläufe, nicht nur die Datei, die den Review ausgelöst hat.

Dies folgt demselben Prinzip wie Kaizen in der Fertigung und der sukzessiven Approximation im Ingenieurwesen: Starten Sie mit einer ausreichenden Basis und verbessern Sie sie systematisch mit menschlicher Urteilskraft im Regelkreis.

## Praktische Implikationen

- Erwarten Sie keine Perfektion beim ersten Durchlauf. Planen Sie ein oder zwei Überprüfungsrunden ein.
- Investieren Sie Zeit in die Erstellung klarer Kontextdateien. Sie bieten die größte Wirkung für den eingesetzten Aufwand.
- Nutzen Sie die Übersetzungssitzung in Glossia, um zu verfolgen, welche Dateien übersetzt wurden,
  übersprungen, oder fehlgeschlagen.
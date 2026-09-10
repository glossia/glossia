%{
  title: "Schrittweise Verfeinerung",
  summary:
    "Warum die Inhaltsqualität im Laufe der Zeit konvergiert, nicht in einem einzigen Durchlauf.",
  category: "Erklärung",
  order: 1
}
---
Erste Entwürfe von [großsprachigen Sprachmodellen](https://en.wikipedia.org/wiki/Large_language_model) sind strukturell korrekt, können aber Nuancen, Ton oder domänenspezifische Formulierungen verfehlen. Das ist beabsichtigt. Glossia behandelt die Inhaltserstellung genauso wie Software-Teams Code: eine funktionierende Version ausliefern, sie überprüfen und iterativ verbessern.

## Der Verfeinerungszyklus

1. **Entwurf**: Glossia erstellt einen strukturell gültigen ersten Entwurf basierend auf Ihren Quelldateien und dem Kontext in `L10N.md`.
2. **Überprüfung**: Ihr Team meldet Probleme über Pull Requests und Diffs, den gleichen Workflow, den Sie bereits für Code verwenden.
3. **Verfeinern**: Aktualisierte Kontextdateien, Terminologiekorrekturen und Review-Feedback speisen den nächsten Durchlauf ein.
4. **Konvergenz**: Jeder Zyklus verringert den Abstand zur Produktionsqualität. Das System lernt die Stimme Ihres Produkts durch den von Ihnen bereitgestellten Kontext.

## Warum das funktioniert

Der Kerngedanke ist, dass Kontext akkumuliert. Jeder Review-Kommentar, der zu einer Aktualisierung `L10N.md` oder einer korrigierten Terminologieregistrierung verbessert alle zukünftigen Durchläufe, nicht nur die Datei, die die Überprüfung ausgelöst hat.

Dies folgt dem gleichen Prinzip hinter Kaizen in der Fertigung und schrittweiser Annäherung im Ingenieurwesen: Beginnen Sie mit einer hinreichend guten Basis und verbessern Sie sie systematisch unter Einbeziehung menschlichen Urteils im Prozess.

## Praktische Implikationen

- Erwarten Sie keine Perfektion beim ersten Durchlauf. Planen Sie eine oder zwei Überprüfungszyklen ein.
- Investieren Sie Zeit beim Schreiben klarer Kontextdateien. Sie sind die Verbesserung mit der höchsten Hebelwirkung, die Sie vornehmen können.
- Nutzen Sie die Serverübersetzungssitzung, um zu verfolgen, welche Dateien übersetzt wurde,
  übersprungen, oder fehlgeschlagen.
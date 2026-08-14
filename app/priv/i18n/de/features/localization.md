%{
  title: "Lokalisierung",
  summary: "Lokalisieren Sie Ihre Inhalte in jede beliebige Sprache, während Struktur, Codeblöcke und Formatierung erhalten bleiben. Glossia-Agents übernehmen die schwere Arbeit, sodass sich Ihr Team auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "languages",
  hero_cta_text: "Jetzt starten",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Strukturerhaltend", description: "Codeblöcke, Frontmatter und Formatierungen überstehen die Lokalisierung unbeschadet. Keine manuelle Bereinigung erforderlich.", icon: "code"},
    %{title: "Beliebige Sprachpaare", description: "Lokalisieren Sie zwischen jeder beliebigen Kombination von Sprachen. Fügen Sie neue Zielsprachen hinzu, indem Sie eine einzige Zeile in Ihrer Konfiguration bearbeiten.", icon: "globe"},
    %{title: "Inkrementelle Aktualisierungen", description: "Nur geänderte Inhalte werden neu lokalisiert. Lockfiles erfassen, was bereits verarbeitet wurde, was Zeit und Kosten spart.", icon: "zap"}
  ]
}
---
## Funktionsweise der Lokalisierung

Glossia liest die Inhalte aus Ihrem Repository zusammen mit Lockfiles, die nachverfolgen, was bereits verarbeitet wurde. Anschließend führt es Ihren lokalen Kontext (`GLOSSIA.md`-Dateien im Stammverzeichnis oder in Unterverzeichnissen) mit dem globalen Kontext (Stimme, Terminologie und Einstellungen auf Kontoebene) zusammen, um ein vollständiges Bild davon zu erstellen, wie Ihre Inhalte in der jeweiligen Zielsprache klingen sollen. Nach der Zusammenführung dieses Kontexts lokalisiert ein agentenbasierter Workflow die geänderten Inhalte, wobei Struktur, Codeblöcke und Formatierung beibehalten werden. Sobald der Durchlauf abgeschlossen ist, werden die Ergebnisse als prüfbereiter Pull-Request an Ihr Repository zurückgesendet.

## Kontextgesteuerte Qualität

Jede Lokalisierung profitiert von dem von Ihnen bereitgestellten Kontext. Terminologie, Stilhinweise und domänenspezifische Anweisungen fließen in den Prompt ein, sodass der Agent Ergebnisse liefert, die der Stimme Ihres Produkts entsprechen.

## Sichere Überprüfung

Die Ergebnisse werden als Pull-Requests oder Entwurfsdateien bereitgestellt, damit Ihr Team sie überprüfen kann. Prüfer markieren Probleme, aktualisieren Kontextdateien, und der nächste Durchlauf übernimmt diese Korrekturen automatisch.
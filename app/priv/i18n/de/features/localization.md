%{
  title: "Lokalisierung",
  summary:
    "Lokalisieren Sie Ihre Inhalte in jede beliebige Sprache. Dabei bleiben Struktur, Code-Blöcke und Formatierung erhalten. Die Glossia-Agenten übernehmen die Schwerarbeit, sodass Ihr Team sich auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturorientiert",
      description:
        "Code-Blöcke, Frontmatter und Formatierung bleiben bei der Lokalisierung intakt. Keine manuelle Nacharbeit erforderlich.",
      icon: "Code"
    },
    %{
      title: "Jedes Sprachpaar",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Ziele hinzu, indem Sie eine einzelne Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Welt"
    },
    %{
      title: "Inkrementale Updates",
      description:
        "Nur geänderter Inhalt wird neu lokalisiert. Lockdateien protokollieren, was bereits verarbeitet wurde, und sparen Zeit und Kosten.",
      icon: "Blitz"
    }
  ]
}
---

## Wie Lokalisierung funktioniert

Glossia liest den Inhalt aus deinem Repository zusammen mit Lockdateien, die verfolgen, was bereits verarbeitet wurde. Es integriert dann deinen lokalen Kontext (`L10N.md` Dateien im Root oder in Subordnern) mit globalem Kontext (Stimme, Glossar und Einstellungen auf Kontoebene), um ein vollständiges Bild davon zu erhalten, wie dein Inhalt in jeder Zielsprache klingen sollte. Sobald dieser Kontext zusammengetragen ist, lokalisiert ein Agenten-Workflow den veränderten Inhalt, während Struktur, Code-Blöcke und Formatierung erhalten bleiben. Sobald der Durchlauf abgeschlossen ist, werden die Ergebnisse deinem Repository als Pull-Request zurückgesendet, der für die Überprüfung bereitsteht.

## Kontextgesteuerte Qualität

Jede Lokalisierung profitiert von dem Kontext, den du bereitstellst. Der Glossar, Stilhinweise und domänenspezifische Anweisungen fließen alle in den Prompt ein, sodass der Agent Ausgaben erzeugt, die der Stimme deines Produkts entsprechen.

## Überprüfen Sie mit Zuversicht

Die Ausgaben landen als Pull-Requests oder Entwurfsdateien, bereit für die Überprüfung durch dein Team. Prüfer markieren Probleme, aktualisieren Kontextdateien und der nächste Durchlauf integriert diese Korrekturen automatisch.

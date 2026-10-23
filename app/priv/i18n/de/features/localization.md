%{
  title: "Lokalisierung",
  summary:
    "Lokalisieren Sie Ihren Inhalt in jede beliebige Sprache bei gleichzeitiger Bewahrung von Struktur, Code-Blöcken und Formatierung. Glossia-Agenten übernehmen die schwere Arbeit, sodass Ihr Team sich auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturbewusst",
      description:
        "Code-Blöcke, Frontmatter und Formatierung überstehen die Lokalisierung unverändert. Keine manuelle Bereinigung erforderlich.",
      icon: "Code"
    },
    %{
      title: "Jedes Sprachpaar",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Ziele hinzu, indem Sie eine einzelne Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Welt"
    },
    %{
      title: "Inkrementelle Updates",
      description:
        "Nur geänderter Inhalt wird neu lokalisiert. Sperrdateien erfassen, was bereits verarbeitet wurde und sparen Zeit und Kosten ein.",
      icon: "Turbo"
    }
  ]
}
---

## Wie Lokalisierung funktioniert

Glossia liest den Inhalt aus deinem Repository zusammen mit Lockfiles, die verfolgen, was bereits verarbeitet wurde. Es kombiniert dann deinen lokalen Kontext (`L10N.md` Dateien im Root-Verzeichnis oder in Unterordnern) mit globalem Kontext (Stimme, Glossar und Einstellungen auf Kontoniveau), um ein vollständiges Bild davon zu erzeugen, wie dein Inhalt in jeder Zielsprache klingen sollte. Sobald dieser Kontext assembles ist, lokalisiert ein agentenbasierter Workflow den veränderten Inhalt und bewahrt dabei Struktur, Code-Blöcke und Formatierung. Sobald die Ausführung abgeschlossen ist, werden die Ergebnisse als Pull Request, der für die Prüfung bereit ist, an dein Repository gesendet.

## Kontextgestützte Qualität

Jede Lokalisierung profitiert vom Kontext, den du bereitstellst. Glossar, Stilhinweise und domänenspezifische Anweisungen fließen alle in den Prompt ein, damit der Agent eine Ausgabe erzeugt, die der Stimme deines Produkts entspricht.

## Überprüfung mit Zuversicht

Die Ergebnisse landen als Pull-Requests oder Entwurfsdateien, bereit für deine Überprüfung durch dein Team. Prüfer markieren Probleme, aktualisieren Kontextdateien und die nächste Ausführung übernimmt diese Korrekturen automatisch.

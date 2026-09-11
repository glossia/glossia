%{
  title: "Lokalisierung",
  summary:
    "Lokalisieren Sie Ihren Inhalt in beliebige Sprachen, wobei Struktur, Code-Blöcke und Formatierung erhalten bleiben. Glossia-Agenten übernehmen die schwere Arbeit, damit Ihr Team sich auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturbewusst",
      description:
        "Code-Blöcke, Frontmatter und Formatierung bleiben bei der Lokalisierung vollständig erhalten. Keine manuelle Aufräumarbeit erforderlich.",
      icon: "Code"
    },
    %{
      title: "Beliebige Sprachpaare",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Ziele hinzu, indem Sie eine einzelne Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Welt"
    },
    %{
      title: "Inkrementelle Updates",
      description:
        "Nur geänderter Inhalt wird neu lokalisiert. Sperrdateien verfolgen das bereits verarbeitete Material und sparen Zeit sowie Kosten.",
      icon: "Blitz"
    }
  ]
}
---
## Wie Lokalisierung funktioniert

Glossia liest den Inhalt aus Ihrem Repository zusammen mit Lockdateien, die verfolgen, was bereits verarbeitet wurde. Es kombiniert dann Ihren lokalen Kontext (`L10N.md`-Dateien im Stammordner oder in Unterordnern) mit globalem Kontext (Stimme, Terminologie und Einstellungen auf Kontoebene), um ein vollständiges Bild davon zu erstellen, wie Ihr Inhalt in jeder Zielsprache klingen sollte. Mit diesem zusammengeführten Kontext lokalisiert ein Agenten-Workflow den geänderten Inhalt, wobei Struktur, Code-Blöcke und Formatierung erhalten bleiben. Sobald der Durchlauf abgeschlossen ist, werden die Ergebnisse als Pull-Request an Ihr Repository zurückgesendet, bereit für die Überprüfung.

## Kontextgestützte Qualität

Jede Lokalisierung profitiert vom Kontext, den Sie bereitstellen. Terminologie, Stilhinweise und domänenspezifische Anweisungen fließen in den Prompt ein, sodass der Agent eine Ausgabe erzeugt, die der Stimme Ihres Produkts entspricht.

## Überprüfung mit Vertrauen

Ausgaben erscheinen als Pull-Requests oder Entwurfsdateien, bereit für die Prüfung durch Ihr Team. Prüfer kennzeichnen Probleme, aktualisieren Kontextdateien, und der nächste Durchlauf integriert diese Korrekturen automatisch.
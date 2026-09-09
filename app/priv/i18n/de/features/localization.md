%{
  title: "Lokalisierung",
  summary:
    "Lokalisieren Sie Ihren Inhalt in jede Sprache, während Struktur, Code-Blöcke und Formatierung erhalten bleiben. Glossia-Agenten erledigen die Hauptarbeit, damit sich Ihr Team auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturbewusst",
      description:
        "Code-Blöcke, Frontmatter und Formatierung bleiben bei der Lokalisierung intakt. Keine manuelle Bereinigung erforderlich.",
      icon: "Code"
    },
    %{
      title: "Jedes Sprachpaar",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Ziele hinzu, indem Sie eine einzige Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Welt"
    },
    %{
      title: "Inkrementelle Updates",
      description:
        "Nur veränderter Inhalt wird neu lokalisiert. Lockdateien verfolgen, was bereits verarbeitet wurde, und sparen Zeit und Kosten.",
      icon: "Blitz"
    }
  ]
}
---
## Wie Lokalisierung funktioniert

Glossia liest den Inhalt Ihres Repositorys zusammen mit Sperrdateien, die verfolgen, was bereits verarbeitet wurde. Es verbindet dann Ihren lokalen Kontext (`L10N.md`-Dateien im Root-Verzeichnis oder in Unterordnern) mit globalem Kontext (Stimme, Terminologie und Einstellungen auf Kontoebene), um ein vollständiges Bild davon zu erstellen, wie sich Ihr Inhalt in jeder Zielsprache anhören sollte. Mit diesem zusammengebauten Kontext lokalisiert ein Agenten-Arbeitsablauf den veränderten Inhalt und behält dabei Struktur, Code-Blöcke und Formatierung bei. Sobald der Durchlauf abgeschlossen ist, werden die Ergebnisse als Pull-Request an Ihr Repository zurückgesendet, bereit zur Prüfung.

## Kontextgestützte Qualität

Jede Lokalisierung profitiert vom Kontext, den Sie bereitstellen. Terminologie, Stilhinweise und anwendungsspezifische Anweisungen fließen alle in den Prompt ein, damit der Agent eine Ausgabe erzeugt, die der Stimme Ihres Produkts entspricht.

## Mit Zuversicht prüfen

Ausgaben landen als Pull-Requests oder Entwurfsdateien, damit Ihr Team sie prüfen kann. Prüfer markieren Probleme, aktualisieren Kontextdateien, und der nächste Durchlauf übernimmt diese Korrekturen automatisch.
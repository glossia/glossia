%{
  title: "Lokalisierung",
  summary:
    "Lokalisieren Sie Ihren Inhalt in jede beliebige Sprache, während Struktur, Code-Blöcke und Formatierung erhalten bleiben. Glossia-Agenten übernehmen die komplexe Arbeit, damit Ihr Team sich auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturbewusst",
      description:
        "Code-Blöcke, frontmatter und Formatierung bleiben bei der Lokalisierung intakt. Keine manuelle Bereinigung erforderlich.",
      icon: "Code"
    },
    %{
      title: "Beliebiges Sprachpaar",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Ziele hinzu, indem Sie eine einzelne Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Welt"
    },
    %{
      title: "Inkrementelle Aktualisierungen",
      description:
        "Nur geänderter Inhalt wird neu lokalisiert. Sperrdateien verfolgen, was bereits verarbeitet wurde, und sparen so Zeit und Kosten.",
      icon: "Zapen"
    }
  ]
}
---
## Wie Lokalisierung funktioniert

Glossia liest den Inhalt aus Ihrem Repository zusammen mit Lockdateien, die protokollieren, was bereits verarbeitet wurde. Sie verknüpft dann Ihren lokalen Kontext (`L10N.md`-Dateien im Wurzelverzeichnis oder in Unterverzeichnissen) mit globalem Kontext (Stimme, Terminologie und Einstellungen auf Kontoebene), um ein vollständiges Bild davon zu zeichnen, wie Ihr Inhalt in jeder Zielsprache klingen sollte. Mit diesem Kontext lokalisiert ein Agenten-Workflow den geänderten Inhalt, während Struktur, Code-Blöcke und Formatierung erhalten bleiben. Sobald der Durchlauf abgeschlossen ist, werden die Ergebnisse als Pull-Request in Ihr Repository zurückgesendet, bereit zur Prüfung.

## Kontextgetriebene Qualität

Jede Lokalisierung profitiert vom von Ihnen bereitgestellten Kontext. Terminologie, Stilhinweise und anwendungsspezifische Anweisungen fließen alle in den Prompt ein, sodass der Agent eine Ausgabe erzeugt, die der Stimme Ihres Produkts entspricht.

## Überprüfung mit Zuversicht

Die Ergebnisse landen als Pull-Requests oder Entwurfsdateien, bereit für die Prüfung durch Ihr Team. Prüfer melden Probleme, aktualisieren Kontextdateien und der nächste Durchlauf integriert diese Korrekturen automatisch.
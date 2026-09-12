%{
  title: " Lokalisierung",
  summary:
    "Lokalisieren Sie Ihre Inhalte in jede beliebige Sprache, wobei Struktur, Code-Blöcke und Formatierung intakt bleiben. Glossia-Agenten übernehmen die Schwerarbeit, damit Ihr Team sich auf die Prüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturintegrität",
      description:
        "Code-Blöcke, Frontmatter und Formatierung bleiben bei der Lokalisierung intakt. Keine manuelle Bereinigung erforderlich.",
      icon: "Code"
    },
    %{
      title: "Alle Sprachkombinationen",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Ziele hinzu, indem Sie eine einzige Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Welt"
    },
    %{
      title: "Inkrementelle Updates",
      description:
        "Nur geänderter Inhalt wird erneut lokalisiert. Sperrdateien protokollieren, was bereits verarbeitet wurde und sparen Zeit und Kosten.",
      icon: "Blitz"
    }
  ]
}
---
## So funktioniert die Lokalisierung

Glossia liest den Inhalt Ihres Repositoriums zusammen mit Lockdateien ein, die verfolgen, was bereits verarbeitet wurde. Anschließend kombiniert er Ihren lokalen Kontext (`L10N.md`-Dateien im Stammordner oder in Unterordnern) mit dem globalen Kontext (Tonfall, Terminologie und Einstellungen auf Kontoebene), um ein vollständiges Bild davon zu erstellen, wie Ihr Inhalt in jeder Zielsprache klingen sollte. Mit diesem Kontext führt ein agentischer Workflow die Lokalisierung des geänderten Inhalts durch, wobei er Struktur, Code-Blöcke und Formatierung beibehält. Sobald die Ausführung abgeschlossen ist, werden die Ergebnisse als Pull Request an Ihr Repository zurückgesendet und sind für die Überprüfung bereit.

## Kontextgestützte Qualität

Jede Lokalisierung profitiert von dem bereitgestellten Kontext. Terminologie, Stilanweisungen und domänenspezifische Hinweise fließen alle in den Prompt ein, sodass der Agent eine Ausgabe liefert, die dem Tonfall Ihres Produkts entspricht.

## Überprüfung mit Zuversicht

Die Ergebnisse landen als Pull Requests oder Entwurfsdateien und sind bereit für die Überprüfung durch Ihr Team. Überprüfer markieren Probleme, aktualisieren Kontextdateien, und der nächste Durchlauf integriert diese Korrekturen automatisch.
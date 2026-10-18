%{
  title: "Lokalisierung",
  summary:
    "Lokalisieren Sie Ihren Inhalt in jede Sprache, während Struktur, Code-Blöcke und Formatierung erhalten bleiben. Glossia-Agenten übernehmen die schwerarbeit, sodass Ihr Team sich auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturbewusst",
      description:
        "Code-Blöcke, Frontmatter und Formatierung überstehen die Lokalisierung intakt. Keine manuelle Nachbearbeitung erforderlich.",
      icon: "Code"
    },
    %{
      title: "Beliebiges Sprachpaar",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Zielsprachen hinzu, indem Sie eine einzelne Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Welt"
    },
    %{
      title: "Inkrementelle Updates",
      description:
        "Nur geänderter Inhalt wird neu lokalisiert. Lockfiles verfolgen das, was bereits verarbeitet wurde, und sparen Zeit und Kosten.",
      icon: "Zap"
    }
  ]
}
---

## Wie Lokalisierung funktioniert

Glossia liest den Inhalt aus deinem Repository zusammen mit Lockdateien, die verfolgen, was bereits verarbeitet wurde. Anschließend kombiniert es deinen lokalen Kontext (`L10N.md` Dateien im Stammverzeichnis oder in Unterordnern) mit dem globalen Kontext (Stimme, Glossar und Einstellungen auf Kontoebene), um ein vollständiges Bild davon zu erstellen, wie dein Inhalt in jeder Zielsprache klingen sollte. Sobald dieser Kontext zusammengefügt ist, lokalisiert ein Agenten-Workflow den geänderten Inhalt, während er Struktur, Code-Blöcke und Formatierung bewahrt. Sobald der Durchlauf abgeschlossen ist, werden die Ergebnisse als Pull Request an dein Repository zurückgesendet, bereit zur Überprüfung.

## Kontextgestützte Qualität

Jede Lokalisierung profitiert vom Kontext, den du bereitstellst. Glossar, Stilhinweise und domänenspezifische Anweisungen fließen alle in den Prompt hinein, sodass der Agent eine Ausgabe produziert, die dem Tonfall deines Produkts entspricht.

## Überprüfung mit Zuversicht

Die Ergebnisse erscheinen als Pull Requests oder Entwurfsdateien, bereit für deine Teamüberprüfung. Prüfer markieren Probleme, aktualisieren Kontextdateien, und der nächste Durchlauf integriert diese Korrekturen automatisch.

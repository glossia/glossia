%{
  title: "Lokalisierung",
  summary:
    "Lokalisieren Sie Ihren Inhalt in jede Sprache, während Struktur, Codeblöcke und Formatierung erhalten bleiben. Glossia-Agenten übernehmen die Schwerarbeit, damit Ihr Team sich auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Starten",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturbewusst",
      description:
        "Codeblöcke, Frontmatter und Formatierung bleiben während der Lokalisierung intakt. Keine manuelle Bereinigung erforderlich.",
      icon: "Code"
    },
    %{
      title: "Beliebige Sprachpaare",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Ziele hinzu, indem Sie eine einzelne Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Weltkugel"
    },
    %{
      title: "Inkrementelle Aktualisierungen",
      description:
        "Nur geänderter Inhalt wird erneut lokalisiert. Sperrdateien verwalten, was bereits verarbeitet wurde, und sparen Zeit und Kosten.",
      icon: "Löschen"
    }
  ]
}
---
## Wie Lokalisierung funktioniert

Glossia liest den Inhalt aus deinem Repository zusammen mit Lockfiles, die verfolgen, was bereits verarbeitet wurde. Es kombiniert deinen lokalen Kontext (`L10N.md`-Dateien im Root oder in Unterverzeichnissen) mit globalem Kontext (Stimme, Terminologie und Account-Level-Einstellungen), um ein vollständiges Bild davon zu erstellen, wie dein Inhalt in jeder Zielsprache klingen sollte. Sobald dieser Kontext zusammengestellt ist, lokalisiert ein Agenten-Workflow den geänderten Inhalt, während Struktur, Code-Blöcke und Formatierung erhalten bleiben. Sobald der Durchlauf abgeschlossen ist, werden Ergebnisse als eine Pull Request an dein Repository zurückgesendet, bereit zur Überprüfung.

## Kontextgetriebene Qualität

Jede Lokalisierung profitiert vom bereitgestellten Kontext. Terminologie, Stilhinweise und domänenspezifische Anweisungen fließen alle in den Prompt ein, damit der Agent Ergebnisse erstellt, die mit der Stimme deines Produkts übereinstimmen.

## Überprüfung mit Zuversicht

Ergebnisse landen als Pull Requests oder Entwurfsdateien, bereit für die Überprüfung durch dein Team. Prüfer melden Probleme, aktualisieren Kontextdateien und der nächste Durchlauf integriert diese Korrekturen automatisch.
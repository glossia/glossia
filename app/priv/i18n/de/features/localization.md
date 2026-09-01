%{
  title: "Lokalisierung",
  summary:
    "Lokalisieren Sie Ihren Inhalt in jede beliebige Sprache, wobei Struktur, Code-Blöcke und Formatierung intakt bleiben. Glossia-Agenten übernehmen die schwereren Aufgaben, damit Ihr Team sich auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturbewusst",
      description:
        "Code-Blöcke, Frontmatter und Formatierung überstehen die Lokalisierung intakt. Keine manuelle Bereinigung erforderlich.",
      icon: "Code"
    },
    %{
      title: "Jede Sprachkombination",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Ziele hinzu, indem Sie eine einzelne Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Welt"
    },
    %{
      title: "Inkrementelle Updates",
      description:
        "Nur geänderte Inhalte werden neu lokalisiert. Lockdateien erfassen, was bereits verarbeitet wurde, und sparen Zeit und Kosten.",
      icon: "Schnell"
    }
  ]
}
---
## So funktioniert Lokalisierung

Glossia liest den Inhalt aus deinem Repository sowie Lockdateien, die verfolgen, was bereits verarbeitet wurde. Dann verschmilzt es deinen lokalen Kontext (`GLOSSIA.md`-Dateien im Root-Verzeichnis oder in Unterordnern) mit globalem Kontext (Stimme, Terminologie und Einstellungen auf Kontoebene), um ein vollständiges Bild davon zu erhalten, wie dein Inhalt in jeder Zielsprache klingen sollte. Mit diesem Kontext lokalisiert ein agentenbasierter Workflow den geänderten Inhalt, während Struktur, Code-Blöcke und Formatierung erhalten bleiben. Sobald der Lauf abgeschlossen ist, werden die Ergebnisse als Pull Request zurück in dein Repository gesendet, der zur Überprüfung bereitsteht.

## Kontextgestützte Qualität

Jede Lokalisierung profitiert vom von dir bereitgestellten Kontext. Terminologie, Stilhinweise und domänenspezifische Anweisungen fließen alle in den Prompt ein, sodass der Agent eine Ausgabe generiert, die der Stimme deines Produkts entspricht.

## Überprüfung mit Zuversicht

Die Ausgaben landen als Pull Requests oder Entwurfsdateien, bereit für die Prüfung deines Teams. Prüfer markieren Probleme, aktualisieren Kontextdateien und der nächste Lauf integriert diese Korrekturen automatisch.
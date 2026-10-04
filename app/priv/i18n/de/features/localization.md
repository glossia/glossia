%{
  title: "Lokalisierung",
  summary:
    "Lokalisieren Sie Ihren Inhalt in jede Sprache, während Struktur, Code-Blöcke und Formatierung erhalten bleiben. Glossia-Agenten übernehmen die Schwerarbeit, sodass sich Ihr Team auf die Überprüfung konzentrieren kann.",
  order: 1,
  icon: "Sprachen",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Strukturbewusst",
      description:
        "Code-Blöcke, Frontmatter und Formatierung bleiben bei der Lokalisierung intakt. Kein manuelles Aufräumen erforderlich.",
      icon: "Code"
    },
    %{
      title: "Jede Sprachkombination",
      description:
        "Lokalisieren Sie zwischen beliebigen Sprachkombinationen. Fügen Sie neue Zielsprachen hinzu, indem Sie eine Zeile in Ihrer Konfiguration bearbeiten.",
      icon: "Welt"
    },
    %{
      title: "Inkrementelle Updates",
      description:
        "Nur geänderter Inhalt wird erneut lokalisiert. Lockdateien verfolgen, was bereits verarbeitet wurde, was Zeit und Kosten spart.",
      icon: "Blitz"
    }
  ]
}
---
## So funktioniert die Lokalisierung

Glossia liest den Inhalt aus Ihrem Repository zusammen mit Lockdateien, die verfolgen, was bereits verarbeitet wurde. Es fusioniert Ihren lokalen Kontext (`L10N.md`-Dateien im root oder in Unterordnern) mit globalem Kontext (Stimme, Glossar und Einstellungen auf Kontoebene), um ein vollständiges Bild davon zu erstellen, wie Ihr Inhalt in jeder Zielsprache klingen sollte. Mit diesem zusammengestellten Kontext führt ein agentenbasierter Workflow die Lokalisierung des geänderten Inhalts durch, während Struktur, Code-Blöcke und Formatierung erhalten bleiben. Sobald der Durchlauf abgeschlossen ist, werden die Ergebnisse als Pull-Request an Ihr Repository gesendet und sind zur Überprüfung bereit.

## Kontextgestützte Qualität

Jede Lokalisierung profitiert von dem Kontext, den Sie bereitstellen. Glossar, Stilhinweise und branchenspezifische Anweisungen fließen alle in den Prompt ein, sodass der Agent eine Ausgabe erzeugt, die der Stimme Ihres Produkts entspricht.

## Überprüfung mit Zuversicht

Ergebnisse erscheinen als Pull-Requests oder Entwurfsdateien, bereit für eine Überprüfung durch Ihr Team. Überprüfer melden Probleme, aktualisieren Kontextdateien und der nächste Durchlauf übernimmt diese Korrekturen automatisch.
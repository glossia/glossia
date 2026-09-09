%{
  title: "Sprachspeicher",
  summary:
    "Eine versionierte Kontextebene, die die Stimme, die Terminologie und den Stil Ihrer Organisation einfängt. Sprachspeicher leitet jeden Agenten-Workflow und greift über die API und MCP auf Ihre eigenen Tools zu.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und nachvollziehbar",
      description:
        "Jede Änderung an Ihrer Stimme oder Terminologie erstellt eine neue, unveränderliche Version. Sie können die Historie überprüfen, Iterationen vergleichen und zurückrollen, wenn etwas vom Kurs abweicht.",
      icon: "git-branch"
    },
    %{
      title: "Mehr als nur Lokalisierung",
      description:
        "Sprachspeicher dient nicht nur der Lokalisierung. Nutzen Sie ihn, um Marketingtexte zu generieren, Dokumentation zu entwerfen, Pull-Requests zu prüfen oder Social-Posts zu verfassen – alles in der Stimme Ihrer Organisation.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Zugriff auf Sprachspeicher über die REST-API oder den MCP-Server. Integrieren Sie ihn in eigene CI-Pipelines, Content-Tools oder benutzerdefinierte Agenten, um die Konsistenz überall zu gewährleisten, wo Sie schreiben.",
      icon: "puzzle"
    }
  ]
}
---
## Was ist Sprachspeicher?

Sprachspeicher ist der angesammelte Kontext, der den KI-Assistenten von Glossia erklärt, wie sich Ihre Organisation kommuniziert. Er besteht aus zwei grundlegenden Komponenten, die Sie mit der Zeit entwickeln und verfeinern:

**Stimme** definiert, wie der Inhalt wirken soll. Ton, Formalität, Zielgruppe und flexible Richtlinien werden hier verwaltet. Sie können eine Basis-Stimme für Ihren Account festlegen und dann einzelne Felder für bestimmte Sprachen anpassen, sodass Ihre japanischen Texte formeller ausfallen, während der englische Text weiterhin lockert bleibt.

**Terminologie** definiert die Bedeutung von Begriffen und deren Lokalisierung. Jeder Eintrag enthält eine Definition und sprachspezifische Übersetzungen. Wenn ein KI-Assistent Begriffe wie "workspace" in Ihrem Quelltext findet, bestimmt die Terminologie, ob sie übersetzt, phonetisch wiedergegeben oder belassen werden sollen, sowie die genaue Ausdrucksform in jeder Zielsprache.

Zusammen bilden Stimme und Terminologie eine Kontext-Ebene, auf die Agenten bei jeder Ausführung zurückgreifen. Je mehr Sie in diese Ebene investieren, desto weniger Nachbearbeitung benötigen Sie für Ihre Ergebnisse.

## Unveränderbare Versionskontrolle

Das Sprachgedächtnis ist append-only. Wenn Sie Ihre Stimme oder Terminologie aktualisieren, erstellt Glossia eine neue Version statt der alten zu überschreiben. Jede Version dokumentiert Ersteller, Zeitpunkt und eine optionale Änderungsnotiz, die erklärt, was sich entwickelt hat.

Das bedeutet, Sie verfügen stets über einen vollständigen Prüfpfad. Sie können Version 3 mit Version 7 vergleichen, um zu verstehen, wie sich Ihre Tonart über ein Quartal verschoben hat. Wenn eine kürzlich eingeführte Änderung Inkonsistenzen verursachte, rollen Sie auf eine vorherige Version zurück und setzen Sie den Vorgang fort.

Versionierung macht die Zusammenarbeit zudem sicherer. Mehrere Teammitglieder können Stimmenänderungen vorschlagen, ohne sich um Konflikte zu sorgen, da jede Änderung ein diskretes, nachverfolgbares Ereignis ist.

## Lokalisierungsbewusste Auflösung

Wenn ein Agent einen Workflow für eine spezifische Lokalisierung ausführt, setzt Glossia das Sprachgedächtnis für diesen Kontext an. Es beginnt mit Ihren Basis-Stimeinstellungen und wendet anschließend lokalspezifische Überschreibungen darüber an. Gleiches gilt für die Terminologie: Nur Einträge, die einen lokalisierten Begriff für die Ziel-Lokalisierung enthalten, werden berücksichtigt.

Dieser Auflösungs-Schritt bedeutet, dass Agenten stets mit dem relevantesten Kontext arbeiten. Sie müssen keine separaten Konfigurationen je Sprache pflegen. Definieren Sie Ihre Standardwerte einmal, überschreiben Sie dort, wo es zählt, und überlassen Sie den Rest dem Auflösungssystem.

## Nutzen Sie es überall

Das Sprachgedächtnis wurde für die Lokalisierung entwickelt, aber es ist nützlich dort, wo Sie Text erstellen. Weil der Kontext über den zugänglich ist [REST API](/features/rest-api) und den [MCP-Server](/features/mcp-server), können Sie sie in Workflows jenseits der Lokalisierung integrieren:

**Marketing und Social-Media-Inhalte** -- Integrieren Sie die Stimme Ihrer Organisation in einen Inhaltsagenten, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landing-Page-Texte erstellt. Terminologie sichert konsistente Markenbegriffe, und Stimmenteinstellungen garantieren, dass der Tonfall Ihrer Marke entspricht.

**Dokumentation** -- Leiten Sie Sprachwissen in eine Dokumentations-Pipeline ein, so dass technisches Schreiben denselben Stilregeln folgt wie der Rest Ihrer Inhalte. Terminologie-Einträge verhindern Abweichungen zwischen Dokumenten, Hilfeartikeln und im-Produkt-Texten.

**Code-Review** -- Erstellen Sie einen Agenten, der Pull-Request-Text (Fehlermeldungen, UI-Labels, Onboarding-Text) nach Ihrem Sprachgebrauch und Ihrer Terminologie überprüft. Markieren Sie Inkonsistenzen, bevor sie veröffentlicht werden.

**Benutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann das Sprachgedächtnis lesen und schreiben. Fragen Sie Ihren Programmierungsassistenten: "Aktualisieren Sie die Terminologie mit dem neuen Produktnamen" oder "Stellen Sie den Sprachstil auf professionell für die deutsche Lokalisierung", und er übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Schrittweise Verfeinerung

Das Sprachgedächtnis verbessert sich durch Nutzung. Jedes Mal, wenn ein Prüfer die Ausgabe eines Agenten korrigiert, wird diese Korrektur in die nächste Version Ihres Sprachgebrauchs oder Ihrer Terminologie übernommen. Im Laufe der Zeit verringert sich die Lücke zwischen dem ersten Entwurf und der finalen Ausgabe, und der Überprüfungsschritt wird schneller.

Dies ist die Rückkopplungsschleife im Kern von Glossia: generieren, überprüfen, Kontext verfeinern, erneut generieren. Die Agenten befolgen nicht nur Anweisungen. Sie arbeiten mit Kontext, der mit jedem Zyklus besser wird.
%{
  title: "Sprachgedächtnis",
  summary:
    "Ein versionierter Kontextlayer, der die Stimme, Terminologie und den Stil Ihres Unternehmens erfasst. Sprachgedächtnis steuert jeden Agentenablauf und erweitert sich über die API und den MCP-Server auf Ihre eigenen Tools.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und nachvollziehbar",
      description:
        "Jede Änderung Ihrer Stimme oder Terminologie erzeugt eine neue unveränderliche Version. Sie können die Historie prüfen, Iterationen vergleichen und zurückrollen, falls Abweichungen auftreten.",
      icon: "git-branch"
    },
    %{
      title: "Jenseits der Lokalisierung",
      description:
        "Sprachgedächtnis beschränkt sich nicht nur auf die Lokalisierung. Nutzen Sie es zur Generierung von Marketingtexten, zum Entwurf von Dokumentation, zur Prüfung von Pull Requests oder zur Erstellung von Social Posts – alles in der Stimme Ihres Unternehmens.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Greifen Sie über die REST-API oder den MCP-Server auf Sprachgedächtnis zu. Leiten Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierte Agenten ein, um die Konsistenz an jeder geschriebenen Stelle zu gewährleisten.",
      icon: "puzzle"
    }
  ]
}
---
## Was ist Sprachgedächtnis?

Sprachgedächtnis ist der angesammelte Kontext, der den Agenten von Glossia sagt, wie Ihre Organisation kommuniziert. Es besteht aus zwei Kernelementen, die Sie im Laufe der Zeit erstellen und verfeinern:

**Stimme** definiert, wie Inhalte klingen sollen. Tonfall, Formalität, Zielgruppe und freiforme Richtlinien leben hier. Sie können eine Basisstimme für Ihr Konto festlegen und dann bestimmte Felder für einzelne Lokale überschreiben, so dass Ihre japanischen Texte formeller sein können, während Ihr Englisch konversationell bleibt.

**Terminologie** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollen. Jeder Eintrag enthält eine Definition und Übersetzungen pro Lokale. Wenn ein Agent "workspace" in Ihrem Quellinhalt findet, legt die Terminologie fest, ob zu lokalisieren, transliterieren oder unverändert lassen soll, und genau welches Wort in jeder Zielsprache verwendet wird.

Zusammen bilden Stimme und Terminologie eine Kontextschicht, die Agenten bei jedem Durchlauf konsultieren. Je mehr Sie in diese Schicht investieren, desto weniger Überprüfung Ihre Ausgabe benötigt.

## Unveränderliche Versionierung

Das Sprachgedächtnis ist nur zu erweitern. Wenn Sie Ihre Stimme oder Terminologie aktualisieren, erstellt Glossia eine neue Version anstelle des Überschreibens der alten. Jede Version dokumentiert, wer sie erstellt hat, wann und eine optionale Änderungsnotiz, die erklärt, was sich entwickelt hat.

Das bedeutet, Sie verfügen immer über einen vollständigen Audit-Trail. Sie können Version 3 mit Version 7 vergleichen, um zu verstehen, wie sich Ihr Ton im Laufe eines Vierteljahres verschoben hat. Wenn eine jüngere Änderung Inkonsistenzen eingeführt hat, gehen Sie zu einer früheren Version zurück und setzen Sie fort.

Die Versionierung macht collaboration auch sicherer. Mehrere Teammitglieder können Sprachänderungen vorschlagen, ohne sich um Konflikte zu kümmern, da jede Änderung ein eigenständiges, nachvollziehbares Ereignis darstellt.

## Lokalsensible Auflösung

Wenn ein Agent einen Workflow für eine bestimmte Lokale ausführt, löst Glossia das Sprachgedächtnis für diesen Kontext. Es beginnt mit Ihren Basis-Stimmentellungen und wendet dann alle lokalspezifischen Überschreibungen darüber an. Das Gleiche gilt für Terminologie: nur Einträge, die einen lokalisierten Begriff für das Ziel-Lokale haben, sind enthalten.

Dieser Auflösungsschritt bedeutet, Agenten arbeiten immer mit dem relevantesten Kontext. Sie müssen keine separaten Konfigurationen pro Sprache pflegen. Definieren Sie Ihre Standards einmal, überschreiben Sie dort, wo es wichtig ist, und lassen Sie das Auflösungssystem den Rest übernehmen.

## Nutzen Sie es überall

Das Sprachgedächtnis wurde für die Lokalisierung entwickelt, ist aber nützlich, wo immer Sie Text erstellen. Da der Kontext über das zugänglich ist [REST API](/features/rest-api) und der [MCP Server](/features/mcp-server), können Sie es in Workflows jenseits der Lokalisierung integrieren:

**Marketing und Social Content** -- Integrieren Sie die Stimme Ihrer Organisation in einen Content-Agenten, der Social-Media-Posts, E-Mail-Kampagnen oder Landingpage-Texte erstellt. Terminologie hält Markenterme konsistent, und die Stimmeinstellungen gewährleisten, dass der Tonfall mit Ihrer Marke übereinstimmt.

**Dokumentation** -- Füttern Sie das Sprachgedächtnis in eine Dokumentationspipeline ein, so dass technisches Schreiben dieselben Stilregeln wie der Rest Ihres Contents einhält. Terminologie-Einträge verhindern Abweichungen zwischen Dokumenten, Hilfsartikeln und den Texten im Produkt.

**Code-Überprüfung** -- Bauen Sie einen Agenten auf, der Pull-Request-Inhalte (Fehlermeldungen, UI-Labels, Onboarding-Texte) gegen Ihre Stimme und Terminologie überprüft. Markieren Sie Inkonsistenzen, bevor sie veröffentlicht werden.

**Benutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann das Sprach-Gedächtnis lesen und schreiben. Bitten Sie Ihren Code-Assistenten, "die Terminologie mit dem neuen Produktnamen zu aktualisieren" oder "die Stimmtönung auf professionell für die deutsche Lokalisierung zu setzen", und er übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Kontinuierliche Verfeinerung

\-- Das Sprach-Gedächtnis verbessert sich durch Nutzung. Jedes Mal, wenn ein Prüfer die Ausgabe eines Agenten korrigiert, fließt diese Korrektur in die nächste Version Ihrer Stimme oder Terminologie zurück. Mit der Zeit verringert sich die Lücke zwischen dem ersten Entwurf und der finalen Ausgabe, und der Prüfungsschritt beschleunigt sich.

Dies ist die Feedback-Schleife im Kern von Glossia: generieren, überprüfen, Kontext verfeinern, erneut generieren. Die Agenten folgen nicht einfach nur Anweisungen. Sie arbeiten mit Kontext, der mit jedem Zyklus besser wird.
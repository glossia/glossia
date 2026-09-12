%{
  title: "Sprachgedächtnis",
  summary:
    "Eine versionierte Kontextschicht, die die Stimme, Terminologie und den Stil Ihrer Organisation erfasst. Das Sprachgedächtnis leitet jeden Agenten-Workflow und erstreckt sich über die API und MCP auf Ihre eigenen Tools.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und überprüfbar",
      description:
        "Jede Änderung an Ihrer Stimme oder Terminologie erstellt eine neue, unveränderliche Version. Sie können die Historie überprüfen, Iterationen vergleichen und zurückrollen, wenn Abweichungen entstehen.",
      icon: "git-branch"
    },
    %{
      title: "Über die Lokalisierung hinaus",
      description:
        "Sprachgedächtnis dient nicht nur der Lokalisierung. Nutzen Sie es, um Marketingtexte zu erstellen, Dokumentationen zu entwerfen, Pull Requests zu prüfen oder soziale Beiträge zu verfassen – alles in Ihrer Organisationsstimme.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Greifen Sie über die REST-API oder den MCP-Server auf das Sprachgedächtnis zu. Leiten Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierte Agenten ein, um die Konsistenz überall zu wahren, wo Sie schreiben.",
      icon: "puzzle"
    }
  ]
}
---
## Was ist Sprach-Gedächtnis?

Das Sprach-Gedächtnis ist der angesammelte Kontext, der den Agenten von Glossia zeigt, wie Ihre Organisation kommuniziert. Es besteht aus zwei Kernbausteinen, die Sie im Laufe der Zeit erstellen und verfeinern:

**Stimme** definiert, wie Inhalte klingen sollen. Ton, Formalität, Zielgruppe und freie Richtlinien befinden sich hier. Sie können eine Basisstimme für Ihr Konto festlegen und dann spezifische Felder für einzelne Lokale überschreiben, sodass Ihre japanischen Texte formeller sein können, während Ihre englischen Texte gesprächig bleiben.

**Terminologie** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollen. Jeder Eintrag enthält eine Definition und Übersetzungen pro Locale. Wenn ein Agent den Begriff "workspace" in Ihrem Quellinhalt findet, entscheidet die Terminologie, ob er ihn lokalisiert, transliterieren oder unverändert lassen soll, und genau welches Wort in jeder Zielsprache verwendet werden soll.

Zusammen bilden Stimme und Terminologie eine Kontextschicht, auf die Agenten bei jedem Durchlauf zugreifen. Je mehr Sie in diese Schicht investieren, desto weniger Überprüfung Ihre Ausgabe benötigt.

## Unveränderliche Versionierung

Das Sprachgedächtnis ist append-only. Wenn Sie Ihre Stimme oder Terminologie aktualisieren, erstellt Glossia eine neue Version anstatt die alte zu überschreiben. Jede Version erfasst, wer sie erstellt hat, wann, sowie eine optionale Änderungsnotiz, die erläutert, was sich entwickelt hat.

Dies bedeutet, Sie verfügen stets über ein vollständiges Änderungsprotokoll. Sie können Version 3 mit Version 7 vergleichen, um zu verstehen, wie sich Ihr Tonfall im Laufe eines Quartals verschoben hat. Falls eine aktuelle Änderung Inkonsistenzen eingeführt hat, rollen Sie auf eine frühere Version zurück und machen Sie weiter.

Die Versionierung macht die Zusammenarbeit sicherer. Mehrere Teammitglieder können Änderungen an Ihrer Stimme vorschlagen, ohne sich um Konflikte zu sorgen, da jede Änderung ein diskretes, nachvollziehbares Ereignis darstellt.

## Lokalsensitive Auflösung

Wenn ein Agent einen Workflow für eine bestimmte Lokalisierung ausführt, ermittelt Glossia das Sprachgedächtnis für diesen Kontext. Es beginnt mit Ihren Basis-Stimmeinstellungen und wendet dann beliebige lokalspezifische Überschreibungen darüber an. Dasselbe gilt für Terminologie: Nur Einträge, die einen lokalisierten Begriff für die Ziel-Lokalisierung besitzen, werden berücksichtigt.

Dieser Auflösungsschritt bedeutet, dass Agenten stets mit dem relevantesten Kontext arbeiten. Sie müssen keine separaten Konfigurationen pro Sprache pflegen. Definieren Sie Ihre Standardeinstellungen einmal, überschreiben Sie dort, wo es zählt, und lassen Sie das Auflösungssystem den Rest erledigen.

## Verwenden Sie es überall

Das Sprachgedächtnis wurde für Lokalisierung entwickelt, ist aber nützlich überall dort, wo Sie Text erstellen. Da der Kontext über das [REST API](/features/rest-api) und der [MCP-Server](/features/mcp-server), können Sie es in Workflows jenseits der Lokalisierung integrieren:

**Marketing- und Social Content** -- Binden Sie die Stimme Ihrer Organisation in einen Content-Agenten ein, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landingpage-Texte entwirft. Terminologie sorgt für konsistente Markenterme, und die Stimmeneinstellungen stellen sicher, dass der Ton Ihrer Marke entspricht.

**Dokumentation** -- Integrieren Sie das Sprachgedächtnis in eine Dokumentations-Pipeline, sodass technisches Schreiben denselben Stilregeln folgt wie der Rest Ihrer Inhalte. Terminologie-Einträge verhindern Abdrift über Dokumente, Hilfeartikel und in-Produkt-Texte hinweg.

**Codeüberprüfung** -- Erstellen Sie einen Agenten, der Pull-Request-Texte (Fehlermeldungen, UI-Labels, Onboarding-Text) mit Ihrer Stimme und Terminologie vergleicht. Markieren Sie Inkonsistenzen, bevor sie veröffentlicht werden.

**Benutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann das Sprachgedächtnis lesen und schreiben. Bitten Sie Ihren Code-Assistenten, "die Terminologie mit dem neuen Produktnamen aktualisieren" oder "den Stimmenton auf professionell für die deutsche Lokale einstellen" und es übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Stufenweise Verfeinerung

\-- Das Sprachgedächtnis verbessert sich durch Nutzung. Jedes Mal, wenn ein Prüfer die Ausgabe eines Agenten korrigiert, wird diese Korrektur in die nächste Version Ihrer Stimme oder Terminologie rückgekoppelt. Im Laufe der Zeit schließt sich die Lücke zwischen dem ersten Entwurf und der Endausgabe, und der Prüf-Schritt beschleunigt sich.

Dies ist die Feedbackschleife im Kern von Glossia: generieren, prüfen, Kontext verfeinern, erneut generieren. Die Agenten folgen nicht nur Anweisungen. Sie arbeiten mit Kontext, der sich in jedem Zyklus verbessert.
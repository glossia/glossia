%{
  title: "Sprachgedächtnis",
  summary:
    "Eine versionierte Kontextschicht, die Stimme, Terminologie und Stil Ihrer Organisation einfängt. Sprachgedächtnis leitet jeden Agenten-Workflow und erweitert sich über die API und MCP auf Ihre eigenen Tools.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und überprüfbar",
      description:
        "Jede Änderung Ihrer Stimme oder Terminologie erstellt eine neue unveränderbare Version. Sie können die Historie überprüfen, Iterationen vergleichen und zurücksetzen, wenn sich etwas verschiebt.",
      icon: "git-branch"
    },
    %{
      title: "Jenseits der Lokalisierung",
      description:
        "Sprachgedächtnis ist nicht nur für die Lokalisierung. Verwenden Sie es zum Generieren von Marketingtexten, Entwurf von Dokumentationen, Prüfung von Pull Requests oder Erstellen von Social-Media-Posts, alles in der Stimme Ihrer Organisation.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Greifen Sie über die REST-API oder den MCP-Server auf das Sprachgedächtnis zu. Leiten Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierten Agenten ein, um die Konsistenz überall beim Schreiben aufrechtzuerhalten.",
      icon: "puzzle"
    }
  ]
}
---
## Was ist Sprachgedächtnis?

Sprachgedächtnis ist der angesammelte Kontext, der den Glossia-Agenten zeigt, wie sich Ihre Organisation verständigt. Es besteht aus zwei Kernprinzipien, die Sie im Laufe der Zeit erstellen und verfeinern:

**Stimme** definiert, wie Inhalte klingen sollen. Tonfall, Formalität, Zielgruppe und freie Richtlinien finden sich hier. Sie können eine Grundstimme für Ihr Konto festlegen und dann bestimmte Felder für einzelne Lokale überschreiben, damit Ihre japanischen Texte formeller sein können, während Ihr Englisch unterhaltend bleibt.

**Terminologie** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollen. Jeder Eintrag enthält eine Definition und Übersetzungen pro Lokalisierung. Wenn ein Agent auf "workspace" im Quellinhalt trifft, sagt die Terminologie ihm, ob es lokalisiert, transliteriert oder unverändert belassen werden soll, und genau welches Wort in jeder Zielsprache verwendet werden soll.

Zusammen bilden Stimme und Terminologie eine Kontextschicht, die Agenten bei jedem Durchlauf konsultieren. Je mehr Sie in diese Schicht investieren, desto weniger Überprüfung Ihrer Ausgabe benötigt wird.

## Unveränderliche Versionierung

Der Sprachspeicher ist ausschließlich zum Anfügen vorgesehen. Wenn Sie Ihre Stimme oder Terminologie aktualisieren, erstellt Glossia eine neue Version, statt die alte zu überschreiben. Jede Version dokumentiert, wer sie erstellt, wann und enthält eine optionale Änderungsnotiz, die erläutert, was sich entwickelt hat.

Dadurch verfügen Sie stets über einen vollständigen Prüfpfad. Sie können Version 3 gegen Version 7 vergleichen, um zu verstehen, wie sich Ihr Tonfall über ein Quartal verschoben hat. Falls eine jüngere Änderung Inkonsistenzen eingeführt hat, rollen Sie zu einer früheren Version zurück und setzen Sie einfach fort.

Versionierung macht die Zusammenarbeit auch sicherer. Mehrere Teammitglieder können Stimmanpassungen vorschlagen, ohne sich um Konflikte zu kümmern, da jede Änderung ein diskretes und nachverfolgbares Ereignis ist.

## Lokalisierungsbewusste Auflösung

Wenn ein Agent einen Workflow für eine bestimmte Lokalisierung ausführt, bestimmt Glossia den Sprachspeicher für diesen Kontext. Es beginnt mit Ihren Basis-Stimmeinstellungen und wendet dann alle lokalspezifischen Überschreibungen darüber an. Dasselbe gilt für Terminologie: Nur Einträge, die einen lokalisierten Begriff für die Ziellokalisation enthalten, werden aufgenommen.

Dieser Auflösungsschritt bedeutet, dass Agenten stets mit dem relevantesten Kontext arbeiten. Sie müssen keine separaten Konfigurationen pro Sprache pflegen. Definieren Sie Ihre Standards einmal, überschreiben Sie wo es wichtig ist und überlassen Sie das Auflösungssystem den Rest.

## Nutzen Sie es überall

Der Sprachspeicher wurde für die Lokalisierung entwickelt, ist aber nützlich überall, wo Sie Texte produzieren. Weil der Kontext über das zugänglich ist. [REST API](/features/rest-api) und den [MCP-Server](/features/mcp-server), können Sie es in Workflows jenseits der Lokalisierung integrieren:

**Marketing- und Social-Media-Inhalte** -- Importieren Sie die Stimmmuster Ihrer Organisation in einen Content-Agenten, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landing-Page-Inhalte erstellt. Terminologie gewährleistet konsistente Markenbegriffe, und die Stimmeinstellungen sorgen dafür, dass der Tonfall Ihrer Marke passt.

**Dokumentation** -- Einspeisen Sie den Sprachaufnahmen-Speicher in eine Dokumentations-Pipeline, damit technische Texte dieselben Stilregeln einhalten wie der Rest Ihrer Inhalte. Terminologie-Einträge verhindern Abweichungen über Dokumente, Hilfeartikel und in-Produkt-Texte.

**Code-Review** -- Erstellen Sie einen Agenten, der Pull-Request-Inhalte (Fehlermeldungen, UI-Labels, Einrichtungs-Text) auf Ihrer Stimme und Terminologie hin prüft. Kennzeichnen Sie Inkonsistenzen, bevor sie veröffentlicht werden.

**Benutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann den Sprachspeicher lesen und schreiben. Bitten Sie Ihren Coding-Assistenten, "die Terminologie mit dem neuen Produktnamen aktualisieren" oder "den Stimmton auf professionell für das deutsche Locale einstellen" und er übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Progressive Verfeinerung

\-- Der Sprachspeicher verbessert sich mit der Nutzung. Jedes Mal, wenn ein Reviewer die Ausgabe eines Agenten korrigiert, fließt diese Korrektur in die nächste Version Ihrer Stimme oder Terminologie ein. Im Laufe der Zeit verengt sich die Lücke zwischen dem ersten Entwurf und der endgültigen Ausgabe, und der Überprüfungsschritt wird schneller.

Dies ist die Feedback-Schleife im Kern von Glossia: generieren, überprüfen, Kontext verfeinern, erneut generieren. Die Agenten folgen nicht nur Anweisungen. Sie arbeiten mit dem Kontext, der sich in jedem Zyklus verbessert.
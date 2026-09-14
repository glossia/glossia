%{
  title: "Sprachspeicher",
  summary:
    "Eine versionierte Kontextschicht, die Stimme, Terminologie und Stil Ihrer Organisation einfängt. Sprachspeicher leitet jeden Workflow und erweitert sich über die API und MCP zu Ihren eigenen Tools.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Starten",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und überprüfbar",
      description:
        "Jede Änderung an Ihrer Stimme oder Terminologie erstellt eine neue unveränderliche Version. Sie können die Historie überprüfen, Iterationen vergleichen und zurückrollen, wenn sich etwas ändert.",
      icon: "git-branch"
    },
    %{
      title: "Über die Lokalisierung hinaus",
      description:
        "Sprachspeicher dient nicht nur der Lokalisierung. Nutzen Sie es für Marketingtexte, Dokumentationen, Pull Requests oder Social Posts, alles in der Stimme Ihrer Organisation.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Greifen Sie über die REST-API oder den MCP-Server auf Sprachspeicher zu. Integrieren Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierten Agenten, um überall, wo Sie schreiben, Konsistenz zu erhalten.",
      icon: "puzzle"
    }
  ]
}
---
## Was ist Sprachgedächtnis?

Sprachgedächtnis ist der angesammelte Kontext, der den Agenten von Glossia mitteilt, wie Ihre Organisation kommuniziert. Es besteht aus zwei Kernbausteinen, die Sie im Laufe der Zeit erstellen und verfeinern:

**Stimme** definiert, wie sich Inhalte anhören sollen. Ton, Formalität, Zielgruppe und Richtlinien im freien Format finden sich allesamt hier. Sie können eine Basisstimme für Ihr Konto festlegen und dann spezifische Felder für einzelne Lokale überschreiben, sodass Ihre japanischen Inhalte formeller sein können, während Ihre englischen Inhalte eher gesprächig bleiben.

**Terminologie** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollten. Jeder Eintrag enthält eine Definition und Übersetzungen pro Lokale. Wenn ein Agent "workspace" in Ihrem Quellinhalt findet, weist die Terminologie an, ob dies zu übersetzen, translitterieren oder unverändert lassen ist, und genau welches Wort in jeder Zielsprache zu verwenden ist.

Zusammen bilden Stimme und Terminologie eine Kontextebene, auf die Agenten bei jeder Ausführung zurückgreifen. Je mehr Sie in diese Ebene investieren, desto weniger Überprüfung benötigt Ihre Ausgabe.

## Unveränderliche Versionierung

Der Sprachspeicher ist append-only. Wenn Sie Ihre Stimme oder Terminologie aktualisieren, erstellt Glossia eine neue Version, statt die alte zu überschreiben. Jede Version protokolliert, wer sie erstellt hat, wann und eine optionale Änderungsnotiz, die erklärt, was sich entwickelt hat.

Das bedeutet, Sie verfügen stets über einen vollständigen Audit Trail. Sie können Version 3 mit Version 7 vergleichen, um zu verstehen, wie sich Ihr Tonfall über ein Quartal verschoben hat. Wenn eine kürzliche Änderung Inkonsistenzen eingeführt hat, rollen Sie auf eine frühere Version zurück und setzen Sie fort.

Versionsverwaltung macht Zusammenarbeit sicherer. Mehrere Teammitglieder können Änderungen an der Stimme vorschlagen, ohne sich um Konflikte zu sorgen, da jede Änderung ein diskretes, nachvollziehbares Ereignis ist.

## Lokalsensible Auflösung

Wenn ein Agent einen Workflow für ein bestimmtes Lokale ausführt, stellt Glossia den Sprachspeicher für diesen Kontext her. Sie beginnen mit Ihren Basis-Stimmeneinstellungen und wenden dann beliebige lokalspezifische Überschreibungen darüber an. Das Gleiche gilt für Terminologie: Nur Einträge, die einen lokalisierten Begriff für das Zielfokale besitzen, werden einbezogen.

Dieser Auflösungs-Schritt bedeutet Agenten arbeiten immer mit dem relevantesten Kontext. Sie müssen keine separaten Konfigurationen pro Sprache pflegen. Definieren Sie Standards einmal, überschreiben Sie dort, wo es wichtig ist, und lassen Sie das Auflösungssystem den Rest übernehmen.

## Verwenden Sie es überall

Der Sprachspeicher wurde für Lokalisierung entworfen, ist aber nützlich, wo immer Sie Text produzieren. Da der Kontext durch das zugänglich ist [REST API](/features/rest-api) und den [MCP-Server](/features/mcp-server), können Sie es in Arbeitsabläufe jenseits der Lokalisierung integrieren:

**Marketing und Social-Media-Inhalte** -- Integrieren Sie die Stimme Ihrer Organisation in einen Inhalts-Agenten, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landingpage-Copy entwirft. Terminologie hält Markenbegriffe konsistent und die Stimmenteinstellungen gewährleisten, dass der Ton Ihrer Marke passt.

**Dokumentation** -- Leiten Sie Sprachkontext in eine Dokumentationspipeline ein, sodass technisches Schreiben denselben Stilregeln folgt wie der Rest Ihres Inhalts. Terminologieinträge verhindern Abweichungen über Dokumente, Hilfeartikel und Produkt-Copy.

**Code-Review** -- Erstellen Sie einen Agenten, der Pull-Request-Inhalte (Fehlermeldungen, UI-Labels, Onboarding-Text) nach Ihrer Stimme und Terminologie prüft. Kennzeichnen Sie Inkonsistenzen, bevor sie veröffentlicht werden.

**Benutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann den Sprachspeicher lesen und schreiben. Fragen Sie Ihren Programmierungs-Assistenten, "die Terminologie mit dem neuen Produktnamen aktualisieren" oder "den Stimmton für das deutsche Locale auf professionell setzen", und er übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Progressive Verfeinerung

\-- Der Sprachspeicher verbessert sich durch Nutzung. Jedes Mal, wenn ein Prüfer die Ausgabe eines Agenten korrigiert, fließt diese Korrektur in die nächste Version Ihrer Stimme oder Terminologie zurück. Im Laufe der Zeit verengt sich die Lücke zwischen dem ersten Entwurf und der Finalausgabe, und der Überprüfungsschritt wird schneller.

Dies ist die Feedbackschleife im Kern von Glossia: generieren, überprüfen, Kontext verfeinern, erneut generieren. Die Agenten folgen nicht nur Anweisungen. Sie arbeiten mit einem Kontext, der sich in jedem Zyklus verbessert.
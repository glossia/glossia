%{
  title: "Sprachgedächtnis",
  summary:
    "Eine versionierte Kontextschicht, die Ihre Unternehmensstimme, Ihren Glossar und Ihren Stil erfasst. Sprachgedächtnis leitet jeden Agenten-Workflow und erstreckt sich über die API und MCP auf Ihre eigenen Tools.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und überprüfbar",
      description:
        "Jede Änderung an Ihrer Unternehmensstimme oder Ihrem Glossar erstellt eine neue unveränderliche Version. Sie können den Verlauf überprüfen, Iterationen vergleichen und bei Abweichungen Rollback durchführen.",
      icon: "git-branch"
    },
    %{
      title: "Über die Lokalisierung hinaus",
      description:
        "Sprachgedächtnis dient nicht nur der Lokalisierung. Nutzen Sie es, um Marketingtexte zu generieren, Dokumentation zu entwickeln, Pull-Requests zu überprüfen oder Social-Media-Beiträge zu verfassen, alles in Ihrer Unternehmensstimme.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Greifen Sie über die REST API oder den MCP-Server auf das Sprachgedächtnis zu. Leiten Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierten Agenten ein, um die Konsistenz überall, wo Sie schreiben, aufrechtzuerhalten.",
      icon: "puzzle"
    }
  ]
}
---
## Was ist Sprachgedächtnis?

Sprachgedächtnis ist der angesammelte Kontext, der den Agenten von Glossia zeigt, wie Ihre Organisation kommuniziert. Es besteht aus zwei Kernbausteinen, die Sie im Laufe der Zeit erstellen und verfeinern:

**Stimme** definiert, wie Inhalte klingen sollen. Tonfall, Formalität, Zielgruppe und Richtlinien für freies Format finden sich hier. Sie können eine Basis-Stimme für Ihr Konto festlegen und dann bestimmte Felder für einzelne Lokale überschreiben, sodass Ihre japanischen Inhalte formeller sein können, während Ihr Englisch im Gesprächston bleibt.

**Glossar** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollen. Jeder Eintrag enthält eine Definition und Übersetzungen für jedes Lokale. Wenn ein Agent den Begriff "workspace" in Ihrem Quellinhalt findet, gibt das Glossar vor, ob er lokalisiert, translitteriert oder unverändert belassen werden soll und genau welches Wort in jeder Zielsprache verwendet werden muss.

Zusammen bilden Stimme und Glossar eine Kontextschicht, die Agenten bei jedem Durchlauf konsultieren. Je mehr Sie in diese Schicht investieren, desto weniger Überprüfung ist für Ihre Ausgabe nötig.

## Unveränderliche Versionierung

Der Sprachspeicher ist nicht überschreibend. Wenn Sie Ihre Stimme oder das Glossar aktualisieren, erstellt Glossia eine neue Version anstelle der alten Version zu überschreiben. Jede Version dokumentiert, wer sie erstellt hat, wann und eine optionale Änderungsnotiz, die erläutert, welche Änderungen sich entwickelt haben.

Das bedeutet, dass Sie stets einen vollständigen Auditpfad haben. Sie können Version 3 mit Version 7 vergleichen, um zu verstehen, wie sich Ihr Tonfall über ein Quartal verschoben hat. Wenn eine jüngere Änderung Inkonsistenzen eingeführt hat, können Sie zurück zu einer früheren Version setzen und fortfahren.

Die Versionierung macht die Zusammenarbeit auch sicherer. Mehrere Teammitglieder können Stimmanpassungen vorschlagen, ohne sich um Konflikte sorgen zu müssen, da jede Änderung ein eigenständiges, nachverfolgbares Ereignis ist.

## Lokalisierungsbewusste Auflösung

Wenn ein Agent einen Workflow für eine bestimmte Sprache ausführt, löst Glossia den Sprachspeicher für diesen Kontext auf. Es beginnt mit Ihren Basis-Stimmeinstellungen und wendet dann alle sprachspezifischen Überschreibungen an. Das Gleiche gilt für das Glossar: nur Einträge, die einen lokalisierten Begriff für die Zielsprache haben, werden enthalten.

Dieser Auflösungsschritt bedeutet, dass Agenten stets mit dem relevantesten Kontext arbeiten. Sie müssen keine separaten Konfigurationen pro Sprache pflegen. Definieren Sie Ihre Standards einmal, überschreiben Sie dort, wo es zählt, und lassen Sie das Auilösungssystem den Rest übernehmen.

## Nutzen Sie es überall

Der Sprachspeicher wurde für die Lokalisierung konzipiert, ist aber nützlich, wo immer Sie Text erstellen. Weil der Kontext über das zugänglich ist. [REST API](/features/rest-api) und den [MCP-Server](/features/mcp-server), können Sie ihn in Workflows jenseits der Lokalisierung integrieren:

**Marketing und Social Content** -- Binden Sie die Stimme Ihrer Organisation in einen Content-Agenten ein, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landing-Page-Texte erstellt. Das Glossar hält Markenbegriffe konsistent und die Stimmeinstellungen stellen sicher, dass der Ton Ihrer Marke entspricht.

**Dokumentation** -- Füttern Sie das Sprachgedächtnis in eine Dokumentation-Pipeline, so dass technisches Schreiben dieselben Stilregeln wie den Rest Ihrer Inhalte befolgt. Glossareinträge verhindern Abweichungen über Dokumente, Hilfeartikel und In-Produkt-Texte.

**Code Review** -- Stellen Sie einen Agenten vor, der Pull-Request-Texte (Fehlermeldungen, UI-Labels, Onboarding-Text) auf Konsistenz mit Ihrer Stimme und Ihrem Wörterbuch prüft. Kennzeichnen Sie Inkonsistenzen, bevor sie veröffentlicht werden.

**Benutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann das Sprachgedächtnis lesen und schreiben. Fragen Sie Ihren Programmierungsassistenten an, "das Wörterbuch mit dem neuen Produktnamen aktualisieren" oder "den Tonfall auf professionell für das deutsche Locale setzen" und es übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Progressive Verfeinerung

Das Sprachgedächtnis verbessert sich durch Nutzung. Jede Korrektur, die ein Reviewer an einer Ausgabe des Agenten vornimmt, fließt in die nächste Version Ihrer Stimme oder Ihres Wörterbuchs zurück. Mit der Zeit schnürt sich der Abstand zwischen dem ersten Entwurf und der Endausgabe, und der Überprüfungsschritt wird schneller.

Dies ist der Feedback-Loop im Kern von Glossia: Generieren, überprüfen, Kontext verfeinern, erneut generieren. Die Agenten verfolgen nicht nur Anweisungen. Sie arbeiten mit Kontext, der in jedem Zyklus besser wird.
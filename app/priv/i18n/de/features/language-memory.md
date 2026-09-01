%{
  title: "Sprachspeicher",
  summary:
    "Eine versionierte Kontextschicht, die Stimme, Terminologie und Stil Ihrer Organisation erfasst. Sprachspeicher leitet jeden Agenten-Workflow und erweitert sich auf Ihre eigenen Tools über die API und MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und überprüfbar",
      description:
        "Jede Änderung Ihrer Stimme oder Terminologie erzeugt eine neue unveränderliche Version. Sie können den Verlauf einsehen, Iterationen vergleichen und zurückrollen, wenn Abweichungen eintreten.",
      icon: "git-branch"
    },
    %{
      title: "Jenseits der Lokalisierung",
      description:
        "Sprachspeicher dient nicht nur der Lokalisierung. Verwenden Sie es für Marketingtexte, Entwurf von Dokumentation, Prüfung von Pull-Requests oder Social-Media-Beiträge, alles in der Stimme Ihrer Organisation.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Greifen Sie auf den Sprachspeicher über die REST-API oder den MCP-Server zu. Leiten Sie ihn in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierten Agenten ein, um die Konsistenz überall aufrechtzuerhalten, wo Sie schreiben.",
      icon: "puzzle"
    }
  ]
}
---
## Was ist der Sprachspeicher?

Der Sprachspeicher ist der angesammelte Kontext, der Sonnen der Agenten von Glossia erklärt, wie sich Ihre Organisation kommuniziert. Er besteht aus zwei Grundelementen, die Sie mit der Zeit erstellen und verfeinern:

**Stimme** definiert, wie Inhalte klingen sollten. Ton, Formalität, Zielgruppe und freitextorientierte Richtlinien werden hier gespeichert. Sie können eine Basisstimme für Ihr Konto festlegen und dann spezifische Felder für einzelne Lokalisierungen überschreiben, sodass Ihr japanischer Text formeller sein kann, während Ihre englischen Inhalte im Konversationston bleiben.

**Terminologie** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollen. Jeder Eintrag trägt eine Definition und lokalspezifische Übersetzungen. Wenn ein Agent das Wort "Arbeitsbereich" in Ihrem Quellinhalt findet, weist die Terminologie ihm an, ob er dies zu lokalisieren, zu transliteralieren oder unberührt zu lassen, und genau welches Wort in jeder Zielsprache verwendet werden soll.

Gemeinsam bilden Stimme und Terminologie eine Kontextschicht, die die Agenten bei jedem Lauf konsultieren. Je mehr Sie in diese Schicht investieren, desto weniger Überprüfung Ihr Output braucht.

## Unveränderbare Versionierung

Der Sprachspeicher ist append-only. Wenn Sie Ihre Stimme oder Terminologie aktualisieren, erstellt Glossia eine neue Version anstelle des Überschreibens der alten. Jede Version erfasst, wer sie erstellt hat, wann, und eine optionale Änderungsnotiz, die erklärt, was sich geändert hat.

Das bedeutet, Sie haben immer eine vollständige Prüfspur. Sie können Version 3 gegen Version 7 vergleichen, um zu verstehen, wie sich Ihr Ton über ein Quartal hinweg verschoben hat. Wenn eine recente Änderung Inkonsistenzen eingeführt hat, rollen Sie zurück auf eine frühere Version und setzen Sie fort.

Versionierung macht Kollaboration auch sicherer. Mehrere Teammitglieder können Stimmenänderungen vorschlagen, ohne sich um Konflikte zu kümmern, da jede Änderung ein diskreteres, nachvollziehbares Ereignis ist.

## Lokalsensitive Auflösung

Wenn ein Agent einen Workflow für eine bestimmte Lokalisierung ausführt, löst Glossia den Sprachspeicher für diesen Kontext auf. Es beginnt mit Ihren Basisstimme-Einstellungen und wendet dann Überschreibungen spezifisch für diese Lokalisierung darüber an. Das Gleiche gilt für die Terminologie: Nur Einträge, die einen lokalisierten Begriff für die Zielsprache haben, werden berücksichtigt.

Dieser Auflösungsschritt bedeutet, dass Agenten immer mit dem relevantesten Kontext arbeiten. Sie müssen keine separaten Konfigurationen pro Sprache aufrechterhalten. Definieren Sie Ihre Standards nur einmal, überschreiben Sie sie dort, wo es zählt, und lassen Sie das Auflösungssystem den Rest erledigen.

## Nutzen Sie es überall

Der Sprachspeicher wurde für die Lokalisierung entwickelt, aber er ist nützlich überall, wo Sie Text erstellen. Da der Kontext über den [REST API](/features/rest-api) und den [MCP server](/features/mcp-server) zugänglich ist, können Sie ihn in Workflows integrieren, die über die Lokalisierung hinausgehen:

**Marketing- und soziale Inhalte** - Ziehen Sie die Stimme Ihrer Organisation in einen Content-Agenten ein, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landingpage-Texte entwirft. Terminologie sorgt für konsistente Markenterme, und die Stimmeinstellungen stellen sicher, dass der Ton Ihrer Marke entspricht.

**Dokumentation** - Leiten Sie den Sprachspeicher in eine Dokumentations-Pipeline ein, sodass technisches Schreiben denselben Stilregeln folgt wie der Rest Ihrer Inhalte. Terminologie-Einträge verhindern Drift über Dokumente, Hilfeseiten und im-Produkt-Texte hinweg.

**Code-Review** - Erstellen Sie einen Agenten, der Pull-Request-Inhalte (Fehlermeldungen, UI-Labels, Onboarding-Text) gegen Ihre Stimme und Terminologie prüft. Markieren Sie Inkonsistenzen, bevor sie ausgeliefert werden.

**Benutzerdefinierte Agenten** - Jeder MCP-kompatible Client kann den Sprachspeicher lesen und schreiben. Fragen Sie Ihren Coding-Assistenten nach "Terminologie mit dem neuen Produktname aktualisieren" oder "Ton der Stimme auf professionell für die deutsche Lokalisierung setzen", und er übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Progressive Verfeinerung

Der Sprachspeicher verbessert sich mit der Nutzung. Jedes Mal, wenn ein Prüfer die Ausgabe eines Agenten korrigiert, fließt diese Korrektur in die nächste Version Ihrer Stimme oder Terminologie zurück. Mit der Zeit verengt sich die Lücke zwischen dem ersten Entwurf und der endgültigen Ausgabe, und die Prüfschritte werden schneller.

Dies ist die Feedbackschleife im Kern von Glossia: Generieren, überprüfen, Kontext verfeinern, erneut generieren. Die Agenten befolgen nicht nur Anweisungen. Sie arbeiten mit Kontext, der mit jedem Zyklus besser wird.
%{
  title: "Sprachgedächtnis",
  summary:
    "Eine versionierte Kontextschicht, die die Stimme, Terminologie und den Stil Ihrer Organisation erfasst. Sprachgedächtnis leitet jeden Agentenworkflow und erstreckt sich durch die API und MCP auf Ihre eigenen Tools.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Loslegen",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und überprüfbar",
      description:
        "Jede Änderung Ihrer Stimme oder Terminologie erstellt eine neue, unveränderliche Version. Sie können den Verlauf überprüfen, Iterationen vergleichen und zurückrollen, falls etwas davon abweicht.",
      icon: "git-branch"
    },
    %{
      title: "Mehr als Lokalisierung",
      description:
        "Sprachgedächtnis dient nicht nur der Lokalisierung. Verwenden Sie es, um Marketingtexte zu generieren, Dokumentation zu entwerfen, Pull Requests zu überprüfen oder Social-Media-Beiträge zu verfassen – alles in der Stimme Ihrer Organisation.",
      icon: "megaphone"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Nutzen Sie Sprachgedächtnis über die REST API oder den MCP-Server. Integrieren Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierte Agenten, um die Konsistenz überall aufrechtzuerhalten, wo Sie schreiben.",
      icon: "puzzle"
    }
  ]
}
---
## Was ist Sprachgedächtnis?

Sprachgedächtnis ist der angesammelte Kontext, der den Glossia-Agenten besagt, wie Ihre Organisation kommuniziert. Es besteht aus zwei Kernbausteinen, die Sie im Laufe der Zeit erstellen und verfeinern:

**Stimme** definiert, wie Inhalte klingen sollen. Tonfall, Formalität, Zielgruppe und freie Richtlinien finden sich hier. Sie können eine Basisstimme für Ihr Konto festlegen und dann spezifische Felder für einzelne Lokale überschreiben, sodass Ihre japanischen Inhalte formeller sein können, während Ihre englischen Inhalte im Gesprächston bleiben.

**Terminologie** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollen. Jeder Eintrag enthält eine Definition und Übersetzungen pro LOKALE. Wenn ein Agent "workspace" in Ihrem Quellinhalt findet, legt die Terminologie fest, ob lokalisiert, transliteriert oder unverändert zu lassen ist, und genau welches Wort in jeder Zielsprache verwendet wird.

Zusammen bilden Stimme und Terminologie eine Kontextschicht, die Agenten bei jedem Durchlauf konsultieren. Je mehr Sie in diese Schicht investieren, desto weniger Überprüfung Ihre Ausgabe benötigt.

## \[Unveränderliche Versionierung\]

Der Sprachspeicher ist schreibgeschützt. Wenn Sie Ihre Stimme oder Terminologie aktualisieren, erstellt Glossia eine neue Version anstatt die alte zu überschreiben. Jede Version erfasst, wer sie erstellt hat, wann und eine optionale Änderungsnote, die erläutert, was sich entwickelt hat.

Dies bedeutet, dass Sie immer eine vollständige Audithistorie haben. Sie können Version 3 gegen Version 7 vergleichen, um zu verstehen, wie Ihr Tonfall im Laufe eines Quartals sich verändert hat. Wenn eine aktuelle Änderung Inkonsistenzen eingeführt hat, rollen Sie auf eine frühere Version zurück und fahren Sie weiter.

Versionierung macht die Zusammenarbeit ebenfalls sicherer. Mehrere Teammitglieder können Änderungen der Stimme vorschlagen, ohne sich um Konflikte zu kümmern, da jede Änderung ein separates, nachverfolgbares Ereignis ist.

## Lokalisierungssensitive Auflösung

Wenn ein Agent einen Workflow für eine bestimmte Lokalisierung ausführt, ermittelt Glossia den Sprachspeicher für diesen Kontext. Es beginnt mit Ihren Basis-Stimmeinstellungen und wendet dann alle lokalspezifischen Überschreibungen darüber an. Gleiches gilt für Terminologie: Nur Einträge, die einen lokalisierten Begriff für die Ziellokalisierung besitzen, werden einbezogen.

Dieser Auflösungsschritt stellt sicher, dass Agenten stets mit dem relevantesten Kontext arbeiten. Sie müssen keine separaten Konfigurationen pro Sprache pflegen. Definieren Sie Ihre Standards einmal, überschreiben Sie, wo es zählt, und lassen Sie das Auflösungssystem den Rest erledigen.

## Nutzen Sie es überall

Der Sprachspeicher wurde für die Lokalisierung entwickelt, ist aber nützlich, wo immer Sie Text produzieren. Da der Kontext über das zugänglich ist [REST API](/features/rest-api) und der [MCP-Server](/features/mcp-server), können Sie es in Workflows jenseits der Lokalisierung integrieren:

**Marketing und Social Content** -- Integrieren Sie die Stimme Ihrer Organisation in einen Content-Agenten, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landing-Page-Text entwirft. Terminologie sorgt für konsistente Markenbegriffe, und die Stimmeinstellungen gewährleisten, dass der Ton Ihrer Marke passt.

**Dokumentation** -- Speisen Sie das Sprachgedächtnis in eine Dokumentationspipeline ein, damit technisches Schreiben denselben Stilregeln folgt wie der Rest Ihres Inhalts. Terminologie-Einträge verhindern Drift über Dokumente, Hilfeartikel und Produkttext hinaus.

**Code-Review** -- Baue einen Agenten, der Pull-Request-Inhalte (Fehlermeldungen, UI-Labels, Einrichtungs-Texte) auf deine Stimme und Terminologie überprüft. Markiere Inkonsistenzen, bevor sie veröffentlicht werden.

**Benutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann das Sprachgedächtnis lesen und schreiben. Befehle deinen Programmierassistenten, "die Terminologie mit dem neuen Produktnamen zu aktualisieren" oder "den Sprachton auf professionell für die deutsche Lokalisierung zu setzen" und er übersetzt deine Absicht in den richtigen API-Aufruf.

## Schrittweise Verfeinerung

Sprachgedächtnis verbessert sich durch Nutzung. Jedes Mal, wenn ein Reviewer eine Ausgabe eines Agents korrigiert, wird diese Korrektur in die nächste Version deiner Stimme oder Terminologie übernommen. Mit der Zeit verengt sich der Abstand zwischen Erstentwurf und Endausgabe, und der Prüfungsschritt wird schneller.

Dies ist der Feedback-Loop im Kern von Glossia: Generieren, überprüfen, Kontext verfeinern, erneut Generieren. Die Agenten folgen nicht nur Anweisungen. Sie arbeiten mit einem Kontext, der sich in jedem Zyklus verbessert.
%{
  title: "Sprachgedächtnis",
  summary:
    "Eine versionierte Kontextschicht, die Stimme, Glossar und Stil Ihres Unternehmens erfasst. Das Sprachgedächtnis leitet jeden Agenten-Arbeitsablauf und erweitert sich über die API und MCP auf Ihre eigenen Tools.",
  order: 5,
  icon: "Gehirn",
  hero_cta_text: "Jetzt starten",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versioniert und nachvollziehbar",
      description:
        "Jede Änderung Ihrer Stimme oder Ihres Glossars erstellt eine neue, unveränderliche Version. Sie können die Historie durchgehen, Iterationen vergleichen und zurückrollen, wenn etwas davon abdriftet.",
      icon: "git-Zweig"
    },
    %{
      title: "Jenseits der Lokalisierung",
      description:
        "Das Sprachgedächtnis dient nicht nur der Lokalisierung. Nutzen Sie es zur Generierung von Marketingtexten, zum Entwurf von Dokumentation, zur Prüfung von Pull-Requests oder zum Erstellen von Social-Media-Beiträgen, alles in der Stimme Ihres Unternehmens.",
      icon: "Megafon"
    },
    %{
      title: "Offen und erweiterbar",
      description:
        "Greifen Sie über die REST-API oder den MCP-Server auf das Sprachgedächtnis zu. Integrieren Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierte Agenten, um die Konsistenz überall zu wahren, wo Sie schreiben.",
      icon: "Puzzle"
    }
  ]
}
---

## Was ist Sprachgedächtnis?

Das Sprachgedächtnis ist der angesammelte Kontext, der den Agenten von Glossia sagt, wie Ihre Organisation kommuniziert. Es besteht aus zwei Kernbausteinen, die Sie im Laufe der Zeit erstellen und verfeinern:

**Stimme** definiert, wie der Inhalt klingen soll. Tonfall, Formalität, Zielgruppe und freie Richtlinien sind hier angesiedelt. Sie können eine Basis-Stimme für Ihr Konto festlegen und dann spezifische Felder für einzelne Lokale überschreiben, sodass Ihre japanischen Inhalte formeller sein können, während Ihr Englisch gesprächig bleibt.

**Glossar** definiert, was Begriffe bedeuten und wie sie zu lokalisieren sind. Jeder Eintrag enthält eine Definition und Übersetzungen für einzelne Lokale. Wenn ein Agent im Quellinhalt auf "workspace" stößt, teilt das Glossar ihm mit, ob lokalisiert, translitteriert oder unberührt lassen soll, und genau welches Wort in jeder Zielsprache zu verwenden ist.

Zusammen bilden Stimme und Glossar eine Kontextschicht, auf die sich Agenten bei jedem Lauf stützen. Je mehr Sie in diese Schicht investieren, desto weniger Überprüfung benötigt Ihre Ausgabe.

## Unveränderliche Versionierung

Das Sprachgedächtnis ist nur ergänzbar. Wenn Sie Ihre Stimme oder Ihr Glossar aktualisieren, erstellt Glossia eine neue Version statt die alte zu überschreiben. Jede Version dokumentiert, wer sie erstellt hat, wann und eine optionale Änderungsnotiz, die erklärt, was sich entwickelt hat.

Das bedeutet, Sie haben immer einen vollständigen Audit-Trail. Sie können Version 3 gegen Version 7 vergleichen, um zu verstehen, wie sich Ihr Ton über ein Quartal verschoben hat. Wenn eine aktuelle Änderung Inkonsistenzen eingeführt hat, rollen Sie zu einer früheren Version zurück und setzen Sie fort.

Versionierung macht Zusammenarbeit auch sicherer. Mehrere Teammitglieder können Stimmpervorschläge machen, ohne sich über Konflikte Gedanken zu machen, da jede Änderung ein diskretes, nachvollziehbares Ereignis ist.

## Lokalspezifische Auflösung

Wenn ein Agent einen Workflow für ein bestimmtes Lokal ausführt, löst Glossia das Sprachgedächtnis für diesen Kontext auf. Es beginnt mit Ihren Basis-Stimmeinstellungen und wendet dann lokale-spezifische Überschreibungen an. Dasselbe gilt für das Glossar: Nur Einträge, die einen lokalisierten Begriff für das Ziellokale haben, sind enthalten.

Dieser Auflösungsschritt bedeutet, dass Agenten immer den relevantesten Kontext nutzen. Sie müssen keine separaten Konfigurationen pro Sprache pflegen. Definieren Sie einmal Ihre Standards, überschreiben Sie dort, wo es zählt, und lassen Sie dem Auflösungssystem das Überbleibende überlassen.

## Überall einsetzen

Das Sprachgedächtnis wurde für Lokalisierung entworfen, aber es ist nützlich, wo immer Sie Text produzieren. Da der Kontext über die [REST-API](/features/rest-api) und den [MCP-Server](/features/mcp-server) zugänglich ist, können Sie es in Workflows jenseits der Lokalisierung integrieren:

**Marketing- und Social-Media-Inhalte** -- Fügen Sie die Stimme Ihrer Organisation in einen Inhaltsagenten ein, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landingpage-Texte erstellt. Das Glossar hält Markenbegriffe konsistent und die Stimmeinrichtung stellt sicher, dass der Ton Ihrer Marke entspricht.

**Dokumentation** -- Leiten Sie das Sprachgedächtnis in eine Dokumentations-Pipeline ein, damit technisches Schreiben denselben Stilregeln folgt wie der Rest Ihres Inhalts. Glossar-Einträge verhindern Drift über Dokumente, Hilfeartikel und In-Produkt-Kopie hinweg.

**Code-Review** -- Erstellen Sie einen Agenten, der Pull-Request-Texte (Fehlermeldungen, UI-Labels, Onboarding-Text) gegen Ihre Stimme und Ihr Glossar überprüft. Kennzeichnen Sie Inkonsistenzen, bevor sie versendet werden.

**Nutzerdefinierte Agenten** -- Jeder MCP-kompatible Client kann Sprachgedächtnis lesen und schreiben. Bitten Sie Ihren Code-Assistenten, "das Glossar mit dem neuen Produktnamen aktualisieren" oder "den Stimmtón für das deutsche Lokal auf professionell setzen", und er übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Progressive Verfeinerung

Das Sprachgedächtnis verbessert sich mit der Nutzung. Jedes Mal, wenn ein Reviewer eine Ausgabe eines Agenten korrigiert, fließt diese Korrektur in die nächste Version Ihrer Stimme oder Ihres Glossars zurück. Im Laufe der Zeit schließt sich die Lücke zwischen dem ersten Entwurf und der endgültigen Ausgabe, und der Überprüfungsschritt wird schneller.

Dies ist die Rückkopplungsschleife im Herzen von Glossia: generieren, überprüfen, Kontext verfeinern, erneut generieren. Die Agenten folgen nicht nur Anweisungen. Sie arbeiten mit Kontext, der mit jedem Zyklus besser wird.

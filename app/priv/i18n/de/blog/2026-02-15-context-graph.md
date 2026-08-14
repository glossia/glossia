%{
  title: "Der Kontextgraph: Kodifizierung jahrzehntelanger linguistischer Theorie für die Ära der Agenten",
  summary: "Sprachmodelle sind leistungsstark, benötigen jedoch den passenden Kontext, um erstklassige Inhalte zu generieren. Wir entwickeln einen versionierten, gerichteten Graphen, um linguistisches Wissen zu erfassen und mit Agenten zu teilen, und wir sind überzeugt, dass sich Glossia dadurch abheben wird.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Ich habe viel darüber nachgedacht, was den Unterschied ausmacht zwischen Inhalten, die maschinengeneriert klingen, und Inhalten, bei denen man das Gefühl hat, sie wurden von jemandem geschrieben, der die Zielgruppe, die Marke und die kulturellen Nuancen hinter jedem Wort versteht. Die Antwort läuft immer wieder auf dasselbe hinaus: **Kontext**.

Sprachmodelle werden immer besser im Umgang mit Sprachen, und wir setzen darauf, dass sich dieser Trend fortsetzt. Sie sind noch nicht ganz am Ziel, aber das Tempo der Verbesserung ist schwer zu ignorieren. Was jedoch noch fehlt, ist das System, das zwischen dem Modell und den Inhalten sitzt. Das Element, das dem Modell mitteilt, *wer* Sie sind, *wie* Sie sprechen, *worauf* es in diesem speziellen Satz ankommt und *warum* dieser Satz überhaupt existiert. Das ist das Problem, an dem wir bei Glossia arbeiten, und ich halte es derzeit für das interessanteste in diesem Bereich.

## Drei Elemente, zwei davon kontrollieren wir

Wenn ich mir ansehe, was nötig ist, um einen wirklich neuen Ansatz für einsprachige und mehrsprachige Inhalte zu ermöglichen, sehe ich drei Elemente:

1. **Modelle, die gut mit Sprachen umgehen können.** Sie sind noch nicht ganz so weit, aber sie verbessern sich schnell, und wir setzen auf diesen Trend. Wir müssen kein Basismodell entwickeln. Wir müssen bereit sein, sie effektiv zu nutzen, sobald sie so weit sind.
2. **Ein System zur Modellierung und Bereitstellung des Kontexts, den Agenten benötigen.** Dies ist das Bindeglied zwischen dem Modell und dem Inhalt. Die Ebene, die Ihre Stimme, Ihre Terminologie, Ihren Tonfall sowie die Erwartungen Ihrer Zielgruppe erfasst und all dies dem Agenten strukturiert bereitstellt.
3. **Der Kontext, der von den Nutzern stammt.** Menschen bringen Urteilsvermögen, kulturelles Bewusstsein und kreative Führung ein. Kein System kann das vollständig ersetzen. Aber ein System kann es erleichtern, dies zu erfassen und wiederzuverwenden.

Von diesen dreien kontrollieren wir zwei: das System selbst und die Art und Weise, wie wir Nutzer anleiten, Kontext beizutragen und uns dabei zu helfen, das System zu verbessern. Wir sind überzeugt, dass der richtige Umgang mit beiden Aspekten Glossia in einem Markt hervorheben wird, der sich schnell mit einfachen „Schließ-einfach-ein-LLM-an“-Lösungen füllt. Im System müssen wir jahrzehntelange linguistische Theorie in die primitiven Strukturen codieren, die sich in der agentischen Welt herausbilden. Und die Benutzererfahrung darum herum stellt sicher, dass der richtige Kontext tatsächlich erfasst, verfeinert und in den Kreislauf zurückgeführt wird.

Eugene Nida, einer der Begründer der modernen Übersetzungswissenschaft, argumentierte, dass es bei einer guten Übersetzung nicht um eine Wort-für-Wort-Entsprechung geht. Sein Konzept der [dynamischen Äquivalenz](https://en.wikipedia.org/wiki/Dynamic_equivalence) besagt, dass sich die Beziehung zwischen der Zielgruppe und der übersetzten Botschaft genauso anfühlen sollte wie die Beziehung zwischen dem ursprünglichen Publikum und der Quelle. Das ist ein schöner Gedanke, er erfordert jedoch ein tiefes Verständnis des Kontexts: wer liest, welchen kulturellen Rahmen die Leser mitbringen und welcher Tonfall im Original beabsichtigt war. Genau diese Dinge müssen an einem Ort hinterlegt sein, auf den ein Modell zugreifen kann.

## Was wir erfassen müssen und wie

Eines der ersten Themen, die wir untersucht haben, ist die Frage, welche Informationen erfasst werden müssen und wie diese strukturiert sein sollten, damit Agenten sie tatsächlich nutzen können. Je mehr wir darüber nachdachten, desto klarer wurde uns, dass es sich dabei nicht um eine flache Konfigurationsdatei oder eine Einstellungsseite handeln konnte. Es musste ein Graph sein. Genauer gesagt, ein **[gerichteter azyklischer Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Warum ein DAG? Weil **Kontext nicht flach ist**. Die Stimme Ihrer Marke beeinflusst Ihre Terminologie. Ihre Terminologie prägt, wie Sie über bestimmte Funktionen schreiben. Die Erwartungen Ihrer Zielgruppe bestimmen den Grad der Formalität, was wiederum die Wortwahl beeinflusst. Diese Beziehungen haben eine Richtung und eine Hierarchie, und sie weisen keine Schleifen auf.

Hierfür existieren bereits bewährte Ansätze. Wissensgraphen werden seit Jahren in KI-Systemen eingesetzt, um strukturierte Beziehungen zwischen Konzepten darzustellen. In jüngerer Zeit haben [Kontextgraphen](https://grokipedia.com/page/context-graph) diese Idee durch das Hinzufügen dynamischer Kontextschichten erweitert. Dies ist genau das, was Agenten benötigen, um fundierte Entscheidungen zu treffen. Und in der Multi-Agenten-Welt [haben sich DAGs als grundlegendes Muster etabliert](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780), um Aufgabenabhängigkeiten und den Informationsfluss zu modellieren.

Doch das ist der Punkt, der mich besonders begeistert: **Jeder Knoten in diesem Graphen muss versioniert sein**. Wenn Sie Ihre Markenstimme ändern, dürfen Sie den Zugriff auf die vorherige Version nicht verlieren. Wenn Sie einen Terminologie-Eintrag aktualisieren, muss das System wissen, welche Inhalte unter der alten Definition erstellt wurden und welche Teile möglicherweise überprüft werden müssen. Auf diese Weise können wir den agentenbasierten Workflow so optimieren, dass er nur für die Teile ausgelöst wird, die tatsächlich von einer Änderung betroffen sind, anstatt alles neu zu verarbeiten.

## Bidirektional konzipiert

Wir sind davon überzeugt, dass die Beziehung zwischen Kontextknoten und Inhalten gerichtet sein und in beide Richtungen funktionieren muss.

Aus der einen Perspektive betrachtet: Sie müssen wissen, wie Inhalte mit dem Kontext verknüpft sind. Wenn sich ein Teil des Kontexts ändert (beispielsweise wenn sich Ihre Markenstimme hin zu einem lockereren Ton verändert), welche Blogbeiträge, Produktbeschreibungen oder Hilfeartikel wurden dann unter der vorherigen Version verfasst? Dies sind die Inhalte, die überarbeitet oder neu übersetzt werden müssen. Dies ist die **Vorwärtsrichtung, vom Kontext zum Inhalt**.

Aus der anderen Perspektive: Wenn ein Linguist einen Inhalt betrachtet und sich fragt, warum eine bestimmte Entscheidung getroffen wurde, muss er diese auf den Kontext zurückführen können, der die Entscheidung geleitet hat. Welche Definition der Stimme war aktiv? Welche Terminologieregel wurde angewendet? Diese **Rückverfolgbarkeit** ermöglicht es Menschen zu verstehen, was die Agenten getan haben, und darauf basierend souverän weitere Iterationen vorzunehmen.

Die NASA bezeichnet dies als [bidirektionale Rückverfolgbarkeit](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): die Fähigkeit, einer Verknüpfung zwischen Entitäten in beide Richtungen zu folgen. Es ist ein Prinzip aus dem Systems Engineering, und es stellt sich heraus, dass es genau das ist, was Sie benötigen, um eine Feedback-Schleife zwischen linguistischem Kontext und generiertem Inhalt zu erstellen.

Diese bidirektionale Eigenschaft ist es, die eine **progressive Verfeinerung** ermöglicht. Ein Linguist kann einen Inhalt überprüfen, den Kontext einsehen, der ihn geprägt hat, entscheiden, dass die Definition der Stimme angepasst werden muss, und diese Anpassung vornehmen. Das System weiß dann genau, welche anderen Inhalte von dieser Änderung betroffen sind. Es ist ein enger Kreislauf, der zutiefst menschlich ist.

## Über ein einzelnes Repository hinaus

Dieser Graph weist eine weitere Dimension auf, die ich besonders interessant finde: **Er kann nicht in einem einzelnen Repository existieren.** Der Kontextgraph muss über Projekte und potenziell auch über Organisationen hinweg gemeinsam nutzbar sein.

Bedenken Sie Folgendes: Ein Unternehmen hat eine Markenstimme. Diese Stimme gilt für jedes Produkt, jede Website und jeden Support-Artikel. Sie existiert nicht in einem einzigen Repository. Es handelt sich um ein Querschnittsthema. Sie können Ihre Kernstimme auf Organisationsebene definieren und dann auf Projektebene Überschreibungen für ein bestimmtes Produkt oder eine bestimmte Zielgruppe anwenden. Dies ist die **Vererbung von Gültigkeitsbereichen** (Scope Inheritance). Es handelt sich um dasselbe Muster, das wir aus der Programmierung kennen, hier jedoch auf den linguistischen Kontext angewendet.

Zudem muss dieser Kontext ordnungsgemäß versioniert werden. Sie können nicht einfach die Definition der Stimme ändern und die vorherige Version verwerfen. Wir können viel davon lernen, wie [Git die Versionierung handhabt](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) mittels inhaltsadressierbarem Speicher (Content-Addressable Storage) und DAGs. Bei Gits Modell aus Commits, Branches und Diffs geht es im Kern darum, Änderungen im Zeitverlauf nachzuverfolgen und gleichzeitig den Zugriff auf jeden vorherigen Zustand zu erhalten. Genau das benötigen wir für den linguistischen Kontext.

Tatsächlich sind wir der Meinung, dass eine Änderung der Stimme über ein Verfahren erfolgen sollte, das wir als *Stimmenänderungsanfrage* bezeichnen. Ähnlich wie ein Pull-Request Raum für Diskussionen über Codeänderungen bietet, schafft eine Stimmenänderungsanfrage Raum für die Erörterung linguistischer Änderungen. Warum wechseln wir zu einem konversationelleren Ton? Welche Auswirkungen wird das haben? Welche Inhalte sind davon betroffen? Dies sind Gespräche, die es sich zu führen lohnt, bevor die Änderung übertragen wird.

## Wo Menschen kreativer werden und nicht an Relevanz verlieren

Und an dieser Stelle wird es besonders interessant. Anstatt den Menschen überflüssig zu machen, wie es ein von vielen im Zusammenhang mit KI verbreitetes Narrativ nahelegt, **weist dieses System dem Menschen eine kreativere Rolle zu**.

Stellen Sie sich ein Team von Linguisten und Content-Strategen vor, die in einer Sitzung Ideen über die sprachliche Ausrichtung der Marke diskutieren. Sie könnten Konzepte explorieren, über tonale Verschiebungen debattieren und sich auf kulturelle Kontexte beziehen, zu denen kein Modell Zugang hat. Und anstatt dann Hunderte von Dateien manuell zu aktualisieren, erfassen sie ihre Entscheidungen als Anpassungen am Kontextgraphen. Das System übernimmt die Übertragung.

Oder gehen Sie noch einen Schritt weiter: Stellen Sie sich agentenbasierte Sitzungen vor, in denen ein Linguist mit einem KI-Assistenten zusammenarbeitet, um linguistische Ideen zu explorieren. „Was wäre, wenn wir die Fehlermeldungen empathischer gestalten würden?“ Der Agent simuliert die Auswirkungen, zeigt auf, wie sich der aktuelle Kontext ändern würde, und liefert eine Vorschau darauf, wie die aktualisierten Inhalte aussehen könnten. Der Linguist verfeinert und passt an, und reicht, sobald er zufrieden ist, eine Kontextänderungsanfrage ein. Wäre das nicht bemerkenswert?

**Hierbei geht es nicht darum, den Linguisten zu ersetzen.** Es geht darum, ihnen bessere Werkzeuge an die Hand zu geben, um das zu tun, worin sie bereits hervorragend sind: nuancierte, kulturell fundierte Entscheidungen über Sprache zu treffen. Das System übernimmt die mechanischen Aufgaben (Übertragung, Auswirkungsanalyse, Konsistenz), während sich der Mensch auf die kreativen Aspekte konzentriert (Stimme, Tonfall, kulturelle Resonanz).

Ich muss immer wieder daran denken, worauf Nida mit der dynamischen Äquivalenz hinauswollte. Das Ziel ist keine linguistische Genauigkeit im mechanischen Sinne. Es geht darum, die gleiche gefühlte Beziehung zwischen Leser und Inhalt herzustellen, unabhängig von der Sprache. Das erfordert Geschmack, Urteilsvermögen und kulturelles Bewusstsein. Eigenschaften, in denen Menschen bemerkenswert gut sind und mit denen Modelle nach wie vor Schwierigkeiten haben. Die Aufgabe des Systems besteht darin, sicherzustellen, dass diese menschlichen Erkenntnisse erfasst, strukturiert und wiederverwendbar gemacht werden.

## Wie es weitergeht

In einem folgenden Beitrag werden wir technischer werden und über die Rolle sprechen, die Sandboxes bei der Ermöglichung von Erfahrungen spielen werden, die es in diesem Bereich so noch nicht gegeben hat, und warum wir stark in APIs investieren. Es gibt eine ganz eigene Dimension rund um das Staging, die Vorschau und das Testen von linguistischen Änderungen vor ihrer Veröffentlichung, die wir unbedingt näher beleuchten wollen.

Wenn Sie sich davon angesprochen fühlen, sei es als Linguist, der von den aktuellen Werkzeugen frustriert ist, als Entwickler, der mit Lokalisierungs-Workflows kämpft, oder einfach als jemand, der intensiv über die Schnittstelle von Sprache und Technologie nachdenkt: Wir würden uns freuen, von Ihnen zu hören.
%{
  title: "Der Kontextgraph: Codifizierung von jahrzehntelanger Sprachtheorie für die Agenten-Ära",
  summary:
    "Sprachmodelle sind leistungsstark, benötigen aber den richtigen Kontext, um großartige Inhalte zu erstellen. Wir entwerfen einen versionierten, gerichteten Graphen, um linguistisches Wissen zu erfassen und es mit Agenten zu teilen, und wir glauben, dass dies genau das ist, was Glossia hervorstechen wird.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Ich habe viel darüber nachgedacht, was den Unterschied ausmacht zwischen Inhalten, die maschinell generiert klingen, und solchen, die sich so anfühlen, als würden sie von jemandem verfasst, der die Zielgruppe, die Marke und die kulturellen Nuancen hinter jedem Wort versteht. Die Antwort führt immer wieder aufs Gleiche zurück: **Kontext**.

Sprachmodelle werden in Bezug auf Sprachen besser, und wir setzen darauf, dass sich dieser Trend fortsetzt. Sie sind noch nicht vollständig da, aber das Tempo der Verbesserung ist schwer zu ignorieren. Was jedoch noch fehlt, ist das System, das sich zwischen Modell und Inhalt befindet. Das, was dem Modell sagt, *wer* du bist, *wie* du sprichst, *was* in diesem speziellen Satz zählt, und *warum* dieser Satz überhaupt existiert. Das ist das Problem, an dem wir bei Glossia arbeiten, und ich denke, es ist das interessanteste im Bereich gerade.

## Drei Elemente, zwei steuern wir

Wenn ich ansehe, was nötig ist, um einen wirklich neuen Ansatz für einsprachigen und mehrsprachigen Inhalt zu ermöglichen, sehe ich drei Elemente:

1. **Modelle, die gut mit Sprachen umgehen.** Sie sind noch nicht vollständig da, verbessern sich aber schnell, und wir setzen auf diesen Trend. Wir müssen kein Basismodell aufbauen. Wir müssen bereit sein, sie gut zu nutzen, sobald sie verfügbar sind.
2. **Ein System zum Modellieren und Teilen des Kontexts, den Agenten benötigen.** Dies ist das Element zwischen dem Modell und dem Inhalt. Die Schicht, die Ihre Stimme, Ihre Terminologie, Ihren Ton, Ihre Erwartungshaltungen Ihres Zielpublikums einfängt und dies alles strukturiert dem Agenten zur Verfügung stellt.
3. **Der Kontext, der von Benutzern stammt.** Menschen bringen Urteilsvermögen, kulturelles Bewusstsein und kreative Richtung mit. Kein System kann das vollständig ersetzen. Aber ein System kann es erleichtern, das einzufangen und wiederverwenden zu können.

Von diesen drei Punkten kontrollieren wir zwei: das System selbst und die Art und Weise, wie wir Benutzer anleiten, Kontext beizutragen und uns dabei zu helfen, das System zu verbessern. Wir glauben, dass das Richtige bei beiden ist, was Glossia in einem Umfeld abheben lässt, das sich schnell mit "just plug in an LLM"-Lösungen füllt. Das System ist der Ort, an dem wir Jahrzehnte der linguistischen Theorie in die grundlegenden Bausteine übersetzen, die in der Agentenwelt entstehen. Und die Benutzererfahrung darum ist der Mechanismus, mit dem wir sicherstellen, dass der richtige Kontext tatsächlich erfasst, verfeinert und in den Kreis zurückgeführt wird.

Eugene Nida, einer der Gründer moderner Übersetzungsstudien, argumentierte, dass gute Übersetzung nicht um Wort-für-Wort-Korrespondenz geht. Sein Konzept der [dynamischen Äquivalenz](https://en.wikipedia.org/wiki/Dynamic_equivalence) sagt, dass die Beziehung zwischen dem Zielpublikum und der übersetzten Botschaft sich so anfühlen sollte, wie die Beziehung zwischen dem ursprünglichen Publikum und der Quelle. Das ist eine schöne Idee, aber es erfordert tiefgreifendes kontextuelles Verständnis: Wer liest, welches kulturelle Rahmen sie mitbringen, welchen Ton das Original anstrebte. Das sind genau die Dinge, die irgendwo gespeichert sein müssen, worauf ein Modell zugreifen kann.

## Was wir erfassen müssen und wie

Eines der ersten Dinge, die wir bereits erforscht haben, ist, welche Informationen erfasst werden müssen und wie sie strukturiert werden sollen, damit Agenten sie tatsächlich nutzen können. Je mehr wir darüber nachdachten, desto mehr erkannten wir, dass dies keine flache Konfigurationsdatei oder eine Einstellungenseite war. Es musste ein Graph sein. Spezifisch, ein **[gerichteter azyklischer Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Warum ein DAG? Weil **Kontext ist nicht flach**. Deine Markenstimme beeinflusst deine Terminologie. Deine Terminologie prägt, wie du über spezifische Funktionen schreibst. Die Erwartungen deiner Zielgruppe bestimmen den Formalitätsgrad, der wiederum die Wortwahl beeinflusst. Diese Beziehungen haben Richtung und Hierarchie, und sie laufen nicht in sich selbst zurück.

Hier gibt es bereits Vorarbeiten. Wissensgraphen werden seit Jahren in KI-Systemen verwendet, um strukturierte Beziehungen zwischen Konzepten darzustellen. In jüngerer Zeit, [Kontextgraphen](https://grokipedia.com/page/context-graph) haben dieses Konzept erweitert, indem sie dynamische Kontextschichten hinzufügen, genau das, was Agenten für informierte Entscheidungen benötigen. Und in der multi-agentigen Welt, [DAGs sind zu einem fundamentalen Muster geworden](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) für die Modellierung von Aufgabenabhängigkeiten und Informationsfluss.

Aber hier ist der Teil, der mich begeistert: **jeder Knoten in diesem Graph muss versioniert werden**. Wenn Sie Ihre Markenstimme ändern, sollten Sie den Zugriff auf die vorherige Version nicht verlieren. Wenn Sie einen Terminologie-Eintrag aktualisieren, sollte das System wissen, welcher Inhalt unter der alten Definition erstellt wurde und welche Teile möglicherweise erneut betrachtet werden müssen. Dies ermöglicht es uns, den Agenten-Workflow so zu optimieren, dass er nur die Elemente aktiviert, die tatsächlich von einer Änderung betroffen sind, statt alles erneut zu verarbeiten.

## Bidirektional von Haus aus

Wir glauben, dass die Beziehung zwischen Kontextknoten und Inhalt gerichtet sein muss und in beide Richtungen funktionieren muss.

Auf der einen Seite: Sie müssen wissen, wie Inhalte mit dem Kontext verbunden sind. Wenn sich ein Kontext ändert (beispielsweise, wenn sich Ihre Markenstimme lockerer verhält), welche Blogbeiträge, Produktbeschreibungen oder Hilfeartikel wurden unter der vorherigen Version erstellt? Diese sind die, die überprüft oder neu übersetzt werden müssen. Dies ist die **Vorwärtsrichtung, vom Kontext zum Inhalt**.

Auf der anderen Seite: Wenn ein Linguist einen Inhalt betrachtet und sich fragt, warum eine bestimmte Entscheidung getroffen wurde, sollte er zurückverfolgen können, welcher Kontext die Entscheidung leitete. Welche Stimmdefinition war aktiv? Welche Terminologie-Regel galt? Dies **Rückwärtsverfolgbarkeit** ist, was es Menschen ermöglicht zu verstehen, was die Agenten getan haben, und mit Zuversicht daran zu iterieren.

NASA nennt dies [bidirektionale Rückverfolgbarkeit](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): die Fähigkeit, eine Assoziation zwischen Entitäten in beide Richtungen nachzuvollziehen. Es ist ein Prinzip aus der Systemtechnik und stellt sich als genau das heraus, was Sie benötigen, wenn Sie versuchen, eine Rückkopplungsschleife zwischen linguistischem Kontext und generiertem Inhalt zu erstellen.

Diese bidirektionale Qualität ist das, was **fortschreitende Verfeinerung** möglich. Ein Linguist kann einen Inhalt begutachten, den Kontext erkennen, der ihn geformt hat, entscheiden, dass die Stimmdefinition angepasst werden muss, und diese Anpassung vornehmen. Das System weiß dann genau, welcher andere Inhalt durch diese Änderung betroffen ist. Es ist eine enge Schleife und es ist dabei sehr menschlich.

## Jenseits eines einzelnen Repositories

Es gibt eine andere Dimension in diesem Graphen, die ich besonders interessant finde. **Es kann nicht in einem einzigen Repository leben.** Der Kontextgraph muss zwischen Projekten und potenziell zwischen Organisationen teilbar sein.

Denken Sie darüber nach: Eine Firma hat eine Markenstimme. Diese Stimme gilt für jedes Produkt, jede Website, jeden Supportartikel. Sie lebt nicht in einem Repository. Es ist ein Querthema. Sie könnten Ihre Kernstimme auf Organisationsebene definieren und dann Überschreibungen auf Projektebene für ein bestimmtes Produkt oder Publikum anwenden. Dies ist **Scope Vererbung**, das gleiche Muster, dem wir in der Programmierung gewohnt sind, aber auf linguistischen Kontext angewendet.

Und dieser Kontext muss ordnungsgemäß versioniert werden. Sie können die Stimmen-Definition nicht einfach ändern und die vorherige Version löschen. Hier gibt es viel zu lernen, wie [Git verwaltet die Versionierung](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) , durch content-addressable storage und DAGs. Git-Modell der Commits, Zweige und Diffs basiert grundsätzlich darauf, wie sich Dinge im Laufe der Zeit ändern, während der Zugriff auf jeden früheren Zustand erhalten bleibt. Genau das benötigen wir für linguistischen Kontext.

Tatsächlich glauben wir, dass eine Sprachveränderung über etwas stattfinden sollte, das wir einen *Sprachveränderungsantrag*. Genau wie ein Pull Request einen Raum für Diskussionen um Codeänderungen schafft, schafft ein Sprachveränderungsantrag einen Raum, um linguistische Änderungen zu besprechen. Warum wechseln wir zu einem gesprächigeren Ton? Welche Auswirkungen hat das? Welche Inhalte werden betroffen sein? Dies sind Gespräche, die sich lohnen, bevor sich die Änderung durchsetzt.

## Wo Menschen kreativer werden, nicht weniger relevant

Und genau hier beginnen die Dinge wirklich interessant zu werden. Anstatt Menschen zu eliminieren, was die Erzählung ist, die viele Menschen vortragen, wenn sie über KI sprechen, übernimmt dieses System **gibt Menschen eine kreativere Rolle**.

Stellen Sie sich ein Team von Linguisten und Content-Strategen vor, die in einer Sitzung Ideen zur sprachlichen Ausrichtung der Marke diskutieren. Sie können Konzepte erforschen, Tonverschiebungen debattieren, kulturellen Kontext verweisen, dem kein Modell Zugriff hat; und statt Hunderte von Dateien manuell zu aktualisieren, erfassen sie ihre Entscheidungen als Anpassungen am Kontextgraphen. Das System kümmert sich um die Propagation.

Oder gehen Sie einen Schritt weiter: Stellen Sie sich agentische Sitzungen vor, in denen ein Übersetzer mit einem KI-Assistenten linguistische Ideen erkundet. "Was, wenn wir die Fehlermeldungen empathischer gestalten würden?" Der Agent simuliert die Auswirkungen, zeigt, wie sich der aktuelle Kontext verändern würde, und erstellt eine Vorschau, wie der aktualisierte Inhalt aussehen könnte. Der Übersetzer verfeinert und passt an, und wenn er zufrieden ist, reicht er eine Änderungsanfrage für den Kontext ein. Wäre das nicht etwas Besonderes?

**Es geht nicht darum, den Übersetzer zu ersetzen.** Es geht darum, ihnen bessere Tools zu geben, um das zu tun, was ihnen bereits sehr gut gelingt: differenzierte, kulturbewusste Entscheidungen über Sprache zu treffen. Das System übernimmt den mechanischen Teil (Propagation, Auswirkungsanalyse, Konsistenz), während sich Menschen auf den kreativen Teil konzentrieren (Stimme, Tonfall, kulturelle Resonanz).

Ich laufe immer wieder darauf zurück, was Nida mit der dynamischen Äquivalenz meinte. Ziel ist keine sprachliche Genauigkeit im mechanischen Sinne. Es geht darum, zwischen Leser und Inhalt unabhängig von der Sprache das gleiche Gefühl zu erzeugen. Dafür sind Geschmack, Urteilskraft und kulturelles Bewusstsein notwendig. Dinge, die Menschen hervorragend beherrschen, bei denen KI-Modelle jedoch noch an Grenzen stoßen. Die Aufgabe des Systems ist es, sicherzustellen, dass diese menschlichen Erkenntnisse erfasst, strukturiert und wiederverwendbar sind.

## Was kommt als Nächstes

In einem Folgebeitrag werden wir technischer und darüber sprechen, welche Rolle Testumgebungen spielen werden, um Erfahrungen zu ermöglichen, die in diesem Bereich noch nicht zuvor gesehen wurden, und warum wir massiv in APIs investieren. Es gibt eine ganze Dimension rund um Staging, Vorschau und Testen linguistischer Änderungen, bevor diese live gehen, in die wir gerne tiefer einsteigen möchten.

Wenn dies bei Ihnen Widerhall findet, ob Sie nun ein Übersetzer sind, der mit den aktuellen Tools frustriert ist, ein Entwickler, der bei Lokalisierungsworkflows Schwierigkeiten hatte, oder einfach jemand, der tief darüber nachdenkt, wie Sprache und Technologie zusammentreffen, freuen wir uns, von Ihnen zu hören.
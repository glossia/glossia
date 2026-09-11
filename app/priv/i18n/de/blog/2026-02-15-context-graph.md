%{
  title: "Der Kontextgraph: Kodifizierung jahrzehntelanger Sprachtheorie für die Ära der Agenten",
  summary:
    "Sprachmodelle sind leistungsstark, benötigen aber den richtigen Kontext, um großartige Inhalte zu erstellen. Wir entwerfen einen versionierten, gerichteten Graphen, um linguistisches Wissen zu erfassen und mit Agenten zu teilen, und wir sind der Überzeugung, dass dies der Grund sein wird, warum Glossia hervorsticht.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
ICH habe viel darüber nachgedacht, was den Unterschied macht zwischen Inhalten, die maschinell generiert klingen, und solchen, die sich wie von jemandem geschrieben anfühlen, der das Publikum, die Marke und die kulturellen Nuancen hinter jedem Wort versteht. Die Antwort führt immer wieder auf dasselbe zurück: **Kontext**.

Sprachmodelle werden in Sprachen besser, und wir setzen darauf, dass sich dieser Trend fortsetzt. Sie sind noch nicht vollständig da, aber die Geschwindigkeit der Verbesserung ist schwer zu ignorieren. Was dennoch noch fehlt, ist das System, das zwischen dem Modell und dem Inhalt sitzt. Die Sache, die dem Modell sagt *wer* du bist, *wie* du sprichst, *was* in diesem bestimmten Satz zählt, und *warum* dass dieser Satz überhaupt existiert. Das ist das Problem, an dem wir bei Glossia arbeiten, und ich denke, es ist das interessanteste gerade in der Branche.

## Drei Elemente, zwei kontrollieren wir selbst

Wenn ich betrachte, was nötig ist, um einen wirklich neuen Ansatz für mono-sprachigen und mehrsprachigen Inhalt zu ermöglichen, sehe ich drei Elemente:

1. **Modelle, die Sprachen gut beherrschen.** Sie sind noch nicht vollständig da, aber sie verbessern sich schnell, und wir setzen auf diesen Trend. Wir müssen kein Grundlagenmodell selbst bauen. Wir müssen bereit sein, sie gut zu nutzen, wenn sie verfügbar sind.
2. **Ein System, um den Kontext zu modellieren und zu teilen, den Agenten benötigen.** Dies ist der Baustein, der zwischen Modell und Inhalt vermittelt. Die Schicht, die deine Stimme, deine Terminologie, deinen Ton, die Erwartungen deiner Zielgruppe einfängt und all das strukturiert dem Agenten zur Verfügung stellt.
3. **Der Kontext, der von Nutzern stammt.** Menschen bringen Urteilsvermögen, kulturelles Bewusstsein und kreative Leitlinien. Kein System kann dies vollständig ersetzen. Doch ein System kann die Erfassung und Wiederverwendung erleichtern.

Von diesen drei dominieren zwei: das System selbst und wie wir Nutzer anleiten, Kontext beizusteuern und uns bei der Weiterentwicklung zu helfen. Wir glauben, dass das Verknüpfen beider Aspekte es sein wird, was Glossia in einem Umfeld auszeichnet, das sich schnell mit Lösungen füllt, die behaupten: "schließe einfach ein LLM ein". Das System ist der Bereich, in dem wir Jahrzehnte linguistischer Theorie in die Primitiven kodifizieren müssen, die sich in der Agenten-Welt durchsetzen. Und das Nutzererlebnis darum ist der Weg, wie wir sicherstellen, dass der richtige Kontext tatsächlich erfasst, verfeinert und zurück in den Kreis eingespeist wird.

Eugene Nida, einer der Gründungsväter des modernen Bereichs der Übersetzungswissenschaft, argumentierte, dass eine gute Übersetzung nicht auf einer Wort-für-Wort-Entsprechung basiert. Sein Konzept der [dynamische Äquivalenz](https://en.wikipedia.org/wiki/Dynamic_equivalence) behauptet, dass die Beziehung zwischen dem Zielpublikum und der übersetzten Botschaft so wirken sollte, wie die Beziehung zwischen dem Originalpublikum und der Quelle. Das ist eine schöne Idee, aber sie erfordert tiefes kontextuelles Verständnis: wer liest, welches kulturelle Gerüst sie mitbringt, welchen Ton das Original anvisierte? Genau diese Dinge müssen irgendwo existieren, wo ein Modell sie zugreifen kann.

## Was wir erfassen müssen, und wie

Eines der ersten Dinge, die wir untersucht haben, ist, welche Informationen erfasst werden müssen, und wie diese strukturiert werden sollen, damit Agenten sie tatsächlich nutzen können. Je mehr wir darüber nachdachten, desto mehr wurde uns klar, dass dies kein flaches Konfigurationsfile oder eine Einstellungen-Seite war. Es bedurfte eines Graphen. Konkret einen **[gerichteten azyklischen Graphen](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**,.

Warum ein DAG? Weil **Kontext ist nicht flach**. Ihre Markenstimme beeinflusst Ihre Terminologie. Ihre Terminologie gestaltet, wie Sie sich über bestimmte Funktionen äußern. Ihre Zielgruppenwartung informiert über das Formalitätsniveau, was wiederum die Wortwahl beeinflusst. Diese Beziehungen weisen Richtung und Hierarchie auf und laufen nicht auf sich selbst zurück.

Hier gibt es bereits Vorarbeiten. Wissensgraphen werden seit Jahren in KI-Systemen genutzt, um strukturierte Beziehungen zwischen Konzepten darzustellen. Kürzlich, [Kontextgraphen](https://grokipedia.com/page/context-graph) haben diese Idee erweitert, indem sie dynamische Kontextschichten hinzufügen, genau das, was Agenten benötigen, um fundierte Entscheidungen zu treffen. Und in der Multi-Agenten-Welt, [DAGs sind zu einem grundlegenden Muster geworden](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) zur Modellierung von Aufgabenabhängigkeiten und Informationsfluss.

Aber hier ist der Teil, der mich begeistert: **jeder Knoten in diesem Graphen muss versioniert werden**. Wenn Sie Ihre Markenstimme ändern, sollten Sie nicht den Zugang zur vorherigen Version verlieren. Wenn Sie einen Terminologieeintrag aktualisieren, sollte das System wissen, welche Inhalte unter der alten Definition erstellt wurden und welche Teile möglicherweise erneut überprüft werden müssen. Dies ermöglicht uns, den Agenten-Workflow zu optimieren, sodass er nur für die Teile ausgelöst wird, die tatsächlich von einer Änderung betroffen sind, anstatt alles erneut zu verarbeiten.

## Bidirektional von Haus aus

Wir glauben, dass die Beziehung zwischen Kontextknoten und Inhalt eine Richtung haben muss und in beide Richtungen funktionieren muss.

Wenn man es von einer Seite ansieht: Man muss wissen, wie der Inhalt mit dem Kontext verbunden ist. Wenn sich ein Teil des Kontexts ändert (sagen wir, Ihre Markenstimme wird beinahe informeller), welche Blog-Beiträge, Produktbeschreibungen oder Hilfeartikel wurden unter der vorherigen Version erstellt? Das sind die, die überarbeitet oder neu übersetzt werden müssen. Dies ist die **Vorderichtung: vom Kontext zum Inhalt**.

Von der anderen Seite: Wenn ein Übersetzer einen Inhalt betrachtet und fragt, warum eine bestimmte Entscheidung getroffen wurde, sollte er sie dem Kontext zuordnen können, der sie leitete. Welche Stimmen-Definition war aktiv? Welche Terminologie-Regel galt? Diese **Rückverfolgbarkeit** ist das, was es Menschen ermöglicht zu verstehen, was die Agenten getan haben und mit Zuversicht daran zu iterieren.

NASA nennt dies [bidirektionale Nachverfolgbarkeit](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): die Fähigkeit, Assoziationen zwischen Entitäten in beide Richtungen nachzuvollziehen. Es ist ein Prinzip der Systemtechnik und stellt sich heraus, dass es genau das ist, was Sie brauchen, wenn Sie versuchen, eine Feedback-Schleife zwischen linguistischem Kontext und generiertem Inhalt zu erstellen.

Diese bidirektionale Qualität ist genau das, was macht **schrittweise Verfeinerung** möglich. Ein Linguist kann einen Inhalt überprüfen, den Kontext betrachten, der ihn geprägt hat, entscheiden, dass die Stimmdefinition angepasst werden muss und diese Anpassung erstellen. Das System weiß dann genau, welcher andere Inhalt davon betroffen ist. Es ist eine enge Schleife und ist tief menschlich.

## Jenseits eines einzelnen Repositoriums

Es gibt eine weitere Dimension an diesem Graphen, die ich besonders interessant finde. **Es kann nicht in einem einzigen Repository leben.** Der Kontextgraph muss über Projekte hinweg teilbar sein und potenziell über Organisationen.

Halten Sie nach: Ein Unternehmen hat eine Markenstimme. Diese Stimme gilt für jedes Produkt, jede Website, jeden Supportartikel. Sie lebt nicht in einem Repository. Es ist eine Querschnittsanfrage. Sie könnten Ihre Kernstimme auf Organisationsebene definieren, und dann Anpassungen auf Projektebene für ein bestimmtes Produkt oder Publikum anwenden. Das ist **Scope-Ererbung**, das gleiche Muster, an dem wir aus der Programmierung gewohnt sind, aber auf linguischen Kontext angewendet.

Und dieser Kontext muss ordnungsgemäß versioniert werden. Man kann die Stimmdefinition nicht einfach ändern und die vorherige Version löschen. Es gibt viel zu lernen, wie [Git übernimmt Versionierung](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) durch content-addressable storage und DAGs. Git's Modell von Commits, Branches und Diffs dreht sich grundlegend darum, zu verfolgen, wie sich Dinge im Zeitverlauf ändern, während der Zugriff auf jeden vorherigen Zustand erhalten bleibt. Genau das brauchen wir für linguischen Kontext.

Tatsächlich meinen wir, dass eine Änderung der Stimme über etwas geschehen sollte, das wir eine *Stimmenänderungsanfrage*. Ähnlich wie ein Pull-Request einen Raum für Diskussionen rund um Code-Änderungen schafft, schafft eine Stimmenänderungsanfrage einen Raum für die Diskussion linguistischer Änderungen. Warum wechseln wir zu einem konversationelleren Ton? Welche Auswirkungen werden dadurch entstehen? Welcher Inhalt wird davon betroffen sein? Das sind Gespräche, die es wert sind, bevor die Änderung propagiert.

## Wo Menschen kreativer werden, und nicht weniger relevant.

Und genau hier beginnen die Dinge wirklich interessant zu werden. Anstatt Menschen zu eliminieren, was eine Erzählung ist, die viele verbreiten, wenn es um KI geht, dieses System **gibt Menschen eine kreativere Rolle**.

Stellen Sie sich ein Team von Linguisten und Content-Strategen vor, das eine Sitzung hat, um Ideen zur sprachlichen Ausrichtung der Marke zu erörtern. Sie könnten Konzepte erforschen, Ton-Anderungen diskutieren, auf kulturellen Kontext verweisen, auf den kein Modell zugreifen kann. Und dann erfassen sie ihre Entscheidungen nicht durch manuelles Aktualisieren von hunderten Dateien, sondern als Anpassungen an den Kontextgraph. Das System kümmert sich um die Propagation.

Oder gehen wir einen Schritt weiter: Stellen Sie sich Sitzungen mit KI-Agenten vor, in denen eine Linguistin mit einem KI-Assistenten sprachliche Ideen untersucht. "Was wäre, wenn wir die Fehlermeldungen einfühlsamer gestalten würden?" Der Agent simuliert die Auswirkungen, zeigt, wie sich der aktuelle Kontext ändern würde, und vorschaut, wie der aktualisierte Inhalt aussehen könnte. Die Linguistin verfeinert, passt an und reicht, wenn sie zufrieden ist, einen Kontextänderungsantrag ein. Wäre das nicht schon etwas Besonderes?

**Es geht nicht darum, die Linguistin zu ersetzen.** Es geht darum, ihnen bessere Werkzeuge zu geben, damit sie das tun können, worin sie bereits hervorragend sind: differenzierte, kulturinformierte Entscheidungen über Sprache zu treffen. Das System übernimmt die mechanischen Teile (Propagation, Auswirkungsanalyse, Konsistenz), während sich Menschen auf die kreativen Bereiche (Stimme, Ton, kulturelle Resonanz) konzentrieren.

Ich komme immer wieder darauf zurück, worauf Nida mit der dynamischen Äquivalenz hinauswollte. Das Ziel ist keine linguistische Genauigkeit im mechanischen Sinne. Es geht darum, dieselbe gefühlte Beziehung zwischen Leser und Inhalt herzustellen, unabhängig von der Sprache. Das bedarf Geschmack, Urteilskraft und kulturellem Bewusstsein. Dinge, in denen Menschen außergewöhnlich gut sind und bei denen Modelle immer noch scheitern. Die Aufgabe des Systems besteht darin, sicherzustellen, dass diese menschlichen Erkenntnisse erfasst, strukturiert und wiederverwendbar sind.

## Was als Nächstes

In einem Folgebeitrag werden wir uns technisch vertiefen und darüber sprechen, welche Rolle Sandboxen dabei spielen, Erlebnisse zu ermöglichen, die in diesem Bereich noch nicht gesehen wurden, und warum wir stark in APIs investieren. Es gibt eine ganze Dimension rund um Staging, Vorschau und Testen linguistischer Änderungen live, bevor sie online gehen, die wir gerne genauer untersuchen.

Wenn das bei Ihnen Anklang findet, sei es als Linguist, der mit den aktuellen Werkzeugen unzufrieden ist, als Entwickler, der bei Lokalisierungsworkflows ins Wühlen gerät, oder einfach jemand, der tief darüber nachdenkt, wie Sprache und Technologie ineinandergreifen, würden wir uns freuen, von Ihnen zu hören.
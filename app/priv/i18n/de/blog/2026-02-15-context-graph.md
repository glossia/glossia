%{
  title:
    "Der Kontextgraph: Die Kodifizierung von Jahrzehnten linguistischer Theorie für die Ära der Agenten",
  summary:
    "Sprachmodelle sind leistungsfähig, benötigen aber den richtigen Kontext, um großartige Inhalte zu produzieren. Wir entwerfen einen versionierten, gerichteten Graphen, um linguistisches Wissen zu erfassen und mit Agenten zu teilen, und wir sind davon überzeugt, dass dies genau das ist, was Glossia besonders machen wird.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Ich habe viel darüber nachgedacht, was den Unterschied ausmacht zwischen Inhalten, die nach maschineller Generierung klingen, und Inhalten, die sich so anfühlen, als würden sie von jemandem verfasst, der das Publikum, die Marke und die kulturellen Nuancen hinter jedem Wort versteht. Die Antwort führt immer wieder zum selben Punkt zurück: **Kontext**.

Sprachmodelle werden bei Sprachen besser, und wir wetten darauf, dass diese Entwicklung anhält. Sie sind noch nicht vollständig da, aber das Tempo der Verbesserung ist schwer zu ignorieren. Was fehlt, ist jedoch das System zwischen dem Modell und dem Inhalt. Die Sache, die dem Modell sagt *wer* du bist, *wie* du sprichst, *was* das in diesem bestimmten Satz zählt, und *warum* dass dieser Satz überhaupt existiert. Das ist das Problem, an dem wir bei Glossia arbeiten, und ich denke, es ist das interessanteste in diesem Bereich derzeit.

## Drei Elemente, zwei kontrollieren wir

Wenn ich dto betrachte, was nötig ist, um einen wirklich neuen Ansatz für mono-lingualen und multi-lingualen Inhalt zu ermöglichen, erkenne ich drei Elemente:

1. **Modelle, die gut mit Sprachen umgehen.** Sie sind noch nicht ganz da, verbessern sich aber schnell, und wir wetten auf diesen Trend. Wir müssen kein Foundation Model bauen. Wir müssen bereit sein, sie gut zu nutzen, wenn sie so weit sind.
2. **Ein System, um den Kontext zu modellieren und zu teilen, den Agenten benötigen.** Dies ist das Stück, das zwischen Modell und Inhalt sitzt. Die Schicht, die Ihre Stimme, Ihre Terminologie, Ihren Ton und Ihre Erwartungen an die Zielgruppe einfängt und dies dem Agenten strukturiert bereitstellt.
3. **Der von Nutzern stammende Kontext.** Menschen bringen Urteilsvermögen, kulturelles Bewusstsein und kreative Ausrichtung ein. Kein System kann dies vollständig ersetzen. Aber ein System kann die Erfassung und Wiederverwendung erleichtern.

Von diesen drei gibt es zwei, die wir kontrollieren: das System selbst und die Art, wie wir Nutzer anleiten, Kontext beizutragen und uns bei der Verbesserung des Systems zu helfen. Wir glauben, dass es genau dabei besteht, beides zu meistern, was Glossia in einem sich schnell mit "just plug in an LLM"-Lösungen füllenden Bereich voraussagen lässt. Das System ist der Ort, an dem wir jahrzehntelange linguistische Theorie in die Grundbausteine kodifizieren müssen, die in der Welt der Agenten entstehen. Und die Nutzererfahrung darum herum ist der Mechanismus, um sicherzustellen, dass der richtige Kontext tatsächlich erfasst, verfeinert und in die Rückkopplungsschleife zurückgegeben wird.

Eugene Nida, einer der Väter moderner Übersetzungsforschung, argumentierte, dass gute Übersetzung nicht auf der Wort-für-Wort-Korrespondenz beruht. Sein Konzept des [dynamische Äquivalenz](https://en.wikipedia.org/wiki/Dynamic_equivalence) sagt, dass die Beziehung zwischen der Zielgruppe und der übersetzten Botschaft sich genauso anfühlen sollte wie die Beziehung zwischen dem ursprünglichen Publikum und der Quelle. Das ist eine schöne Idee, aber sie fordert ein tiefes kontextuelles Verständnis: wer liest, welchen kulturellen Rahmen sie einbringen, welchen Ton das Original verfolgte. Das sind genau jene Dinge, die an einem Ort sein müssen, von dem aus ein Modell darauf zugreifen kann.

## Was wir erfassen müssen und wie

Eine der ersten Dinge, die wir untersucht haben, ist das, was Informationen erfasst werden müssen und wie wir diese strukturieren müssen, damit Agenten sie tatsächlich nutzen können. Je mehr wir darüber nachgedacht haben, desto mehr haben wir festgestellt, dass es sich nicht um eine flache Konfigurationsdatei oder eine Einstellungsseite handeln muss. Es musste eine Graphik sein. Konkret, ein **[gerichteter azyklischer Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Warum ein DAG? Weil **Kontext ist nicht flach**Ihre Markenstimme beeinflusst Ihre Terminologie. Ihre Terminologie prägt, wie Sie sich über bestimmte Funktionen äußern. Die Erwartungen Ihres Publikums bestimmen den Formalitätsgrad, was wiederum die Wahl des Wortschatzes beeinflusst. Diese Beziehungen sind gerichtet und hierarchisch und liefern keine Schleifen.

Hier gibt es bereits Vorarbeiten. Wissensgraphen werden seit Jahren in KI-Systemen verwendet, um strukturierte Beziehungen zwischen Konzepten darzustellen. Kürzlich sind [Kontextgraphen](https://grokipedia.com/page/context-graph) diese Idee erweitert worden, indem dynamische Kontextschichten hinzugefügt werden, genau das, was Agenten benötigen, um fundierte Entscheidungen zu treffen. Und in der Welt mehrer Agenten sind [DAGs zu einem grundlegenden Muster geworden](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) zur Modellierung von Aufgabenabhängigkeiten und Informationsfluss.

Aber hier ist der Teil, der mich begeistert: **jeder Knoten in diesem Graphen muss versioniert werden.**Wenn Sie Ihre Markenstimme ändern, sollten Sie keinen Zugriff auf die vorherige Version verlieren. Wenn Sie einen Terminologieeintrag aktualisieren, sollte das System wissen, welche Inhalte unter der alten Definition erstellt wurden und welche Teile möglicherweise erneut geprüft werden müssen. Dies ermöglicht es uns, den agentischen Workflow so zu optimieren, dass er nur für die tatsächlich betroffenen Teile auslöst, statt alles erneut zu verarbeiten.

## Bidirektional konzipiert

Wir glauben, dass die Beziehung zwischen Kontextknoten und Inhalt gerichtet sein muss und in beiden Richtungen funktionieren muss.

Betrachtet man dies von einer Seite: Sie müssen wissen, wie Inhalte mit Kontext verbunden sind. Wenn ein Stück Kontext sich ändert (sagen wir, Ihre Markenstimme wird etwas lässiger), welche Blogposts, Produktbeschreibungen oder Hilfeartikel wurden unter der vorherigen Version erstellt? Das sind die, die überprüft oder neuübersetzt werden müssen. Dies ist das **Vorwärtsrichtung, vom Kontext zum Inhalt**.

Von der anderen Seite: Wenn ein Linguist:in einen Inhalt betrachtet und fragt, warum eine Entscheidung getroffen wurde, sollte sie zum gekörnten Kontext zurückverfolgen können. Welche Stimmendefinition war aktiv? Welche Terminologieregel galt? Dies **Rückwärtsverfolgbarkeit** ist es, was Menschen verstehen lässt, was die Agenten getan haben, und darauf mit Zuversicht iterieren können.

NASA nennt dies [bidirektionale Nachverfolgbarkeit](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): die Fähigkeit, eine Assoziation zwischen Entitäten in beide Richtungen zu verfolgen. Es ist ein Prinzip der Systemtechnik, und es stellt sich heraus, dass es genau das ist, was Sie benötigen, wenn Sie versuchen, eine Feedback-Schleife zwischen dem sprachlichen Kontext und dem generierten Inhalt zu erstellen.

Diese bidirektionale Eigenschaft macht **stufenweise Verfeinerung** möglich. Ein Linguist kann einen Inhalt prüfen, den Kontext sehen, der ihn geformt hat, entscheiden, dass die Stimmedefinition angepasst werden muss, und diese Anpassung vornehmen. Das System weiß dann genau, welche anderen Inhalte von der Änderung betroffen sind. Es ist ein enger Kreislauf, und es ist sehr menschlich.

## Jenseits eines einzelnen Repositories

Es gibt eine weitere Dimension an diesem Graphen, die ich besonders interessant finde. **Es kann nicht in einem einzigen Repository leben.** Der Kontextgraph muss über Projekte hinweg geteilt werden können und potenziell auch über Organisationen.

Denken Sie nach: Ein Unternehmen hat eine Markenstimme. Diese Stimme gilt für jedes Produkt, jede Website, jeden Support-Artikel. Sie lebt nicht in einem Repository. **Es ist ein querlaufender Aspekt. Sie können Ihre Kernstimme auf Organisationsebene definieren und dann Überschreibungen auf Projektebene für ein bestimmtes Produkt oder eine Zielgruppe anwenden. Das ist**Scope-Vererbung

, das gleiche Muster, an dem wir in der Programmierung gewohnt sind, aber auf linguistischen Kontext angewendet. [Und dieser Kontext muss ordnungsgemäß versioniert werden. Sie können die Stimmen-Definitionen nicht einfach ändern und die vorherige Version löschen. Es gibt viel zu lernen, wie](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) Git verwaltet Versionsierung durch inhaltadressierbare Speicherung und DAGs. Das Git-Modell mit Commits, Branchen und Diffs dient grundlegend dazu, Änderungen im Zeitverlauf zu verfolgen, während der Zugriff auf jeden früheren Zustand erhalten bleibt. Genau das brauchen wir für linguistischen Kontext.

In der Tat glauben wir, dass eine Stimmenänderung über etwas passieren sollte, das wir eine *Stimmenänderungsanfrage*. Ähnlich wie ein Pull-Request Raum für Diskussionen um Code-Änderungen schafft, schafft eine Stimmenänderungsanfrage Raum für Diskusionen um linguistische Änderungen. Warum wechseln wir zu einem gesprächigeren Ton? Welche Auswirkungen wird das haben? Welcher Inhalt wird betroffen sein? Diese sind Gespräche wert, die vor der Ausbreitung der Änderung geführt werden müssen.

## Wo Menschen kreativer werden, nicht weniger relevant

Und hier beginnen die Dinge wirklich interessant zu werden. **Anstatt Menschen zu eliminieren, was das Narrativ ist, das viele Menschen betonen, wenn sie über KI sprechen, dieses System**verleiht Menschen eine kreativere Rolle

.

Oder gehen Sie noch einen Schritt weiter: Stellen Sie sich agentenbasierte Sitzungen vor, in denen ein Linguist mit einem KI-Assistenten zusammenarbeitet, um sprachliche Ideen zu erkunden. "Was wäre, wenn wir die Fehlermeldungen empathischer gestalten würden?" Der Agent simuliert die Auswirkungen, zeigt, wie sich der aktuelle Kontext ändern würde und teilt mit, wie der aktualisierte Inhalt aussehen könnte. Der Linguist verfeinert, passt an und wenn er zufrieden ist, reicht er eine Kontextänderungsanfrage ein. Das wäre doch mal was.

**Es geht nicht darum, den Linguisten zu ersetzen.** Es geht darum, ihnen bessere Werkzeuge an die Hand zu geben, um das zu tun, worin sie ohnehin großartig sind: differenzierte, kulturgestützte Entscheidungen über Sprache. Das System übernimmt die mechanischen Teile (Propagation, Auswirkungsanalyse, Konsistenz), während sich Menschen auf die kreativen Teile (Stimme, Ton, kulturelle Resonanz) konzentrieren.

Ich komme immer wieder darauf zurück, worauf Nida mit der dynamischen Äquivalenz hinauswollte. Das Ziel ist keine sprachliche Genauigkeit im mechanischen Sinne. Es geht darum, die gleiche gefühlte Beziehung zwischen Leser und Inhalt zu schaffen, unabhängig von der Sprache. Das erfordert Geschmack, Urteilsvermögen und kulturelles Bewusstsein. Das sind Dinge, bei denen Menschen hervorragend sind, wohingegen Modelle noch immer damit kämpfen. Die Aufgabe des Systems ist es, sicherzustellen, dass diese menschlichen Erkenntnisse erfasst, strukturiert und wiederverwendbar gemacht werden.

## Was kommt als Nächstes

In einem Folgebeitrag werden wir technischer und besprechen, welche Rolle Sandboxen dabei spielen, Erlebnisse zu ermöglichen, die es in diesem Bereich noch nicht gab, und warum wir stark in APIs investieren. Es gibt ein ganzes Spektrum rund um Staging, Vorschau und Testen linguistischer Änderungen, bevor diese ins Live gehen, auf das wir gespannt sind und das wir gerne vertiefen möchten.

Wenn dies bei dir Anklang findet, egal ob du als Linguist frustriert von den aktuellen Werkzeugen bist, als Entwickler Schwierigkeiten mit Lokalisierungs-Workflows hast oder einfach jemand bist, der tief darüber nachdenkt, wie Sprache und Technologie sich überschneiden, freuen wir uns, von dir zu hören.
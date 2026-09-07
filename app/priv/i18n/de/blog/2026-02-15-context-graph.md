%{
  title: "Der Kontextgraph: Kodifizierung jahrzehntelanger Sprachtheorie für die agentische Ära",
  summary:
    "Sprachmodelle sind leistungsstark, doch sie benötigen den richtigen Kontext, um großartige Inhalte zu produzieren. Wir entwickeln einen versionierten, gerichteten Graphen, um linguistisches Wissen zu erfassen und mit Agenten zu teilen, und wir glauben, dass dies Glossia besonders machen wird.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Ich habe viel darüber nachgedacht, was den Unterschied ausmacht zwischen Inhalten, die nach maschinengeneriert klingen, und solchen, die sich so anfühlen, als hätte sie jemand geschrieben, der das Publikum, die Marke und die kulturellen Nuancen hinter jedem Wort versteht. Die Antwort kommt wiederholt auf das gleiche zurück: **Kontext**.

Sprachmodelle werden bei Sprachen besser, und wir setzen darauf, dass diese Entwicklung anhalten wird. Sie sind noch nicht ganz dort, aber das Tempo der Verbesserungen lässt sich kaum ignorieren. Was aber noch fehlt, ist das System, das zwischen dem Modell und dem Inhalt sitzt. Das Ding, das dem Modell sagt *wer* du bist, *wie* du sprichst, *was* in diesem besonderen Satz wichtig ist und *warum* dieser Satz überhaupt existiert. Das ist das Problem, an dem wir bei Glossia arbeiten, und ich denke, es ist das interessanteste im Bereich zu diesem Zeitpunkt.

## Drei Elemente, zwei unter unserer Kontrolle

Wenn ich mir ansehe, was benötigt wird, um einen wirklich neuen Ansatz für mono-lingualen und multi-lingualen Inhalt zu ermöglichen, sehe ich drei Elemente:

1. **Modelle, die bei Sprachen gut sind.** Sie sind noch nicht ganz dort, aber sie verbessern sich schnell, und wir setzen auf diesen Trend. Wir müssen kein Foundation-Modell aufbauen. Wir müssen bereit sein, sie gut zu nutzen, wenn es soweit ist.
2. **Ein System zum Modellieren und Teilen des Kontexts, der Agenten benötigt.** Das ist das Stück, das zwischen dem Modell und dem Inhalt sitzt. Die Schicht, die deine Stimme, deine Terminologie, deinen Ton, deine Erwartungen an das Publikum einfängt und all das der Agenten auf strukturierte Weise zugängig macht.
3. **Der Kontext, der von Nutzern kommt.** Menschen bringen Urteilskraft, kulturelles Bewusstsein und kreative Führung. Kein System kann das vollständig ersetzen. Aber ein System kann es einfach machen, diesen zu erfassen und wiederzuverwenden.

Von diesen drei haben wir zwei unter unserer Kontrolle: das System selbst und wie wir Nutzer leiten, um Kontext beizusteuern und uns dabei zu helfen, das System zu verbessern. Wir glauben, beides richtig zu machen, ist es, was Glossia dazu bringt, in einem Bereich herauszustechen, der sich schnell mit "einfach LLM integrierende" Lösungen füllt. Das System ist, wo wir Jahrzehnte der linguistischen Theorie in die in der Agentenwelt auftauchenden Grundbausteine codifizieren müssen. Und die Benutzerfahrung darum herum ist, wie wir sicherstellen, dass der richtige Kontext tatsächlich erfasst, verfeinert und zurück in den Kreis eingespeist wird.

Eugene Nida, ein Begründer der modernen Übersetzungswissenschaften, argumentierte, dass eine gute Übersetzung nicht von Wort-für-Wort-Korrespondenz abhängt. Sein Konzept der [dynamischen Äquivalenz](https://en.wikipedia.org/wiki/Dynamic_equivalence) besagt, dass die Beziehung zwischen dem Zielpublikum und der übersetzten Nachricht sich so anfühlen sollte wie die Beziehung zwischen dem ursprünglichen Publikum und der Quelle. Das ist eine schöne Idee, aber es erfordert tiefes kontextuelles Verständnis: wer liest, welches kulturelle Rahmenwerk sie mitbringen, welchen Ton das Original anstrebt. Das sind genau die Arten von Dingen, die irgendwo leben müssen, wo ein Modell sie erreichen kann.

## Was wir erfassen müssen, und wie

Eine der ersten Dinge, die wir erforschen, ist welche Informationen erfasst werden müssen und wie man sie strukturiert, damit Agenten sie tatsächlich nutzen können. Je mehr wir darüber dachten, desto mehr realisierten wir, dass dies keine flache Konfigurationsdatei oder eine Einstellungsseite war. Es musste ein Graph sein. Genauer gesagt, ein **[gerichteter azyklischer Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Warum ein DAG? Weil **Kontext nicht flach ist**. Deine Markenstimme beeinflusst deine Terminologie. Deine Terminologie formt, wie du über spezifische Funktionen schreibst. Deine Publikumserwartungen bestimmen das Formalitätsniveau, was wiederum die Wortwahl beeinflusst. Diese Beziehungen haben Richtung und Hierarchie, und sie laufen nicht in sich selbst zurück.

Hier besteht bereits Stand der Technik. Wissensgraphen werden seit Jahren in KI-Systemen verwendet, um strukturierte Beziehungen zwischen Konzepten darzustellen. Kürzlich haben [Kontextgraphen](https://grokipedia.com/page/context-graph) diese Idee erweitert, indem sie dynamische Kontextebenen hinzufügen, genau den Typ von Elementen, dass Agents benötigen, um fundierte Entscheidungen zu treffen. Und in der Welt der Multi-Agenten-Systeme wurden [DAGs](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) zu einem grundlegenden Muster zur Modellierung von Aufgabenabhängigkeiten und Informationsfluss.

Aber hier ist der Teil, der mich begeistert: **jeder Knoten in diesem Graph muss versioniert sein**. Wenn Sie Ihre Markenstimme ändern, sollten Sie keinen Zugriff auf die vorherige Version verlieren. Wenn Sie einen Terminologieeintrag aktualisieren, sollte das System wissen, welche Inhalte unter der alten Definition produziert wurden und welche Teile möglicherweise neu überprüft werden müssen. Genau das ermöglicht es uns, den Agenten-Workflow zu optimieren, sodass er nur für die Teile ausgelöst wird, die tatsächlich von einer Änderung betroffen sind, anstatt alles erneut zu verarbeiten.

## Bidirektional durch Design

Wir glauben, dass die Beziehung zwischen Kontextknoten und Inhalt richtungsabhängig ist und in beide Richtungen funktionieren muss.

Man betrachtet es aus einer Seite: Sie müssen wissen, wie Inhalte mit dem Kontext verbunden sind. Wenn ein Kontextabschnitt sich ändert (etwa wenn Ihre Markenstimme zu einer lockeren Tonalität wechselt), welche Blogbeiträge, Produktbeschreibungen oder Hilfeartikel wurden unter der vorherigen Version verfasst? Das sind die, die neu überprüft oder neu übersetzt werden müssen. Dies ist die **vorwärtige Richtung, vom Kontext zum Inhalt**.

Vom anderen Ende aus: Wenn ein Linguist einen Inhalt betrachtet und sich fragt, warum eine bestimmte Entscheidung getroffen wurde, sollte er in der Lage sein, diese zurück auf den Kontext zu verfolgen, der die Entscheidung geleitet hat. Welche Stimmen-Definition war aktiv? Welche Terminologie-Regel galt? Diese **Rückwärtsverfolgbarkeit** ist das, was Menschen ermöglicht, zu verstehen, was die Agenten getan haben, und mit Zuversicht darauf aufzubauen.

NASA nennt dies [bidirektionale Verfolgbarkeit](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): die Fähigkeit, eine Assoziation zwischen Entitäten in beide Richtungen nachzuverfolgen. Es ist ein Prinzip der Systemtechnik, und es stellt sich heraus genau das, was Sie brauchen, wenn Sie versuchen, eine Feedbackschleife zwischen linguistischem Kontext und generiertem Inhalt zu erstellen.

Diese bidirektionale Qualität macht **progressive Verfeinerung** möglich. Ein Linguist kann einen Inhalt prüfen, den Kontext sehen, der ihn geprägt hat, entscheiden, dass die Stimmen-Definition angepasst werden muss, und diese Anpassung vornehmen. Das System weiß dann genau, welche anderen Inhalte von der Änderung betroffen sind. Es ist eine enge Schleife, und sie ist sehr menschlich.

## Jenseits eines einzelnen Repositories

Es gibt eine weitere Dimension in diesem Graphen, die ich besonders interessant finde. **Es kann nicht in einem einzelnen Repository leben**. Der Kontextgraph muss über Projekte hinweg teilbar sein und potenziell auch über Organisationen hinweg.

Stellen Sie sich vor: Ein Unternehmen hat eine Markenstimme. Diese Stimme gilt für jedes Produkt, jede Website, jeden Support-Artikel. Sie lebt nicht in einem einzigen Repository. Es ist ein Querschnittsproblem. Sie könnten Ihre Kernstimme auf der Organisations-ebene definieren, dann Overrides auf Projektebene für ein bestimmtes Produkt oder Publikum anwenden. Dies ist **Scope-Vererbung**, demselben Muster, das wir in der Programmierung kennen, aber auf linguistischen Kontext angewendet.

Und dieser Kontext muss ordnungsgemäß versioniert sein. Man kann die Stimmen-Definition nicht einfach ändern und die vorherige Version löschen. Es gibt viel zu lernen, wie [Git die Versionierung durchführt](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) über Inhaltsadressierung und DAGs. Gits Modell von Commits, Branchen und Diffs geht grundlegend darum, zu verfolgen, wie sich Dinge über die Zeit verändern, während der Zugriff auf jeden vorherigen Zustand erhalten bleibt. Genau das brauchen wir für linguistischen Kontext.

Tatsächlich glauben wir, dass ein Sprachstimmenwechsel über etwas geschehen sollte, das wir*Sprachstimmenwechselanfrage*. Genau wie ein Pull Request einen Raum für Diskussionen um Code-Änderungen schafft, schafft eine Sprachstimmenwechselanfrage einen Raum für die Besprechung linguistischer Änderungen. Warum wechseln wir zu einem gesprächigeren Ton? Welche Auswirkungen wird das haben? Welcher Inhalt wird betroffen sein? Diese sind wertvolle Gespräche, die vor der Propagation der Änderung führen zu sollten.

## Wo Menschen kreativer werden, nicht weniger relevant

Und hier-beginnen die Dinge wirklich interessant zu werden. Anstatt Menschen zu eliminieren, was die Erzählung ist, die viele vorbringen, wenn sie über KI sprechen, dient dieses System**stunden Menschen eine kreativere Rolle**.

Stellen Sie sich ein Team von Linguisten und Content-Strategen vor, die eine Sitzung abhalten, in der sie Ideen zur sprachlichen Ausrichtung der Marke diskutieren. Sie können Konzepte erkunden, Tonwechsel debattieren, kulturellen Kontext verweisen, auf den kein Zugriff eines Modells möglich. Dann stattdessen die manuell tausenden Dateien zu aktualisieren, erfassen sie ihre Entscheidungen als Anpassungen an die Kontextgraphik. Das System übernimmt die Propagation.

Oder gehen Sie noch einen Schritt weiter: stellen Sie sich Agenten-Sitzungen vor, in denen ein Linguist mit einer KI-Assistentin linguistic ideas erforscht. "Was wäre, wenn die Fehlermeldungen empatisch wären?" Der Agent simuliert die Auswirkungen, zeigt, wie der aktuelle Kontext sich ändern würde, vorschaut, wie die aktualisierten Inhalte aussehen könnten. Der Linguist verfeinert, passt an und reicht einen Kontextänderungsantrag ein, wenn zufrieden. Wäre das nicht großartig?

**Dies geht nicht darum, den Linguisten zu ersetzen.**Es geht darum, ihnen bessere Tools zu geben, mit dem, was sie bereits hervorragend können: subtile, kulturell informierte Entscheidungen über Sprache treffen. Das System übernimmt die mechanischen Teile (Propagation, Impact-Analyse, Konsistenz), während sich Menschen auf die kreativen Teile (Sprache, Ton, kulturelle Resonanz) konzentrieren.

Ich kehre ständig zurück zu dem, was Nida mit dynamischer Äquivalenz gemeint hat. Das Ziel ist keine linguistische Genauigkeit im mechanischen Sinne. Es geht darum, die gleiche gefühlte Beziehung zwischen Leser und Inhalt unabhängig von Sprache zu schaffen. Das erfordert Geschmakmtell, Urteilskraft und kulturelle Sensibilität. Dinge, die Menschen hervorragend können, mit denen Modelle aber noch kämpfen. Die Aufgabe des Systems ist es, sicherzustellen, dass menschliche Erkenntnisse erfasst, strukturiert und wiederverwendbar sind.

## Was kommt als Nächstes

In einem Folgebeitrag werden wir näher technisch werden und über die Rolle sprechen, die Sandboxes dabei spielen, Erfahrungen zu ermöglichen, die in diesem Bereich noch nicht gesehen wurden, und warum wir stark in APIs investieren. Es gibt eine ganze Dimension rund um Staging, Vorschauen und Testen linguistischer Änderungen vor ihrem Live-Gang, worüber wir uns freuen, uns einzudringen.

Wenn dich irgendwelche Teile hier interessieren, ob du als Linguist mit der aktuellen Werkzeugausstattung frustriert bist, ein Entwickler, der sich mit Lokalisierungsworkflows herumschlagen, oder einfach jemand, der tief über das Zusammentreffen von Sprache und Technologie nachdenkt, freuen wir uns, von dir zu hören.
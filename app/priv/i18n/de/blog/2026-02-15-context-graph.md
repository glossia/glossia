%{
  title:
    "Der Kontextgraph: Die Kodifizierung jahrzehntelanger linguistischer Theorie für die agentische Ära",
  summary:
    "Sprachmodelle sind leistungsfähig, benötigen aber den richtigen Kontext, um hochwertigen Inhalt zu generieren. Wir entwickeln einen versionierten, gerichteten Graphen, um linguistisches Wissen zu erfassen und es mit Agenten zu teilen; wir sind überzeugt, dass dies genau das ist, was Glossia besonders macht.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Ich habe mich viel Gedanken gemacht, was den Unterschied zwischen Inhalten ausmacht, die sich maschinell generiert anfühlen, und Inhalten, die sich anfühlen, als wären sie von jemandem verfasst worden, der das Publikum, die Marke und die kulturellen Nuancen hinter jedem Wort versteht. Die Antwort führt immer wieder auf dasselbe zurück: **Kontext**.

Sprachmodelle sind in Sprachen besser, und wir setzen auf diese Entwicklung. Sie sind noch nicht vollständig dort, aber das Tempo der Verbesserung ist schwer zu ignorieren. Was jedoch fehlt, ist das System, das zwischen dem Modell und dem Inhalt sitzt. Das, was dem Modell sagt *wer* du bist, *wie* du sprichst, *Was* in diesem bestimmten Satz zählt, und *warum* dieser Satz überhaupt existiert. Das ist das Problem, an dem wir bei Glossia arbeiten, und ich finde, es ist derzeit das Interessanteste auf diesem Gebiet.

## Drei Elemente, zwei kontrollieren wir selbst.

Wenn ich mir überlege, was nötig ist, um einen wirklich neuen Ansatz für monolingualen und multilingualen Inhalt zu ermöglichen, sehe ich drei Elemente:

1. **Modelle, die gut mit Sprachen umgehen können.** Sie sind noch nicht vollends da, verbessern sich aber rasant und wir setzen auf diesen Trend. Wir müssen kein Stammodell erstellen. Wir müssen bereit sein, sie gut zu nutzen, sobald sie dann soweit sind.
2. **Ein System, um den Kontext zu modellieren und zu teilen, den Agenten benötigen.** Dies ist das Element zwischen dem Modell und dem Inhalt. Die Ebene, die Ihre Stimme, Ihre Terminologie, Ihren Ton, Ihre Erwartungen an die Zielgruppe erfasst und all dies in einer strukturierten Weise dem Agenten bereitstellt.
3. **Der Kontext, der von Nutzern stammt.** Menschen bringen Urteilskraft, kulturelles Bewusstsein und kreative Richtung mit. Kein System kann das vollständig ersetzen. Ein System kann es jedoch einfach machen, dies einzufangen und wiederzuverwenden.

Von diesen drei sind zwei unter unserer Kontrolle: das System selbst und wie wir Nutzer anleiten, Kontext beizutragen und uns zu helfen, das System zu verbessern. Wir glauben, dass beides richtig zu bekommen entscheidend ist, um Glossia in einem Bereich hervorzuheben, der sich schnell füllt mit "einen LLM einfach einzufügen"-Lösungen. Das System ist der Ort, wo wir Jahrzehnte der Sprachtheorie in die Grundbausteine der aufkommenden Agentenwelt kodifizieren müssen. Und die User Experience rund um es ist der Weg, wie wir sicherstellen, dass der richtige Kontext tatsächlich erfasst, verfeinert und in den Loop zurückgeführt wird.

Eugene Nida, einer der Begründer moderner Übersetzungswissenschaft, argumentierte, dass gute Übersetzung nicht um wortwörtliche Entsprechung geht. Sein Konzept der [dynamische Äquivalenz](https://en.wikipedia.org/wiki/Dynamic_equivalence) sagt, dass die Beziehung zwischen der Zielgruppe und der übersetzten Botschaft so anmuten sollte wie die Beziehung zwischen der ursprünglichen Zielgruppe und der Quelle. Das ist eine schöne Idee, aber es erfordert tiefes kontextuelles Verständnis: wer liest, welchen kulturellen Rahmen sie mitbringen, welchen Ton das Original anstrebte. Genau diese Dinge müssen an einem Ort sein, an dem ein Modell darauf zugreifen kann.

## Was wir erfassen müssen, und wie

Eine der ersten Dinge, die wir erforschen, ist welche Informationen erfasst werden müssen und wie wir sie strukturieren, damit Agenten sie tatsächlich nutzen können. Je mehr wir darüber nachdachten, desto mehr erkannten wir, dass dies keine flache Konfigurationsdatei oder Einstellungsseite sein konnte. Es musste ein Graph sein. Insbesondere ein **[gerichteter azyklischer Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Warum ein DAG? Weil **Kontext ist nicht flach**. Ihr Markentonus beeinflusst Ihre Terminologie. Ihre Terminologie prägt, wie Sie über spezifische Features schreiben. Ihre Erwartungen Ihrer Zielgruppe bestimmen das Formalitätsniveau, was wiederum die Wortschatzwahl beeinflusst. Diese Beziehungen haben Richtung und Hierarchie und lassen sich nicht selbst wiederholen.

Hier gibt es bereits Vorarbeiten. Wissensgraphen werden seit Jahren in KI-Systemen genutzt, um strukturierte Beziehungen zwischen Konzepten darzustellen. Kürzlich noch, [Kontextgraphen](https://grokipedia.com/page/context-graph) haben diese Idee erweitert, indem sie dynamische Kontextschichten hinzufügen – genau das, was Agenten zum Treffen fundierter Entscheidungen benötigen. Und in der Welt der Multi-Agenten, [DAGs sind zu einem grundlegenden Muster geworden](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) zur Modellierung von Aufgabenabhängigkeiten und Informationsfluss.

Aber hier ist der Teil, der mich begeistert: **jeder Knoten in diesem Graphen muss versioniert sein**. Wenn Sie Ihre Markenstimme ändern, sollten Sie keinen Zugang zur vorherigen Version verlieren. Wenn Sie einen Terminologeeintrag aktualisieren, sollte das System wissen, welcher Inhalt unter der alten Definition erstellt wurde und welche Teile möglicherweise überprüft werden müssen. Dies ermöglicht es uns, den Agenten-Arbeitsablauf so zu optimieren, dass er nur für die Teile ausgelöst wird, die tatsächlich von einer Änderung betroffen sind, anstatt alles neu zu verarbeiten.

## Beidirektional von Grund auf

Wir glauben, dass die Beziehung zwischen Kontextknoten und Inhalt gerichtet sein muss und in beide Richtungen funktioniert.

Betrachtet man es von einer Seite: Man muss wissen, wie Inhalte mit dem Kontext verknüpft sind. Wenn sich ein Kontextelement ändert (z. B. wenn Ihre Markenstimme zum Informelleren wechselt), welche Blog-Beiträge, Produktbeschreibungen oder Hilfeartikel wurden unter der vorherigen Version erstellt? Diese müssen überprüft oder neu übersetzt werden. Dies ist der **Vorwärtsrichtung, vom Kontext zum Inhalt**.

Von der anderen Seite: Wenn ein Übersetzer einen Inhalt betrachtet und sich fragt, warum eine bestimmte Entscheidung getroffen wurde, sollte er in der Lage sein, dies dem Kontext zurückzuverfolgen, der die Entscheidung leitete. Welche Stimmmdefinition war aktiv? Welche Terminologie-Regel galt? Diese **Rückwärtsverfolgbarkeit** ist das, was Menschen verstehen lässt, was die Agenten getan haben, und es mit Zuversicht zu verfeinern.

NASA nennt dies [bidirektionale Rückverfolgbarkeit](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): die Fähigkeit, eine Beziehung zwischen Entitäten in beide Richtungen nachzuvollziehen. Es ist ein Prinzip aus dem Systems Engineering, und es stellt sich heraus, dass es genau das ist, was Sie benötigen, wenn Sie versuchen, eine Feedbackschleife zwischen linguistischem Kontext und generiertem Inhalt zu erstellen.

Diese bidirektionale Qualität macht **schrittweise Verfeinerung** möglich. Ein Linguist kann einen Inhalt überprüfen, den Kontext betrachten, der ihn geprägt hat, entscheiden, dass die Stimmedefinition angepasst werden muss, und diese Anpassung erstellen. Das System weiß dann genau, welche anderen Inhalte von der Änderung betroffen sind. Es ist eine enge Schleife, und es ist hochgradig menschlich.

## Jenseits eines einzelnen Repositorys

Es gibt eine weitere Dimension in diesem Graphen, die ich als besonders interessant empfinde. **Es kann sich nicht in einem einzigen Repository befinden.** Der Kontextgraph muss über Projekte hinweg geteilt werden und potenziell auch über Organisationen hinweg.

Denk darüber nach: Ein Unternehmen verfügt über eine Markenstimme. Diese Stimme gilt für jedes Produkt, jede Website, jeden Supportartikel. Sie lebt nicht in einem einzigen Repository. Es ist eine Querschnittsaufgabe. Sie könnten Ihre Kernstimme auf Organisationsebene definieren und dann Überschreibungen auf Projektebene für ein spezifisches Produkt oder Publikum anwenden. Dies ist **Scope-Vererbung**dasselbe Muster, an dem wir in der Programmierung gewohnt sind, aber angewendet auf den linguistischen Kontext.

Und dieser Kontext muss ordnungsgemäß versioniert werden. Sie können nicht einfach die Stimmedefinition ändern und die vorherige Version löschen. Es gibt viel zu lernen, wie [Git die Versionierung handhabt](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) über content-addressable storage und DAGs. Das Git-Modell von Commits, Branches und Diffs dreht sich im Kern um das Verfolgen von Änderungen über die Zeit, während gleichzeitig Zugriff auf jeden vorherigen Zustand erhalten bleibt. Genau das brauchen wir für den linguistischen Kontext.

Tatsächlich glauben wir, dass eine Stimmenänderung über etwas geschehen sollte, das wir so nennen *Stimmenänderungsanfrage*. So wie ein Pull Request Raum für die Diskussion von Codeänderungen bietet, bietet eine Stimmenänderungsanfrage Raum für die Diskussion sprachlicher Änderungen. Warum wechseln wir zu einem gesprächigeren Ton? Welche Auswirkungen wird das haben? Welche Inhalte sind betroffen? Das sind Gespräche, die vor der Ausbreitung der Änderung geführt werden sollten.

## Wo Menschen kreativer werden, nicht weniger relevant

Und hier wird es wirklich interessant. Anstatt Menschen zu eliminieren – was die Erzählung ist, die viele verbreiten, wenn sie über KI sprechen –, dieses System **verleiht den Menschen eine kreativere Rolle**.

Stellen Sie sich ein Team aus Linguisten und Content-Strategen vor, das eine Sitzung abhält, in der sie Ideen zur sprachlichen Ausrichtung der Marke diskutieren. Sie können Konzepte erkunden, Tonalitätswechsel debattieren, kulturellen Kontext heranziehen, der keinem Modell zugänglich ist. Statt hunderte von Dateien manuell zu aktualisieren, erfassen sie ihre Entscheidungen als Anpassungen des Kontextgraphen. Das System kümmert sich um die Ausbreitung.

Oder gehen Sie noch einen Schritt weiter: Stellen Sie sich Agentenbasierte Sitzungen vor, in denen ein Sprachexperte mit einem KI-Assistenten zusammenarbeitet, um linguistische Ideen zu erforschen. "Was wäre, wenn wir die Fehlermeldungen verständnisvoller gestalten?" Der Agent simuliert die Auswirkungen, zeigt, wie sich der aktuelle Kontext verändern würde, und zeigt vor, wie der aktualisierte Inhalt aussehen könnte. Der Sprachexperte verfeinert, passt an und reicht, wenn er zufrieden ist, eine Anfrage zur Kontextänderung ein. Das wäre doch großartig.

**Es geht nicht darum, den Sprachexperten zu ersetzen.** Es geht darum, ihnen bessere Werkzeuge an die Hand zu geben, um das zu tun, worin sie bereits stark sind: das Treffen nuancierter, kulturell fundierter Entscheidungen über Sprache. Das System übernimmt die mechanischen Anteile (Ausbreitung, Auswirkungsanalyse, Konsistenz), während sich der Mensch auf die kreativen Anteile (Stimme, Ton, kulturelle Resonanz) konzentriert.

Ich kehre immer wieder darauf zurück, worauf Nida mit der dynamischen Äquivalenz hinauswollte. Das Ziel ist keine linguistische Genauigkeit im mechanischen Sinn. Es geht darum, die gleiche gefühlte Verbindung zwischen Leser und Inhalt zu schaffen, unabhängig von der Sprache. Das erfordert Geschmack, Urteilsvermögen und kulturelles Bewusstsein. Dinge, die Menschen außerordentlich gut beherrschen, und bei denen Modelle noch Schwierigkeiten haben. Die Aufgabe des Systems ist es, sicherzustellen, dass diese menschlichen Erkenntnisse erfasst, strukturiert und wiederverwendbar gemacht werden.

## Was Naechst?

In einem nachfolgenden Artikel werden wir mehr ins Technische gehen und darüber sprechen, welche Rolle Sandboxes spielen, um bisher in diesem Bereich noch nicht gesehene Erfahrungen zu ermöglichen, und warum wir stark in APIs investieren. Es gibt eine ganze Dimension um Staging, Vorschau und Testen von linguistischen Änderungen, bevor sie live gehen, in die wir mit Vorfreude eintauchen.

Wenn das bei Ihnen Anklang findet, egal ob Sie ein Linguist sind, der mit dem aktuellen Tooling frustriert ist, ein Entwickler, der mit Lokalisierungsworkflows zu kämpfen hat, oder jemand, der tief darüber nachdenkt, wie Sprache und Technologie sich kreuzen, freuen wir uns über Ihre Rückmeldung.
%{
  title: "Der Kontextgraph: Jahrzehnte linguistischer Theorie für die Agenten-Ära kodifizieren.",
  summary:
    "Sprachmodelle sind leistungsstark, benötigen aber den richtigen Kontext, um großartige Inhalte zu produzieren. Wir entwickeln einen versionierten, gerichteten Graphen, um linguistisches Wissen zu erfassen und mit Agenten zu teilen, und wir glauben, dass dies das ist, was Glossia abhebt.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Ich habe mich lange damit beschäftigt, was den Unterschied ausmacht zwischen Inhalten, die nach maschineller Generierung klingen, und Inhalten, die so wirken, als habe sie jemand verfasst, der das Publikum, die Marke und die kulturellen Nuancen hinter jedem Wort versteht. Die Antwort kehrt stets zum selben Punkt zurück: **Kontext**.

Sprachmodelle werden bei der Verarbeitung von Sprachen besser, und wir setzen darauf, dass diese Tendenz anhält. Sie sind noch längst nicht dort angekommen, aber das Tempo der Verbesserung ist kaum zu ignorieren. Was jedoch noch fehlt, ist das System zwischen dem Modell und dem Inhalt. Das, was dem Modell sagt, *wer* du bist, *wie* du sprichst, *was* in diesem speziellen Satz zählt, und *warum* dass dieser Satz überhaupt existiert. Das ist das Problem, an dem wir bei Glossia arbeiten, und ich denke, es ist das interessanteste in diesem Bereich gerade jetzt.

## Drei Elemente, zwei unter unserer Kontrolle

Wenn ich prüfe, was notwendig ist, um einen wirklich neuen Ansatz für einsprachige und mehrsprachige Inhalte zu ermöglichen, sehe ich drei Elemente:

1. **Modelle, die gut mit Sprachen umgehen.** Sie sind noch nicht ganz fertig, entwickeln sich aber schnell und wir setzen auf diesen Trend. Wir müssen kein Foundation-Modell aufbauen. Wir müssen bereit sein, sie gut einzusetzen, wenn sie soweit sind.
2. **Ein System, um den Kontext zu modellieren und zu teilen, den Agenten benötigen.** Dies ist das Element, das zwischen dem Modell und dem Inhalt sitzt. Die Ebene, die deine Stimme, deine Terminologie, deinen Ton, deine Zielgruppen-Erwartungen einfängt und all das dem Agenten in einer strukturierten Weise dient.
3. **Der Kontext, der von Nutzern stammt.** Menschen bringen Urteilskraft, kulturelles Bewusstsein und kreative Richtung mit. Kein System kann das vollständig ersetzen. Aber ein System kann es einfach machen, dies zu erfassen und wiederverwenden.

Von diesen drei kontrollieren wir zwei: das System selbst und wie wir Nutzer anleiten, Kontext beizutragen und uns beim Verbessern des Systems zu helfen. Wir glauben, dass beide richtig machen es ist, was Glossia in einem Raum hervorhebt, der sich schnell mit "just plug in an LLM"-Lösungen füllt. Das System ist, wo wir jahrzehntelange linguistische Theorie in die Grundbausteine codifizieren müssen, die in der Welt der Agenten aufkommen. Und das Benutzererlebnis darum herum ist, wie wir sicherstellen, dass der richtige Kontext tatsächlich erfasst, verfeinert und in den Kreislauf eingespeist wird.

Eugene Nida, einer der Grinding der modernen Übersetzungswissenschaft, argumentierte, dass gute Übersetzung nicht um Wort-für-Wort-Korrespondenz geht. Sein Konzept der [dynamische Äquivalenz](https://en.wikipedia.org/wiki/Dynamic_equivalence) sagt, dass die Beziehung zwischen der Zielgruppe und der übersetzten Nachricht das gleiche Gefühl haben sollte wie die Beziehung zwischen dem ursprünglichen Publikum und der Quelle. Das ist eine schöne Idee, aber es erfordert tiefes kontextuelles Verständnis: wer liest, welcher kulturenrahmen sie mitbringen, welcher Ton das Original verfolgte. Dies sind genau die Arten von Dingen, die irgendwo existieren müssen, wo ein Modell sie erreichen kann.

## Was wir erfassen müssen und wie

Eines der ersten Dinge, die wir untersuchten, war, welche Informationen erfasst werden müssen und wie sie strukturiert werden sollen, damit Agenten sie tatsächlich nutzen können. Je mehr wir darüber nachdachten, desto mehr merkten wir, dass dies keine flache Konfigurationsdatei oder eine Einstellungen-Seite war. Es musste ein Graph sein. Genauer gesagt, ein **[gerichteter azyklischer Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Warum ein DAG? Weil **Kontext ist nicht flach**Ihre Markenstimme beeinflusst Ihre Terminologie. Ihre Terminologie bestimmt, wie Sie über bestimmte Funktionen schreiben. Die Erwartungen Ihrer Zielgruppe bestimmen das Formalitätsniveau, was wiederum die Wortwahl beeinflusst. Diese Beziehungen haben Richtung und Hierarchie und laufen nicht auf sich selbst zurück.

Hier gibt es bereits Vorarbeiten. Wissensgraphen werden seit Jahren in KI-Systemen verwendet, um strukturierte Beziehungen zwischen Konzepten abzubilden. In jüngerer Zeit, [Kontextgraphen](https://grokipedia.com/page/context-graph) haben diese Idee durch Hinzufügen dynamischer Kontextebenen erweitert, genau das, was Agenten benötigen, um fundierte Entscheidungen zu treffen. Und in der Welt der Multi-Agenten-Systeme, [DAGs haben sich zu einem grundlegenden Muster entwickelt](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) zur Modellierung von Aufgabenabhängigkeiten und Informationsfluss.

Aber hier ist der Teil, der mich begeistert: **jeder Knoten in diesem Graphen muss versioniert werden**. Wenn Sie Ihre Markenstimme ändern, sollten Sie keinen Zugriff auf die vorherige Version verlieren. Wenn Sie einen Terminologie-Eintrag aktualisieren, sollte das System wissen, welcher Inhalt unter der alten Definition erstellt wurde und welche Teile möglicherweise erneut überprüft werden müssen. Dies ermöglicht es uns, den agentischen Workflow zu optimieren, so dass er nur für die Teile ausgelöst wird, die tatsächlich durch eine Änderung betroffen sind, anstatt alles erneut zu verarbeiten.

## Bidirektional von Grund auf

Wir sind der Überzeugung, dass die Beziehung zwischen Kontext-Knoten und Inhalt Richtung haben muss und in beide Richtungen funktionieren muss.

Betrachtet man es von einer Seite: Sie müssen wissen, wie Inhalt mit Kontext verbunden ist. Wenn sich ein Stück Kontext ändert (sagen wir, Ihre Markenstimme wird etwas lässiger), welche Blogbeiträge, Produktbeschreibungen oder Hilfeartikel wurden unter der vorherigen Version erstellt? Diese müssen aufgearbeitet oder neu übersetzt werden. Dies ist der **Richtung vorwärts, vom Kontext zum Inhalt**.

Von der anderen Seite: Wenn ein Übersetzer einen Inhalt betrachtet und sich fragt, warum eine bestimmte Entscheidung getroffen wurde, sollte er diese bis zum Kontext zurückverfolgen können, der die Entscheidung leitete. Welche Sprachdefinition war aktiv? Welche Terminologie-Regel galt? Dies **Rückwärtsverfolgbarkeit** ist das, was es Menschen ermöglicht, zu verstehen, was die Agenten getan haben, und darauf mit Zuversicht weiterzuarbeiten.

NASA nennt das [bidirektionale Rückverfolgbarkeit](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): die Fähigkeit, eine Assoziation zwischen Entitäten in beide Richtungen zu verfolgen. Es ist ein Prinzip der Systemtechnik, und es stellt sich heraus, dass genau das ist, was du brauchst, wenn du versuchst, eine Rückkopplungsschleife zwischen dem sprachlichen Kontext und dem generierten Inhalt zu erstellen.

Diese bidirektionale Qualität ist das, was **schrittweise Verfeinerung** möglich. Ein Linguist kann einen Inhalt prüfen, den Kontext erkennen, der ihn geprägt hat, entscheiden, dass die Sprachdefinition angepasst werden muss, und diese Anpassung durchführen. Das System weiß dann genau, welche anderen Inhalte von der Änderung betroffen sind. Es ist ein enger Kreislauf, und er ist tief menschlich.

## Jenseits eines einzelnen Repositoriums

Es gibt eine weitere Dimension in diesem Graphen, die ich besonders interessant finde. **Es kann nicht in einem einzigen Repository leben.** Der Kontextgraph muss über Projekte hinweg teilbar sein, und potenziell auch über Organisationen hinweg.

Denken Sie darüber nach: Eine Firma hat eine Markenstimme. Diese Stimme gilt für jedes Produkt, jede Website, jeden Support-Artikel. Sie lebt nicht in einem Repository. Es handelt sich um einen Querschnittsanspruch. Sie können Ihre Kernstimme auf der Organisations-Ebene definieren, und passen dann Überschreibungen für ein spezifisches Produkt oder eine Zielgruppe auf der Projektebene an. Dies ist **Bereichsvererbung**, dasselbe Muster, das wir aus der Programmierung kennen, nur auf den linguistischen Kontext übertragen.

Und dieser Kontext muss ordnungsgemäß versioniert werden. Sie können nicht einfach die Stimmmendefinition ändern und die vorherige Version löschen. Es gibt viel zu lernen, wie [Git verwaltet die Versionierung](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) durch inhaltsbasierte Speicherung und DAGs. Das Git-Modell von Commits, Zweigen und Differenzen geht im Wesentlichen darauf aus, zu verfolgen, wie sich Dinge über die Zeit verändern, während der Zugriff auf jeden vorherigen Zustand erhalten bleibt. Genau das brauchen wir für den linguistischen Kontext.

Tatsächlich glauben wir, dass eine Stimmeänderung über etwas geschehen sollte, das wir einen *Stimmenwechselantrag*. Genau wie ein Pull-Request einen Raum für Diskussionen um Code-Änderungen schafft, schafft ein Stimmenwechselantrag einen Raum für Diskussionen linguistischer Änderungen. Warum wechseln wir zu einem mehr dialogischen Tonfall? Welchen Einfluss wird das haben? Welche Inhalte werden betroffen sein? Dies sind Gespräche, die sich lohnen, bevor sich die Änderung ausbreitet.

## Wo Menschen zu etwas Kreativerem werden, nicht weniger relevant

Und hier beginnt es wirklich interessant zu werden. Anstatt Menschen zu eliminieren, was die Erzählung ist, die viele in Bezug auf KI vertreten, dieses System **verleiht den Menschen eine kreativere Rolle**.

Stellen Sie sich ein Team von Linguisten und Content-Strategen vor, die in einer Sitzung Ideen zur sprachlichen Ausrichtung der Marke diskutieren. Sie könnten Konzepte erforschen, Tonwandel debattieren, kulturellen Kontext anführen, den kein Modell hat. Und dann, anstatt hundert Dateien manuell zu aktualisieren, erfassen sie ihre Entscheidungen als Anpassungen am Kontextgraph. Das System kümmert sich um die Ausbreitung.

Und noch einen Schritt weiter: Stellen Sie sich Sitzungen mit Agenten vor, in denen ein Linguist mit einer KI-Assistenz zusammenarbeitet, um linguistische Ideen zu erforschen. "Was wäre, wenn wir die Fehlermeldungen empathischer gestalten?" Der Agent simuliert die Auswirkungen, zeigt, wie sich der aktuelle Kontext verändern würde, und gibt einen Vorschau darauf, wie die aktualisierten Inhalte aussehen könnten. Der Linguist verfeinert und passt an und reicht, wenn er zufrieden ist, eine Anfrage zur Kontextänderung ein. Wäre das nicht schon etwas?

**Es geht nicht darum, den Linguisten zu ersetzen.** Es geht darum, ihnen bessere Tools zu geben, um zu tun, was sie bereits hervorragend machen: differenzierte, kulturell informierte Entscheidungen über Sprache zu treffen. Das System übernimmt die mechanischen Teile (Propagation, Auswirkungenanalyse, Konsistenz), während sich Menschen auf die kreativen Teile konzentrieren (Stimme, Ton, kulturelle Resonanz).

Ich kehre immer wieder zu dem zurück, was Nida mit dynamischer Äquivalenz meinte. Das Ziel ist keine linguistische Genauigkeit im mechanischen Sinne. Es geht darum, die gleiche gefühlte Beziehung zwischen Leser und Inhalt zu schaffen, unabhängig von der Sprache. Das erfordert Geschmack, Urteilskraft und kulturelles Bewusstsein. Dinge, die Menschen hervorragend beherrschen, und bei denen die Modelle noch Schwierigkeiten haben.

## Was folgt

In einem nachfolgenden Beitrag werden wir technischer werden und darüber sprechen, welche Rolle Sandboxes spielen werden, um Erfahrungen zu ermöglichen, die in diesem Raum noch nicht gesehen wurden, sowie warum wir stark in APIs investieren. Es gibt eine ganze Dimension rund um Staging, Vorschau und das Testen von Sprachänderungen, bevor sie live gehen, in die wir uns freuen, tiefer einzutauchen.

Wenn eines davon bei Ihnen Anklang findet, egal ob Sie ein Linguist sind, der mit den aktuellen Tools enttäuscht ist, ein Entwickler, der mit Lokalisierungs-Workflows gehadert hat, oder einfach jemand, der tief darüber nachdenkt, wie Sprache und Technologie sich überschneiden, würden wir uns freuen, von Ihnen zu hören.
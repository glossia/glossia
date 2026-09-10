%{
  title:
    "Der Kontextgraph: Kodifizierung von Jahrzehnten linguistischer Theorie für die Ära der Agenten",
  summary:
    "Sprachmodelle sind mächtig, benötigen aber den richtigen Kontext, um großartige Inhalte zu produzieren. Wir entwerfen einen versionierten, gerichteten Graphen, um linguistisches Wissen zu erfassen und mit Agenten zu teilen, und wir glauben, dass dies das ist, was Glossia besonders machen wird.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Ich habe viel darüber nachgedacht, was den Unterschied zwischen Inhalten macht, die nach maschineller Generierung klingen, und Inhalten, die sich so anfühlen, als wären sie von jemandem verfasst, der das Publikum, die Marke und die kulturellen Nuancen hinter jedem Wort versteht. Die Antwort führt immer wieder zum selben Punkt zurück: **Kontext**.

Sprachmodelle werden besser im Umgang mit Sprachen, und wir setzen darauf, dass sich diese Entwicklung fortsetzt. Sie sind noch nicht ganz da, aber das Tempo der Verbesserung ist schwer zu ignorieren. Was jedoch noch fehlt, ist das System, das zwischen dem Modell und dem Inhalt sitzt. Das, was dem Modell sagt *wer* du bist, *wie* du sprichst, *was* wichtig ist in diesem besonderen Satz und *warum* dass dieser Satz überhaupt existiert. Das ist das Problem, an dem wir bei Glossia arbeiten, und ich denke, es ist das interessanteste im Bereich gerade jetzt.

## Drei Elemente, zwei unter Kontrolle

Wenn ich mir überlege, was benötigt wird, um einen wirklich neuen Ansatz für monolingualen und multilingualen Inhalt zu ermöglichen, sehe ich drei Elemente.

1. **Modelle, die gut mit Sprachen arbeiten.** Sie sind noch nicht vollständig bereit, verbessern sich aber schnell, und wir wetten auf diesen Trend. Wir müssen kein Basismodell aufbauen. Wir müssen bereit sein, sie gut zu nutzen, wenn sie es werden.
2. **Ein System zur Modellierung und Weitergabe des Kontexts, den Agenten benötigen.** Das ist das Element, das zwischen Modell und Inhalt liegt. Die Schicht, die Ihre Stimme, Ihre Terminologie, Ihren Ton, Ihre Zielgruppenersparnisse einfängt und all das dem Agenten strukturiert zur Verfügung stellt.
3. **Der Kontext, der von Nutzern stammt.** Menschen bringen Urteilskraft, kulturelles Bewusstsein und kreative Richtung. Kein System kann das vollständig ersetzen. Aber ein System kann es einfach machen, das aufzunehmen und zu wieder verwenden.

Von diesen drei kontrollieren wir zwei: das System selbst und die Art und Weise, wie wir Benutzer leiten, Kontext beizusteuern und uns dabei zu helfen, das System zu verbessern. Wir glauben, dass das Gelingen beider nötig ist, um Glossia in einem Raum hervorstechen zu lassen, der sich rasch mit Lösungen füllt, bei denen man einfach ein LLM einbindet. Das System ist der Ort, an dem wir Jahrzehnte linguistischer Theorie in die in der Agentenwelt neu auftauchenden Oberbegriffe umschreiben müssen. Und das Benutzererlebnis darum sorgt dafür, dass der richtige Kontext tatsächlich erfasst, verfeinert und in den Kreislauf zurückgespeist wird.

Eugene Nida, einer der Begründer der modernen Übersetzungswissenschaften, argumentierte, dass gute Übersetzung nicht eine wortwörtliche Entsprechung ist. Sein Konzept von [dynamische Äquivalenz](https://en.wikipedia.org/wiki/Dynamic_equivalence) besagt, dass die Beziehung zwischen der Zielgruppe und der übersetzten Botschaft sich so anfühlen sollte wie die zwischen der Originalzielgruppe und der Quelle. Das ist eine schöne Idee, aber sie erfordert tiefes kontextuelles Verständnis: wer liest, welches kulturelle Rahmenwerk sie mitbringt, welchen Ton das Original ansteuerte. Genau solche Dinge müssen irgendwo leben, wo ein Modell sie greifen kann.

## Was wir erfassen müssen und wie

Eines der ersten Dinge, die wir untersucht haben, ist, welche Informationen erfasst werden müssen und wie sie strukturiert werden sollen, damit Agenten sie tatsächlich nutzen können. Je mehr wir darüber nachdachten, desto mehr merkten wir, dass dies keine flache Konfigurationsdatei oder eine Einstellungen-Seite sein konnte. Es musste ein Graph sein. Genauer gesagt, ein **[gerichteter, azyklischer Graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Warum ein DAG? Weil **Kontext nicht flach ist**. Deine Markenstimme beeinflusst deine Terminologie. Deine Terminologie bestimmt, wie du über spezifische Funktionen schreibst. Deine Publikumserwartungen bilden das Formalitätsniveau, was wiederum die Wortwahl beeinflusst. Diese Beziehungen besitzen Richtung und Hierarchie und laufen nicht wieder auf sich selbst zurück.

Es gibt hier bereits Vorlaufende Lösungen. Wissensgraphen werden seit Jahren in KI-Systemen eingesetzt, um strukturierte Beziehungen zwischen Konzepten darzustellen. Kürzlich erst, [Kontextgraphen](https://grokipedia.com/page/context-graph) haben diese Idee erweitert, indem sie dynamische Kontextschichten hinzufügen, genau das, was Agenten für fundierte Entscheidungen brauchen. Und in der Welt der Multi-Agenten, [DAGs haben sich zu einem grundlegenden Muster entwickelt](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) zur Modellierung von Aufgabenabhängigkeiten und Informationsflüssen.

Aber hier ist der Teil, der mich begeistert: **jeder Knoten in diesem Graphen muss versioniert werden**. Wenn Sie Ihre Markenstimme ändern, sollten Sie keinen Zugriff auf die vorherige Version verlieren. Wenn Sie einen Terminologie-Eintrag aktualisieren, sollte das System erkennen, welcher Inhalt unter der alten Definition erstellt wurde und welche Teile möglicherweise erneut überprüft werden müssen. Das ermöglicht uns, den Agenten-Workflow so zu optimieren, dass er nur für die tatsächlich betroffenen Teile ausgelöst wird, anstatt alles neu zu verarbeiten.

## Beidseitig von Grund auf

Wir sind der Überzeugung, dass die Beziehung zwischen Kontextknoten und Inhalt beidseitig sein muss und in beide Richtungen funktioniert.

Betrachtet man es von einer Seite: Man muss wissen, wie der Inhalt mit dem Kontext verbunden ist. Wenn sich ein Kontextelement ändert (z.B. wenn sich die Markenstimme entspannter verhält), welche Blog-Beiträge, Produktbeschreibungen oder Hilfeartikel wurden unter der vorherigen Version erstellt? Diese sind die, die überprüft oder neu übersetzt werden müssen. Dies ist der **einen Vorwärtsrichtung, vom Kontext zum Inhalt**,

Von der anderen Seite: Wenn ein Übersetzer einen Inhalt betrachtet und sich fragt, warum eine bestimmte Entscheidung getroffen wurde, sollte er dies auf den Kontext zurückverfolgen können, der die Entscheidung geleitet hat. Welche Stimmendefinition war aktiv? Welche Terminologie-Regel galt? Dies **Rückwärts-Nachverfolgbarkeit** ist, was es Menschen ermöglicht, zu verstehen, was die Agenten getan haben, und vertrauensvoll daran weiterzuarbeiten.

Die NASA nennt dies [bidirektionale Rückverfolgbarkeit](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): die Fähigkeit, eine Assoziation zwischen Entitäten in beide Richtungen zu verfolgen. Es ist ein Prinzip des Systemingenieurwesens, und es stellt sich heraus, dass es genau das ist, was Sie benötigen, wenn Sie versuchen, eine Feedbackschleife zwischen sprachlichem Kontext und generiertem Inhalt zu erstellen.

Diese bidirektionale Qualität macht **schrittweise Verfeinerung** möglich. Ein Linguist kann einen Inhalt prüfen, den Kontext sehen, der ihn geformt hat, entscheiden, dass die Stimmen-Definition angepasst werden muss, und diese Anpassung vornehmen. Das System weiß dann genau, welche anderen Inhalte von der Änderung betroffen sind. Es ist ein enger Kreislauf, und er ist tief menschlich.

## Jenseits eines einzelnen Repositoriums

Es gibt eine weitere Dimension an diesem Graphen, die ich besonders interessant finde. **Es kann nicht in einem einzigen Repository leben.** Der Kontextgraph muss zwischen Projekten teilbar sein und potenziell auch zwischen Organisationen.

Denk darüber nach: Ein Unternehmen hat eine Markensprache. Diese Stimme gilt für jedes Produkt, jede Website, jeden Support-Artikel. Sie lebt nicht in einem Repo. Sie ist eine querliegende Konzentration. Du könntest deine Kernstimme auf Organisationsebene definieren und dann auf Projektebene für ein bestimmtes Produkt oder Publikum Überlappungen anwenden. Dies ist **scope inheritance**, das gleiche Muster, dem wir uns in der Programmierung gewöhnt haben, aber auf den linguistischen Kontext angewendet.

Und dieser Kontext muss ordnungsgemäß versioniert werden. Man darf nicht einfach die Voice-Definition ändern und die vorherige Version löschen. Es gibt viel zu lernen darüber, wie [Git handles versioning](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) durch content-addressable storage und DAGs funktioniert. Git's Modell von Commits, Branches und Diffs befasst sich im Grunde darum, wie sich Dinge über die Zeit ändern, während der Zugriff auf jeden vorherigen Zustand erhalten bleibt. Genau das brauchen wir für den linguistischen Kontext.

Tatsächlich glauben wir, dass eine Stimmenänderung über etwas geschehen sollte, das wir eine *Stimmenänderungsanfrage*. So wie ein Pull-Request einen Raum für Diskussionen rund um Code-Änderungen schafft, schafft eine Stimmenänderungsanfrage einen Raum zur Diskussion linguistischer Änderungen. Warum wechseln wir zu einem konversationelleren Ton? Welche Auswirkungen wird das haben? Welche Inhalte sind betroffen? Das sind Gespräche, die wir führen sollten, bevor die Änderung propagiert.

## Wo Menschen kreativer werden, nicht weniger relevant

Und genau hier wird es wirklich interessant. Anstatt Menschen zu eliminieren, was die Erzählung ist, die viele Menschen vertreten, wenn sie über KI sprechen, dieses System **verleiht Menschen eine kreativere Rolle.**.

Stellen Sie sich ein Team von Linguisten und Content-Strategen vor, das in einer Sitzung Ideen zur sprachlichen Ausrichtung der Marke diskutiert. Sie könnten Konzepte erkunden, Tonfalländerungen debattieren, kulturellen Kontext referenzieren, auf den kein Modell Zugriff hat. Anstatt manuell Hunderte von Dateien zu aktualisieren, fassen sie ihre Entscheidungen als Anpassungen am Kontextgraphen fest. Das System übernimmt die Propagation.

Oder gehen wir es noch einen Schritt weiter: Stellen Sie sich agenzbasierte Sitzungen vor, in denen ein Linguist mit einem KI-Assistenten zusammenarbeitet, um linguistische Ideen zu erforschen. "Was wäre, wenn wir die Fehlermeldungen empathischer machen würden?" Der Agent simuliert die Auswirkungen, zeigt, wie sich der aktuelle Kontext verändern würde, und betrachtet eine Vorschau, wie der aktualisierte Inhalt aussehen könnte. Der Linguist verfeinert und passt an, und wenn er zufrieden ist, stellt er eine Kontextänderungsanfrage. Wäre das nicht etwas?

**Es geht nicht darum, den Linguisten zu ersetzen.** Es geht darum, ihnen bessere Werkzeuge an die Hand zu geben, um das zu tun, bei dem sie ohnehin schon stark sind: differenzierte, kulturgesteuerte Entscheidungen über Sprache zu treffen. Das System übernimmt die mechanischen Teile (Propagation, Auswirkungsanalyse, Konsistenz), während sich Menschen auf die kreativen Teile konzentrieren (Stimme, Ton und kulturelle Resonanz).

Ich kehre immer wieder zu dem zurück, was Nida mit der dynamischen Äquivalenz meinte. Das Ziel ist nicht linguistische Genauigkeit im mechanischen Sinne. Es geht darum, die gleiche gefühlte Beziehung zwischen Leser und Inhalt unabhängig von der Sprache zu schaffen. Das erfordert Geschmack, Urteilsvermögen und kulturelles Bewusstsein. Das sind Dinge, bei denen Menschen hervorragend sind und bei denen Modelle noch immer scheitern. Die Aufgabe des Systems besteht darin, zu gewährleisten, dass diese menschlichen Einsichten erfasst, strukturiert und wiederverwendbar sind.

## Was kommt als Nächstes

In einem Folgebeitrag gehen wir technischer und sprechen über die Rolle, die Sandboxen dabei spielen werden, Erfahrungen zu ermöglichen, die in diesem Bereich noch nicht gesehen wurden, und warum wir intensiv in APIs investieren. Es gibt eine ganze Dimension rund um Staging, Vorschau und das Testen linguistischer Änderungen, bevor sie live gehen, in die wir uns gerne vertiefen.

Wenn dies bei Ihnen Anklang findet, egal ob Sie als Linguist mit den aktuellen Tools frustriert sind, ein Entwickler, der bei Lokalisierungsabläufen zu kämpfen hatte, oder einfach jemand, der tief darüber nachdenkt, wie Sprache und Technologie zusammentreffen, würden wir uns freuen, von Ihnen zu hören.
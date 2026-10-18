%{
  title: "Die Übersetzung ist der leichte Teil",
  slug: "translation-is-the-easy-part",
  summary:
    "Wie Gespräche über Sprachen, Softwareauslieferung und Vertrauen María José und mich veranlassten, Glossia zu bauen.",
  author: "pedro"
}
---

Sprachen sind ein großartiges und oft unterschätztes Werkzeug für Barrierefreiheit, um Technologieprodukte auf neue Märkte zu bringen. Wenn Ihr Produkt an Gemeinschaften spricht, deren Hauptsprache nicht Englisch ist, signalisieren Sie, dass Sie an sie gedacht haben. So können Sie eine sehr tiefe Verbindung aufbauen.

Leider können sich viele Teams nicht leisten, Ihr Produkt und Ihre Marke auf mehrere Sprachen zu bringen. Sie müssen sich oft zwei von drei aussuchen: **Qualität, Geschwindigkeit und Kosten**.

Wenn sie Übersetzungen auf einen Software-Lieferprozess abstimmen möchten, können sie in ein dediziertes Team investieren, um die Qualität zu sichern – aber das kostet. Oder sie können stärker auf maschinelle Übersetzung setzen, schnell voran, aber geringere Qualität akzeptieren. Wenn sie Qualität und geringe Kosten wählen und auf menschliche Übersetzung ohne ein dediziertes Team setzen, müssen sie meist auf Geschwindigkeit verzichten. Dabei landen sie in verwobenen Systemen, die Übersetzungen zwischen ihren Repositories und Drittanbieter-Tools hin und her schieben.

Seit [große Sprachmodelle](https://en.wikipedia.org/wiki/Large_language_model) erscheinen, haben meine Frau, [María José](https://www.linkedin.com/in/mariajosesalmeron/), und ich viel darüber gesprochen, ob sie uns helfen könnten, auf solche Kompromisse zu verzichten. Sie liebt Sprachen und ist tief in der Lokalisierungsbranche verankert. Ich hingegen bin ein Erbauer.

Tuist ist mein Hauptgeschäft. Bei der Übersetzung des Produkts und seiner Marketingoberflächen hatte ich mich mit verschlungenen Lösungen zu tun. Keine davon hielt unserem Liefergeschwindigkeit stand. Einige führten zu Konflikten, die ein Albtraum waren zu lösen. Ich hatte das Moment «...das fühlt sich falsch an» vieler Male.

## Von Gesprächen zu Glossia

Jede Woche diskutierten wir neue Muster, die sich um die Fähigkeiten von Sprachmodellen bildeten. Wir sahen immer mehr Entwickler, die ihre eigenen Übersetzungs-Pipelines bauten. Im Kern zielen diese Pipelines auf ein Modell ab: Quell-Sprache rein, Übersetzung raus, dann einfach fortfahren.

Es fühlte sich verständlich an. Genau so agieren wir Erbauer. Aber jemand näher an den Sprachen und Prozessen könnte sehen, wie es fehlgehen könnte, von Inkonsistenzen bis hin zu Übersetzungsfehlern.

Entwickler bewegen sich immer schneller. Sie können nicht langsamer machen, um ein System einzuführen, dessen darunterliegende Workflows lange vor dem Internet entwickelt wurden, im Browser gelandet sind und dennoch Schwierigkeiten haben, den Bedürfnissen von Softwareteams zu entsprechen.

So begann die Idee, Glossia zu bauen. Auf der einen Seite setzen wir auf Modelle, die bei anderen Sprachen und Übersetzungen besser werden. Auf der anderen Seite bauen wir ein System, zunächst mit Fokus auf Software-Inhalte, das sich Plug-and-Play anfühlt. Etwas, das im Hintergrund läuft, Ihre Liefergeschwindigkeit passend, und Ihnen Sicherheit gibt, dass der Output korrekt ist und für die Produktion bereitsteht.

Viele Entwickler behandeln Übersetzungen als eine One-Prompt-Lösung. Ein paar Tokens, Englisch rein, Übersetzung raus, fertig. Aber wenn man mit ihnen spricht, merkt man, dass sie nicht wissen, ob der Output präzise ist, die Stimme ihrer Organisation in dieser Sprache einfängt oder die intendierte Nachricht effektiv übermittelt.

Ich habe eine ähnliche Pipeline bei Tuist, die in Sprachen wie Japanisch übersetzt, und ich mache das mit großer Unsicherheit. Sprachen sind keine Logik. Wir können Tests schreiben, um sicherzustellen, dass das Format korrekt ist, aber das sagt uns nicht **ob die Wörter richtig sind**.

«Übersetzung ist der leichte Teil», wie meine Frau gerne sagt.

Also machten wir uns daran zu ermitteln, wie das richtige System aussehen könnte. Wir nannten es Glossia und beginnen dafür, es für Menschen und Organisationen zu öffnen, die uns beim gemeinsamen Iterieren dabei helfen wollen.

## Entscheiden Sie, was übersetzt werden soll

Erstmals konzentrierten wir uns darauf, Menschen zu helfen, zu entscheiden, was übersetzt werden soll. Die Kosten für Übersetzungen gehen zurück und werden weiter zurückgehen, aber niemals bis auf Null. Organisationen sollten weiterhin informiert über Sprachen sein, in die sie investieren.

Manchmal folgt diese Entscheidung direkt aus einer Geschäftsentscheidung. Andere Male haben Teams eine grobe Vorstellung ihrer Gemeinschaften und treffen eine fundierte Vermutung. Wir dachten, es gäbe viel zu lernen von den Menschen, die Ihre Websites besuchen oder Ihre Apps verwenden. Ihre Präferenzen für Sprachen, kombiniert mit Informationen über die Regionen, aus denen Ihre Produkte genutzt werden, können Ihnen eine bessere Grundlage für diese Entscheidungen geben.

Die erste Funktion, die wir in Glossia landeten, war Analysen. Fügen Sie eine Zeile Code zu Ihrer Website hinzu, und Analysen beginnen, in Ihr Konto zu fließen. Wir präsentieren diese Informationen um die Entscheidung, die Sie treffen müssen: In welche Sprachen sollten Sie als Nächstes investieren?

Auf dem Weg dorthin werden wir untersuchen, wie Experimente in die Sprachdimension eines Produkts einfließen. Stellen Sie sich vor, Sie messen, wie oft人们 auf einen Call-to-Action klickt, wenn eine Seite unterschiedliche Stimmen in derselben Sprache verwendet. Würde das nicht cool sein? Das Vergleichen von Varianten hat sich traditionell um Produkt- und Designentscheidungen gruppiert, aber Sprachen sind auch Teil des Produkts.

## Von Null zu Übersetzung

Sobald Sie sich entschieden haben, ein Projekt zu übersetzen, ist der nächste Schritt das Einrichten desselben. Als Entwickler finde ich Prozesse, die mit viel Reibung kommen, abschätzig. Wir einigten uns darauf, dass der Weg von Null zu Übersetzung idealerweise in einem Schritt erfolgen sollte. Das ist die Erfahrungsebene, auf die wir hinarbeiten.

Die Einrichtung umfasst normalerweise zwei Dinge. Erstens, den Inhalt aus dem Repository extrahieren, damit er übersetzt werden kann, da er oft als wörtliche Strings im Code beginnt. Zweitens, das Projekt konfigurieren, um den richtigen Inhalt basierend auf der Sprache zu wählen. Das kommt möglicherweise vom Gerät des Benutzers oder, in mehr ausgefeilten Fällen, einer ihrer gewählten Präferenzen.

Dies zuverlässig vor automatisieren, vor wenigen Jahren hätte ein Albtraum sein können. Die Dinge haben sich geändert, und Agenten können dabei recht effektiv sein.

Das Verfahren läuft so: Sie verbinden Ihr GitHub-Repository, wählen die Sprachen aus, die Sie übersetzen möchten, und nach einer Weile öffnet sich ein Pull-Request mit den Änderungen. Sobald Sie ihn merged haben, beginnen die Übersetzungen. Das ist alles.

Wir halten Übersetzungen im Repository, gemeinsam mit den Formatprüfungen und anderen Validierungen, die Sie bereits im Rahmen des [kontinuierliche Integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions) ausführen. Die Übersetzungspipeline leitet die Ergebnisse dieser Prüfungen an den Übersetzungsagenten weiter. So beseitigt man eine ganze Klasse von Problemen, bei denen eine Plattform einen Pull-Request öffnet und Sie der Bewältigung fehlgeschlagener Prüfungen oder Merge-Konflikte überlässt.

In Kombination mit anderen Mechanismen zum Aufbau von Vertrauen kann dies ermöglichen, Übersetzungen automatisch zu mergen. Das ist das Modell, an das wir glauben. Es hat wenig Wert, einen Entwickler zu bitten, zu prüfen, ob ein Übersetzungs-Pull-Request grün ist und auf einen Button zu klicken, besonders wenn sie die Sprache selbst nicht beurteilen können. Wir haben diese zusätzliche Zeremonie immer als Zeichen dafür gesehen, dass das Design besser sein könnte.

Wir glauben, dass das beste Übersetzungssystem eines ist, das funktioniert, ohne dass Sie darüber nachdenken müssen.

## Nur das Übersetzen, was geändert wurde

Das Übersetzungssystem verdient seinen eigenen Abschnitt. Tokens sind immer noch nicht kostenlos. Alles immerdar zu übersetzen ist langsam, teuer und eine Verschwendung von Ressourcen.

Um dies zu lösen, haben wir ein Lockdatei-System gebaut, das uns sagt, ob etwas übersetzt werden muss. Wir nennen dies **inkrementelle Übersetzung**. Die Idee ist nicht neu: Buildsysteme haben es lange Zeit genutzt, um bei jedem Build nicht alles neu zu kompilieren. Wir haben es an Sprachen angepasst.

Das System berücksichtigt den gesamten Kontext, der eine bestimmte Übersetzung beeinflusst. Ein Teil dieses Kontexts lebt im Repository. Ein anderer Teil lebt in Glossia und erstrebt mehrere Repositories. Wir erstellen einen Abhängigkeitsbaum und verwenden [Merkle-Bäume](https://en.wikipedia.org/wiki/Merkle_tree), um Hashes zu berechnen, die uns anzeigen, ob sich die Eingaben einer Übersetzung geändert haben.

Die Lockdatei bewahrt diesen Baum auf. Sie kann erklären, warum etwas für die Übersetzung gesendet wurde, oder warum es nicht gesendet wurde, anstatt Menschen zu lassen, zu raten.

[`L10N.md`](/docs/reference/l10n-md) Dateien stellen Lokalisierungskontext für unsere Übersetzungsagenten bereit, ähnlich wie `AGENTS.md` Anweisungen für Codierungsagenten bereitstellen. Sie unterstützen mehr spezifischen Kontext in verschachtelten Verzeichnissen sowie Sprach-Überschreibungen auf jeder Ebene.

Für Informationen, die für mehr als eines Repositories zutreffen, wie z. B. geteilte Terminologie, ist der Server die wahre Quelle. Das System stellt sicher, dass es den richtigen Kontext verwendet und diesen in der Lockdatei widerspiegelt. Wenn sich dieser Kontext ändert, können wir die Änderung auf die Übersetzungen zurückführen, die ihn verwendet haben, und diese aktualisieren.

## Vertrauen in die Wörter aufbauen

Das System ist darauf ausgelegt, sich auf ein Qualitätsniveau zuzuspitzen. Um dorthin zu gelangen, verfügen wir über mehrere Werkzeuge.

Das erste sind gegnerische Prüfungen, die nach der Übersetzung laufen. Stellen Sie sich einen Kollegen vor, der den Code in einem Pull-Request überprüft. Hier bringen die Prüfungen linguistisches Wissen in die Überprüfung ein. Zum Beispiel sollte eine Übersetzung keine Bedeutung aus der Quelle hinzufügen oder entfernen. Dies kann passieren, weil Sprachmodelle nicht immer denselben Output aus denselben Eingaben erzeugen.

Je mehr wir von unseren Nutzern und unserer eigenen Forschung zu Modellen und bestehenden Systemen lernen, werden wir der Pipeline weitere automatische Prüfungen hinzufügen. Jede davon sollte das Vertrauen erhöhen, das Sie in eine Übersetzung haben können.

Die Idee ist, einen Punkt zu erreichen, an dem Sie dem System genug vertrauen, dass Sie nicht den Eindruck haben, muss jeden Pull-Request durchlaufen. Dieses Vertrauen hängt sowohl vom System als auch von den Modellen ab. Wir können helfen, Modelle basierend auf der Zielsprache auszuwählen, da nicht alle Modelle in denselben Sprachen gleich gut sind.

Auch mit diesen Prüfungen an Ort und Stelle müssen Sie möglicherweise eine übersetzte Stelle ändern. Es könnte eine einmalige Korrektur sein, Terminologie, die noch nicht im Kontext geschrieben wurde, oder eines der vielen Szenarien, die wir noch zu beabsichtigen haben.

Jemand sollte in der Lage sein, diese Änderungen direkt in das Repository einzuführen. Aber wir glauben auch, das System soll diese Beiträge als Feedback verarbeiten und vorschlagen, wie diese mit dem Kontext in Einklang gebracht werden sollen. Dies könnte bedeuten, einen Begriff im Glossar hinzuzufügen oder die Stimme anzupassen.

Dies etwas kann ein Mensch asynchron tun, ohne die kontinuierliche Übersetzung zu unterbrechen. Das System soll Ihnen helfen, den Arbeitsplatz effektiver zu machen, indem es aus dem, was die Leute zu sagen haben, lernt. Wir könnten dies erweitern, damit Menschen Feedback direkt aus dem Produkt vorschlagen. Würde das nicht cool sein?

Diese Korrekturen müssen ebenfalls berücksichtigt werden, damit zukünftige Übersetzungen sie nicht überschreiben. Ein zustandslosem Übersetzungsaufforderung hat kein Wissen über die Änderungen, die die Leute vor ihm gemacht haben. In traditionellen Systemen übernehmen Übersetzungsgedächtnisse diese Rolle. Die Notwendigkeit, die sie erfüllen, verschwindet nicht, einfach weil sich die Technologie ändert.

## Wo wir ab jetzt hinfahren

Dies ist Glossia. Wir verwenden es bereits, um Glossia zu übersetzen, und ich arbeite daran, es einzurichten, um Tuist's Dokumentation, Marketingseite und Dashboard in die Sprachen unserer Gemeinschaften zu übersetzen.

María José und ich bauen Glossia in unserer Freizeit, befolgend eine Neugier, die Teil unserer Unterhaltungen seit Jahren ist.

Im Programmieren stellen sich viele Personen die Rolle von Programmierern undfragefrage in Frage und wie es sich evolvieren wird. Ich denke, dass die Lokalisierungsbranche von einer ähnlichen Infragestellung ihrer Annahmen und Modelle profitieren würde. Wie sollen wir unsere Branche dabei helfen, schneller und zu niedrigeren Kosten zu übersetzen, ohne die Qualität zu beeinträchtigen?

Wir haben noch keine Antworten auf alle Fragen. Aber wir glauben, dass wir die richtige Richtung einschlagen, mit der Einfachheit und Aufmerksamkeit für Handwerkskunst, die wir gerne in alles investiert ist, das wir tun.

Wenn das auf Sie zutrifft, [lassen Sie uns sprechen](mailto:pedro@glossia.ai).

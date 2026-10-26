%{
  title: "Übersetzung ist der einfache Teil",
  slug: "translation-is-the-easy-part",
  summary:
    "Wie Gespräche über Sprachen, Softwareauslieferung und Vertrauen mich und María José dazu brachten, Glossia zu bauen.",
  author: "pedro"
}
---

Sprachen sind ein großartiges und oft unterschätztes Mittel für Barrierefreiheit und die Erschließung neuer Märkte für technische Produkte. Wenn Ihr Produkt Gemeinschaften anspricht, deren Muttersprache nicht Englisch ist, zeigen Sie, dass Sie an sie gedacht haben. Dies kann eine sehr tiefe Verbindung stiften.

Leider ist es für viele Teams schlicht nicht leistbar, dass Ihr Produkt und Ihre Marke auf mehrere Sprachen sprechen. Sie stellen sich oft vor, sich zwischen zwei von drei Optionen entscheiden zu müssen: **Qualität, Geschwindigkeit und Kosten**.

Wenn sie Übersetzungen dazu bringen wollen, mit der Softwareauslieferung Schritt zu halten, können sie in ein dediziertes Team zur Qualitätssicherung investieren, was jedoch Kosten verursacht. Oder sie können stärker auf maschinelle Übersetzungen setzen, schnell vorankommen, aber eine geringere Qualität akzeptieren. Wenn sie Qualität und geringe Kosten wählen und menschliche Übersetzungen ohne ein dediziertes Team nutzen, opfern sie meist die Geschwindigkeit. Auf diesem Weg landen sie schließlich mit komplexen Systemen, die Übersetzungen zwischen ihren Repositories und Drittanbieter-Tools hin- und herschieben.

Seit [große Sprachmodelle](https://en.wikipedia.org/wiki/Large_language_model) entstehen sind, habe ich viel mit meiner Frau, [María José](https://www.linkedin.com/in/mariajosesalmeron/), darüber gesprochen, ob sie uns dabei helfen könnten, auf solche Abwägungen zu verzichten. Sie liebt Sprachen und ist im Lokalisierungssektor tief verankert. Ich bin ein Entwickler.

Tuist ist meine Hauptbeschäftigung. Als ich versuchte, das Produkt und seine Marketing-Oberflächen zu übersetzen, stellte ich fest, dass ich mit verworrenen Lösungen kämpfen musste. Keine davon hielt Schritt mit unserer Liefergeschwindigkeit, und einige führten zu Konflikten, deren Lösung ein Albtraum war. Ich hatte dieses "das fühlt sich falsch an"-Moment immer wieder.

## Von Gesprächen zu Glossia

Jede Woche diskutierten wir neue Muster rund um die Fähigkeiten von Sprachmodellen. Wir sahen mehr und mehr Entwickler, die eigene Übersetzungs-Pipelines bauten. Im Kern forderten diese Pipelines ein Modell: Ausgangssprache rein, Übersetzung raus, dann weitermachen.

Es fühlte sich verständlich an. So arbeiten wir Entwickler. Doch jemand, der näher an Sprachen und den umliegenden Prozessen ist, könnte sehen, wie es schiefgehen kann, von Inkonsistenzen im besten Fall bis zu Falschübersetzungen im schlimmsten Fall.

Entwickler bewegen sich immer schneller. Sie können nicht verlangsamen, um ein System zu einführen, dessen zugrundeliegende Abläufe lange vor dem Internet entworfen wurden, in einen Browser verlagert wurden und immer noch Schwierigkeiten haben, die Bedürfnisse von Softwareteams zu erfüllen.

So begann die Idee, Glossia zu bauen. Auf der einen Seite würden wir darauf wetten, dass Modelle besser in anderen Sprachen als Englisch und in Bezug auf Übersetzungen werden. Auf der anderen Seite würden wir ein System bauen, das zunächst auf Software-Inhalte fokussiert, sich plug and play anfühlt. Etwas, das im Hintergrund läuft, Ihre Liefergeschwindigkeit entspricht und Ihnen Sicherheit gibt, dass die Ausgabe korrekt und für die Produktion bereit ist.

Viele Entwickler betrachten Übersetzungen als eine One-Prompt-Lösung. Ein paar Token, Englisch rein, Übersetzung raus, und damit ist es erledigt. Aber wenn du mit ihnen sprichst, merkst du, dass sie nicht wissen, ob die Ausgabe akkurat ist, die Stimme ihrer Organisation in dieser Sprache einfängt oder die beabsichtigte Botschaft effektiv vermittelt.

Ich habe eine ähnliche Pipeline bei Tuist, Übersetzungen in Sprachen wie das Japanische, und mache dies mit einem enormen Mangel an Vertrauen. Sprachen sind keine Logik. Wir können Tests schreiben, um sicherzustellen, dass das Format korrekt ist, aber das verrät uns nicht **ob die Wörter stimmen**.

"Übersetzung ist der einfache Teil", wie meine Frau meint.

Wir machten uns also daran, herauszufinden, wie das richtige System aussehen könnte. Wir nannten es Glossia und beginnen, es für Menschen und Organisationen zugänglich zu machen, die daran interessiert sind, es gemeinsam zu verbessern.

## Was übersetzt werden soll

Der erste Schwerpunkt war es, Menschen dabei zu helfen, zu entscheiden, was übersetzt werden soll. Die Kosten für Übersetzungen sinken und werden weiter sinken, werden aber nie auf null fallen. Organisationen sollten weiterhin selektiv bei den Sprachen sein, in die sie investieren.

Manchmal ergibt sich diese Entscheidung direkt aus einer Geschäftsentscheidung. Manchmal haben Teams eine grobe Vorstellung von ihren Communities und treffen eine fundierte Entscheidung. Wir dachten, es viel zu lernen gibt von den Personen, die Ihre Websites besuchen oder Ihre Apps nutzen. Ihre Sprachpräferenzen, kombiniert mit Informationen über die Regionen, aus denen sie Ihre Produkte nutzen, können Ihnen eine bessere Grundlage für diese Entscheidungen geben.

Die erste Funktion, die wir in Glossia landeten, war Analytik. Fügen Sie eine Zeile Code zur Website hinzu, und Analytik beginnt in Ihr Konto zu fließen. Wir präsentieren diese Informationen um die Entscheidung herum, die Sie treffen müssen: In welche Sprachen sollten Sie investieren?

In Zukunft werden wir untersuchen, wie Experimente in die Sprachdimension eines Produkts integriert werden können. Stellen Sie sich vor, wie oft Menschen auf einen Call to action klicken, wenn eine Seite unterschiedliche Stimmen in derselben Sprache verwendet. Würde das nicht cool sein? Das Vergleichen von Varianten fokussiert sich traditionell auf Produkt- und Designentscheidungen, aber Sprachen sind auch Teil des Produkts.

## Von Null zur Übersetzung

Sobald Sie entschieden haben, ein Projekt zu übersetzen, ist der nächste Schritt, es einzurichten. Als Entwickler lehne ich Prozesse ab, die mit viel Reibung verbunden sind. Wir sind uns einig, dass der Weg von Null zur Übersetzung ideal ein Schritt dauert. Das ist das Niveau der Erfahrung, für das wir uns einsetzen.

Die Einrichtung umfasst normalerweise zwei Dinge. Erstens, extrahieren Sie den Inhalt aus dem Repository, damit er übersetzt werden kann, da er oft als wörtliche Zeichenketten im Code beginnt. Zweitens, konfigurieren Sie das Projekt, um den richtigen Inhalt basierend auf der Sprache auszuwählen. Das könnte vom Gerät des Benutzers kommen oder, in komplexeren Fällen, eine Präferenz, die sie gewählt haben.

Eine Automatisierung dies verlässlich vor ein paar Jahren wäre ein Albtraum gewesen. Die Dinge haben sich geändert, und Agenten können dabei ganz effektiv sein.

Der Prozess verläuft wie folgt: Du verbindest dein GitHub-Repository, wählst die Sprachen aus, in die du übersetzen möchtest, und nach einer Weile öffnet sich eine Pull Request mit den Änderungen. Sobald du sie zusammenfügst, beginnen Übersetzungen zu passieren. Das war's.

Wir halten Übersetzungen im Repository, zusammen mit Formatchecks und anderen Validierungen, die Sie im Rahmen von [Continuous Integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions) bereits durchführen. Die Übersetzungs-Pipeline speist die Ergebnisse dieser Checks zurück an den Übersetzungsagenten. Dadurch entfallen eine ganze Klasse von Problemen, bei denen eine Plattform eine Pull Request öffnet und Sie am Ende mit fehlgeschlagenen Checks oder Merge-Konflikten allein gelassen werden.

In Kombination mit anderen Mechanismen zum Aufbau von Vertrauen ist dies das, was automatisches Mergen von Übersetzungen ermöglicht. Das ist das Modell, an das wir glauben. Es gibt wenig Wert daran, einen Entwickler zu bitten, zu prüfen, ob eine Übersetzungs-Pull Request grün ist und auf einen Button zu klicken, besonders wenn sie selbst die Sprache nicht einschätzen können. Wir haben diese zusätzliche Zeremonie immer als Zeichen dafür gesehen, dass das Design besser sein könnte.

Wir glauben, dass das beste Übersetzungssystem eines ist, das funktioniert, ohne dass Sie darüber nachdenken müssen.

## Nur das Übersetzen von Verändertes

Das Übersetzungssystem verdient eine eigene Sektion. Tokens sind noch nicht kostenlos. Alles immer übersetzen ist langsam, teuer und verschwenderisch mit Ressourcen.

Um das zu lösen, haben wir ein Lockfile-System aufgebaut, das uns sagt, ob etwas übersetzt werden muss. Wir nennen das **inkrementelle Übersetzung**. Die Idee ist nicht neu: Build-Systeme verwenden sie seit langem, um beim每一 Build nicht alles neu zu compilieren. Wir haben sie auf Sprachen angepasst.

Das System berücksichtigt den gesamten Kontext, der eine bestimmte Übersetzung betrifft. Ein Teil dieses Kontextes lebt in dem Repository. Ein Teil lebt in Glossia und erstreckt sich über mehrere Repositories. Wir bauen eine Abhängigkeitsbaum und verwenden [Merkle trees](https://en.wikipedia.org/wiki/Merkle_tree), um Hashes zu berechnen, die uns sagen, ob die Eingaben einer Übersetzung sich geändert haben.

Das Lockfile bewahrt diesen Baum. Es kann erklären, warum etwas zur Übersetzung geschickt wurde, oder warum es nicht, anstatt die Menschen raten zu lassen.

[`L10N.md`](/docs/reference/l10n-md) Dateien bieten Lokalisierungskontext unseren Übersetzungsagenten, ähnlich wie `AGENTS.md` Dateien Anweisungen für Coding-Agenten geben. Sie unterstützen spezifischeren Kontext in verschachtelten Verzeichnissen sowie Sprach-Overrides auf jeder Ebene.

Für Informationen, die sich auf mehr als eines Repository auswirken, wie zum Beispiel geteilte Terminologie, ist der Server die Quelle der Wahrheit. Das System stellt sicher, dass es den richtigen Kontext verwendet und diesen spiegelt im Lockfile wider. Wenn dieser Kontext sich ändert, können wir die Änderung auf die Übersetzungen zurückmappen, die ihn verwendet haben und aktualisiert werden müssen.

## Vertrauen in die Wörter aufbauen

Das System ist darauf ausgelegt, zu einem Qualitätsniveau zu konvergieren. Um dorthin zu gelangen, haben wir mehrere Werkzeuge.

Die erste sind adversariale Checks, die nach der Übersetzung ausgeführt werden. Stellen Sie sich einen Kollegen vor, der den Code überprüft, den Sie in einer Pull Request eingeschlossen haben. Hier bringen die Checks linguistisches Wissen in die Überprüfung mit ein. Zum Beispiel sollte eine Übersetzung die Bedeutung der Quelle nicht hinzufügen oder entfernen. Das kann geschehen, da Sprachmodelle nicht immer dasselbe Ausgabe aus denselben Eingaben produzieren.

Je mehr wir von unseren Nutzern lernen und von unserer eigenen Forschung zu Modellen und bestehenden Systemen, werden wir weitere automatisierte Checks in die Pipeline aufnehmen. Jeder sollte das Vertrauen erhöhen, das Sie in eine Übersetzung haben können.

Die Idee ist, einen Punkt zu erreichen, an dem Sie dem System vertrauen, dass Sie nicht mehr das Bedürfnis verspüren, jede Pull Request durchzugehen. Dieses Vertrauen hängt sowohl vom System als auch von den Modellen ab. Wir können dabei helfen, Modelle basierend auf der Zielsprache auszuwählen, da nicht alle Modelle gleich gut bei denselben Sprachen sind.

Selbst mit diesen Checks können Sie eventuell ein übersetztes Stück ändern müssen. Es könnte eine Einmalskorrektur sein, Terminologie, die noch nicht in den Kontext geschrieben wurde, oder eines der vielen Szenarien, mit denen wir es noch zu tun haben.

Jemand sollte in der Lage sein, diese Beiträge direkt ins Repository einzubringen. Aber wir glauben auch, dass das System diese Beiträge als Feedback verarbeiten und anbieten sollte, wie sie mit seinem Kontext abgeglichen werden sollen. Das könnte bedeuten, einen Begriff zum Glossar hinzu fügen oder die Stimme anzupassen.

Das ist etwas, das ein Mensch asynchron tun kann, ohne kontinuierliche Übersetzung zu unterbrechen. Das System sollte Ihnen dabei helfen, es effektiver in seiner Arbeit zu machen, indem es aus dem lernt, was die Menschen zum Ausdruck bringen. Können wir das erweitern zu Leuten, die Feedback direkt aus dem Produkt vorschlagen. Würde das nicht cool sein?

Diese Korrekturen müssen auch berücksichtigt werden, damit zukünftige Übersetzungen sie nicht überschreiben. Ein stateless Translation-Call hat kein Wissen über die Änderungen, die die Menschen vor ihm vorgenommen haben. In traditionellen Systemen helfen Übersetzungsgedächtnisse, diese Rolle zu füllen. Der Bedarf, den sie bedienen, verschwindet nicht einfach, weil sich die Technologie ändert.

## Von hier aus wohin wir gehen

Dies ist Glossia. Wir verwenden sie bereits, um Glossia zu übersetzen, und ich arbeite daran, sie einzurichten, um Tuist's Dokumentation, Marketing-Website und Dashboard in die Sprachen unserer Gemeinschaften zu übersetzen.

María José und ich bauen Glossia in unserer Freizeit auf, folgen einer Neugier, die seit Jahren Teil unserer Konversationen ist.

In der Programmierung hinterfragen viele Menschen die Rolle von Programmierern und wie sie sich entwickeln wird. Ich glaube, die Lokalisierungs-Branche würde von einer ähnlichen Infragestellung ihrer Annahmen und Modelle profitieren. Wie können wir unserer Branche dabei helfen, mehr, schneller und zu niedrigeren Kosten zu übersetzen, ohne Qualität zu beeinträchtigen?

Wir haben noch keine Antworten auf alle Fragen. Aber wir glauben, dass wir in die richtige Richtung unterwegs sind, mit der Einfachheit und Handwerksaufmerksamkeit, die wir gerne in alles investiert machen, was wir tun.

Ist dies mit Ihnen in Resonanz, [lassen Sie uns reden](mailto:pedro@glossia.ai).

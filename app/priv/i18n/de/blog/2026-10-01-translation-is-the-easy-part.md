%{
  title: "Übersetzung ist der einfache Teil",
  slug: "translation-is-the-easy-part",
  summary:
    "Wie Gespräche über Sprachen, Softwareauslieferung und Vertrauen María José und mich dazu brachten, Glossia zu bauen.",
  author: "pedro"
}
---

Sprachen sind ein großartiges und unterbewertetes Werkzeug für Barrierefreiheit und das Erschließen neuer Märkte für Technologieprodukte. Wenn Ihr Produkt Gemeinschaften anspricht, deren Hauptsprache nicht Englisch ist, signalisieren Sie, dass Sie an sie gedacht haben. So können Sie eine sehr tiefe Verbindung aufbauen.

Leider können sich viele Teams nicht leisten, ihr Produkt und ihre Marke in mehreren Sprachen sprechen zu lassen. Sie müssen sich oft für zwei von drei entscheiden: **Qualität, Geschwindigkeit und Kosten**.

Wenn sie möchten, dass Übersetzungen mit der Softwareauslieferung Schritt halten, können sie in eine dedizierte Mannschaft investieren, um die Qualität zu wahren, aber das kostet etwas. Oder sie können stärker auf maschinelle Übersetzung setzen, schnell voranschreiten und niedrigere Qualität akzeptieren. Wenn sie Qualität und niedrigen Kosten wählen und auf menschliche Übersetzung ohne ein dediziertes Team vertrauen, opfern sie in der Regel Geschwindigkeit. Auf ihrem Weg landen sie mit verworrenen Systemen, die Übersetzungen zwischen ihren Repositories und Drittanbieter-Tools schieben und ziehen.

Seit [Große Sprachmodelle](https://en.wikipedia.org/wiki/Large_language_model) aufgetaucht sind, habe ich viel mit meiner Frau, [María José](https://www.linkedin.com/in/mariajosesalmeron/), darüber gesprochen, ob sie uns dabei helfen können, diese Kompromisse zu beenden. Sie liebt Sprachen und ist tief im Lokalisierungsmarkt verwurzelt. Ich bin ein Builder.

Tuist ist meine Hauptbeschäftigung. Als ich versuchte, das Produkt und seine Marketing-Oberflächen zu übersetzen, habe ich festgestellt, dass ich mit verworrenen Lösungen zu kämpfen hatte. Keines davon konnte mithalten mit unserer Auslieferungsgeschwindigkeit, und einige führten zu Konflikten, die ein Albtraum waren zu lösen. Ich habe diesen Moment, „ dies fühlt sich falsch an “, viele Male erlebt.

## Von Gesprächen zu Glossia

Jede Woche diskutierten wir über neue Muster, die sich um die Fähigkeiten von Sprachmodellen ergaben. Wir sahen immer mehr Entwickler, die ihre eigenen Übersetzungs-Pipelines aufbauten. Im Kern legten diese Pipelines ein Modell fest: Quellsprache rein, Übersetzung raus, dann weitermachen.

Das fühlte sich verständlich an. Das ist, wie wir Builder arbeiten. Aber jemand, der näher an Sprachen und den Prozessen darum herum ist, könnte sehen, wie es schief gehen könnte, von Inkonsistenzen bis hin zu bestenfällen falschen Übersetzungen.

Entwickler bewegen sich immer schneller. Sie können nicht langsamen, um ein System einzuführen, dessen zugrundeliegende Workflows lange vor dem Internet entworfen wurden, in einen Browser umgezogen sind und trotzdem Schwierigkeiten haben, die Bedürfnisse von Softwareteams zu erfüllen.

So begann die Idee, Glossia aufzubauen. Auf einer Seite würden wir darauf wetten, dass Modelle bei anderen Sprachen außer Englisch und bei Übersetzungen besser werden. Auf der anderen Seite würden wir ein System bauen, das zunächst auf Software-Inhalte fokussiert ist, das sich plug-and-play anfühlte. Etwas, das im Hintergrund läuft, mit Ihrer Auslieferungsgeschwindigkeit übereinstimmt und Ihnen Sicherheit gibt, dass die Ausgabe richtig ist und für die Produktion bereit.

Viele Entwickler sehen Übersetzung als eine Ein-Prompt-Lösung an. Einige Token, Englisch rein, Übersetzung raus, und es ist erledigt. Aber wenn Sie mit ihnen sprechen, erkennen Sie, dass sie nicht wissen, ob die Ausgabe genau ist, die Stimme ihrer Organisation in dieser Sprache einfängt oder die beabsichtigte Botschaft effektiv kommuniziert.

Ich habe eine ähnliche Pipeline bei Tuist, übersetzte in Sprachen wie Japanisch, und ich tue das mit einem riesigen Mangel an Vertrauen. Sprachen sind keine Logik. Wir können Tests schreiben, um sicherzustellen, dass das Format korrekt ist, aber das sagt uns nicht **ob die Wörter richtig sind**.

“Übersetzung ist der leichte Teil,“, wie meine Mutter gerne sagt.

So machten wir uns darauf fest, wie das richtige System aussehen könnte. Wir nannten es Glossia, und wir beginnen damit, es für Leute und Organisationen zu öffnen, die uns dabei helfen wollen, gemeinsam daran zu iterieren.

## Entscheiden, was zu übersetzen ist

Der erste Teil, an dem wir arbeiteten, war es Menschen zu helfen, zu entscheiden, was zu übersetzen ist. Die Kosten für Übersetzung gehen nach unten und werden weiter abnehmen, aber sie werden niemals null sein. Organisationen sollten bei den Sprachen, die sie investieren, immer noch selektiv sein.

Manchmal folgt diese Entscheidung direkt aus einer Geschäftsentscheidung. Anderenfalls haben Teams eine grobe Vorstellung ihrer Gemeinschaften und machen eine fundierte Vermutung. Wir glauben, dass es viel zu lernen gibt von den Menschen, die Ihre Websites besuchen oder Ihre Apps verwenden. Ihre Sprachpräferenzen, kombiniert mit Informationen über die Regionen, aus denen Sie Ihre Produkte verwenden, können Ihnen eine bessere Grundlage für diese Entscheidungen geben.

Die erste Funktion, die wir in Glossia gelandet haben, war Analytik. Fügen Sie eine Zeile Code in Ihre Website ein, und Analytik beginnt, in Ihr Konto zu strömen. Wir präsentieren diese Informationen um die Entscheidung, die Sie treffen müssen: In welche Sprachen sollten Sie an Ihrecio investieren?

Langfristig werden wir untersuchen, wie wir Experimente in die Sprachdimension eines Produkts einbringen. Stellen Sie sich vor, Sie messen, wie oft Leute auf einen Call-to-Action klicken, wenn eine Seite verschiedene Stimmen in derselben Sprache verwendet. Würde das nicht cool sein? Das Vergleichen von Varianten hat traditionell um Produkt- und Designentscheidungen gravitiert, aber Sprachen sind auch Teil des Produkts.

## Von null zu Übersetzung

Indem Sie entschieden haben, ein Projekt zu übersetzen, ist der nächste Schritt, es aufzusetzen. Als Entwickler mag ich Prozesse, die mit viel Reibung kommen. Wir haben vereinbart, dass der Weg von null zu Übersetzung am besten nur einem Schritt bedurfte. Das ist das Erfahrungsniveau, das wir anstreben.

Aufsetzungen enthalten meist zwei Dinge. Erstens, den Inhalt aus dem Repository extrahieren, damit er übersetzt werden kann, da er oft als wörtliche Strings im Code beginnt. Second, das Projekt konfigurieren, um den richtigen Inhalt basierend auf der Sprache zu wählen. Das könnte vom Usersgerät kommen oder, in den raffinierteren Fällen, eine Präferenz, die sie gewählt haben.

Diese zuverlässig vor ein paar Jahren zu automatisieren wäre ein Albtraum gewesen. Die Dinge haben sich geändert, und Agenten können dabei recht effektiv sein.

Der Prozess läuft so ab: Sie verbinden Ihr GitHub-Repository, wählen die Sprachen aus, in die Sie übersetzen möchten, und nach einer Weile öffnet sich ein Pull-Request mit den Änderungen. Sobald Sie ihn merged haben, beginnen Übersetzungen. Das ist es.

Speichern wir Übersetzungen im Repository, gemeinsam mit Formatprüfungen und anderen Validierungen, die Sie bereits im Rahmen von [kontinuierlicher Integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions) durchführen. Die Übersetzungs-Pipeline führt die Ergebnisse dieser Prüfungen zurück an den Übersetzungs-Agent. Dadurch werden eine ganze Klasse von Problemen beseitigt, bei denen eine Plattform einen Pull-Request erstellt und Ihnen überlässt, fehlgeschlagene Prüfungen oder Merge-Konflikte zu lösen.

Kombiniert mit anderen Mechanismen zur Vertrauensbildung ist dies das, was eine automatische Zusammenführung von Übersetzungen ermöglicht. Das ist das Modell, an das wir glauben. Es gibt wenig Wert darin, einen Entwickler zu bitten, zu prüfen, ob ein Übersetzungs-Pull-Request grün ist, und einen Knopf zu klicken, insbesondere wenn er die Sprache selbst nicht bewerten kann. Wir haben immer diese zusätzliche Zeremonie als Anzeichen dafür gesehen, dass das Design bessere sein könnte.

Wir glauben, dass das beste Übersetzungssystem eines ist, das funktioniert, ohne dass Sie darüber nachdenken müssen.

## Nur Übersetzen geänderter Inhalte

Das Übersetzungssystem verdient einen eigenen Abschnitt. Tokens sind immer noch nicht kostenlos. Das ständige, gleichzeitige Übersetzen von allem ist langsam, teuer und verschwendet Ressourcen.

Um das zu lösen, haben wir ein Filesystem für Sperrdateien entwickelt, das uns sagt, ob etwas übersetzt werden muss. Wir nennen dies **inkrementelle Übersetzung**. Die Idee ist nicht neu: Bausysteme nutzen sie seit langem, um nichts auf jedem Build erneut zu kompilieren. Wir haben sie an Sprachen angepasst.

Das System berücksichtigt alle Kontextdaten, die eine bestimmte Übersetzung beeinflussen.某个 dieser Kontextdaten lebt im Repository. Ein anderer lebt in Glossia und erstreckt sich über mehrere Repositories. Wir erstellen einen Abhängigkeitsbaum und verwenden [Merkle-Bäume](https://en.wikipedia.org/wiki/Merkle_tree), um Hashes zu berechnen, die uns darauf hinweisen, ob die Eingaben einer Übersetzung geändert wurden.

Die Sperrdatei bewahrt diesen Baum. Sie kann erklären, warum etwas für Übersetzungen gesendet wurde, oder warum nicht, statt Menschen raten zu lassen.

[`L10N.md`](/docs/reference/l10n-md) Dateien bieten Kontext für unsere Übersetzungs-Agenten, ähnlich wie `AGENTS.md` Dateien Anweisungen für Coding-Agenten bieten. Sie unterstützen spezifischere Kontextdaten in verschachtelten Verzeichnissen sowie Sprach-Übersetzungen auf jeder Ebene.

Für Informationen, die sich auf mehr als ein Repository beziehen, wie z. B. gemeinsame Terminologie, ist der Server die Quelle der Wahrheit. Das System stellt sicher, dass es den richtigen Kontext verwendet und dies in der Sperrdatei widerspiegelt. Wenn sich dieser Kontext ändert, können wir die Änderung auf die Übersetzungen abbilden, die sie verwendet haben und aktualisiert werden müssen.

## Vertrauen in die Worte aufbauen

Das System ist so designed, dass es sich einem Qualitätsniveau annähert. Um dorthin zu gelangen, haben wir einige Werkzeuge.

Das erste sind antagonistische Prüfungen, die nach der Übersetzung durchgeführt werden. Stellen Sie sich vor, ein Kollege revidiert den Code, den Sie in einen Pull-Request aufgenommen haben. Hier bringen die Prüfungen linguistisches Wissen in die Überprüfung ein. Zum Beispiel sollte eine Übersetzung keine Bedeutung aus der Quelle hinzufügen oder entfernen. Das kann passieren, weil Sprachmodelle nicht immer die gleiche Ausgabe aus denselben Eingaben produzieren.

Je mehr wir von unseren Nutzern und unserer eigenen Forschung zu Modellen und bestehenden Systemen lernen, fügen wir der Pipeline mehr automatisierte Prüfungen hinzu. Jede sollte das Vertrauen erhöhen, das Sie in eine Übersetzung haben können.

Die Idee besteht darin, einen Punkt zu erreichen, an dem Sie dem System genug vertrauen, dass Sie keine Lust mehr haben, jeden Pull-Request durchzugehen. Dieses Vertrauen hängt sowohl vom System als auch von den Modellen ab. Wir können helfen, Modelle basierend auf der Zielsprache auszuwählen, da nicht alle Modelle gleich gut in denselben Sprachen sind.

Selbst mit diesen Prüfungen im Ort müssen Sie möglicherweise einen übersetzten Teil ändern. Es könnte eine einmalige Korrektur sein, Terminologie, die noch nicht in den Kontext geschrieben wurde, oder eine der vielen Szenarien, die wir noch vorfinden werden.

Jemand sollte in der Lage sein, diese Änderungen direkt ins Repository einzuziehen. Aber wir denken auch, das System sollte diese Beiträge als Feedback verarbeiten und vorschlagen, wie sie mit seinem Kontext harmonisiert werden. Das könnte bedeuten, einen Begriff in das Glossar einzufügen oder die Stimme anzupassen.

Das kann ein Mensch asynchron tun, ohne kontinuierliche Übersetzungen zu unterbrechen. Das System sollte Ihnen dabei helfen, in Ihrer Aufgabe effektiver zu werden, indem es aus dem, was Menschen sagen, lernt. Wir könnten das auf Menschen erweitern, die direkt aus dem Produkt Feedback vorschlagen. Würde das nicht cool sein?

Auch diese Korrekturen müssen berücksichtigt werden, damit künftige Übersetzungen sie nicht überschreiben. Ein Zustandloses Übersetzungsaustauschen kennt nicht die Änderungen, die Menschen vor ihm vorgenommen haben. In herkömmlichen Systemen helfen Übersetzungsgedächtnisse dabei. Das Bedürfnis, das sie erfüllen, verschwindet nicht nur, weil sich die Technologie ändert.

## Wo wir hin gehen

Das ist Glossia. Wir verwenden es bereits, um Glossia zu übersetzen, und ich arbeite daran, es einzurichten, um Tuist's Dokumentation, Marketingseite und Dashboard in die Sprachen unserer Communities zu übersetzen.

María José und ich bauen Glossia in unserer Freizeit, befolgend eine Neugier, die schon seit Jahren Teil unserer Gespräche ist.

In der Programmierung hinterfragen viele Menschen die Rolle von Programmieren und wie sich diese entwickeln wird. Ich denke, die Lokalisierungsindustrie würde von einem ähnlichen Hinterfragen von deren Annahmen und Modellen profitieren. Wie können wir unserer Industrie helfen, mehr, schneller und zu niedrigeren Kosten zu übersetzen, ohne Qualität zu kompromittieren?

Wir haben die Antworten auf alle Fragen noch nicht. Aber wir glauben, wir gehen in die richtige Richtung, mit der Einfachheit und Sorgfalt, die wir gerne in alles einbringen, was wir tun.

Wenn Sie das spüren, [Lass uns sprechen](mailto:pedro@glossia.ai).

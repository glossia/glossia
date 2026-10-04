%{
  title: "Übersetzung ist der einfache Teil",
  slug: "translation-is-the-easy-part",
  summary:
    "Wie Gespräche über Sprachen, Softwarebereitstellung und Vertrauen María José und mich dazu brachten, Glossia zu bauen.",
  author: "pedro"
}
---
Sprachen sind ein großartiges und oft unterschätztes Werkzeug für Barrierefreiheit und den Zugang von Tech-Produkten zu neuen Märkten. Wenn Ihr Produkt zu Gemeinschaften spricht, deren Hauptsprache nicht Englisch ist, zeigen Sie, dass Sie an sie gedacht haben. Das kann eine sehr tiefe Verbindung schaffen.

Leider können es sich viele Teams nicht leisten, ihr Produkt und ihre Marke in mehreren Sprachen anbieten zu lassen. Sie müssen sich oft für zwei der folgenden drei Dinge entscheiden: **Qualität, Geschwindigkeit und Kosten**.

Wenn Übersetzungen Schritt mit der Softwareauslieferung halten sollen, können sie in ein dediziertes Team investieren, um Qualität zu erhalten, doch das kostet. Oder sie können stärker auf maschinelle Übersetzung setzen, bewegen sich schneller, akzeptieren aber geringere Qualität. Wenn sie Qualität und niedrige Kosten wählen und auf menschliche Übersetzung ohne ein dediziertes Team setzen, opfern sie Geschwindigkeit. Dabei landen sie mit verworrenen Systemen, die Übersetzungen zwischen ihren Repositories und Drittanbieter-Tools koordinieren.

Seit [Große Sprachmodelle](https://en.wikipedia.org/wiki/Large_language_model) aufgetaucht sind, meine Frau, [María José](https://www.linkedin.com/in/mariajosesalmeron/), und ich habe viel darüber gesprochen, ob sie uns helfen könnten, diese Kompromisse zu stoppen. Sie liebt Sprachen und ist tief in der Lokalisierungsbranche verwurzelt. Ich bin ein Entwickler.

Tuist ist meine Hauptbeschäftigung. Als ich das Produkt und seine Marketingflächen versuchen wollte zu übersetzen, geriet ich in verwobene Lösungen. Keine davon hielt mit unserer Liefergeschwindigkeit Schritt, und einige führten zu Konflikten, die ein Albtraum waren, sie zu lösen. Ich hatte diesen Moment vieler Male, wo es sich falsch anfühlte.

## Von Gesprächen zu Glossia

Jede Woche diskutierten wir neue Muster, die sich um die Fähigkeiten von Sprachmodellen herum bildeten. Wir sahen immer mehr Entwickler, die ihre eigenen Übersetzungspipelines bauten. Im Kern forderten diese Pipelines ein Modell: Quellsprache ein, Übersetzung aus, dann fortsetzen.

Das erschien nachvollziehbar. So arbeiten wir Entwickler. Aber jemand, der näher an Sprachen und den damit verbundenen Prozessen stand, konnte sehen, wie es schiefgehen könnte, von Inkonsistenzen im besten Fall bis hin zu Fehlbegriffen im schlimmsten Fall.

Entwickler bewegen sich immer schneller vorwärts. Sie können nicht ausbremsen, um ein System einzuführen, dessen grundlegende Abläufe lange vor dem Internet entwickelt wurden, in den Browser verlegt wurden und es nach wie vor schwer haben, die Bedürfnisse von Softwareteams zu erfüllen.

So entstand die Idee, Glossia zu bauen. Auf der einen Seite würden wir Modelle vertrauen, die bei Sprachen außer Englisch und bei Übersetzungen besser werden. Auf der anderen Seite würden wir ein System bauen, das zunächst auf Softwareinhalte ausgerichtet war und sich Plug-and-Play anfühlte. Etwas, das im Hintergrund läuft, Ihre Liefergeschwindigkeit entspricht und Ihnen Sicherheit gibt, dass die Ausgabe korrekt und produktionsbereit ist.

Viele Entwickler betrachten Übersetzung als eine One-Prompt-Lösung. Einige Tokens, Englisch rein, Übersetzung raus, und damit erledigt. Doch wenn Sie mit ihnen sprechen, merken Sie, dass sie nicht wissen, ob der Output korrekt ist, die Stimme ihrer Organisation in dieser Sprache einfängt oder die beabsichtigte Botschaft effektiv übermittelt.

Ich habe eine ähnliche Pipeline bei Tuist, die in Sprachen wie Japanisch übersetzt, und ich tue dies mit einem massiven Mangel an Vertrauen. Sprachen sind keine Logik. Wir können Tests schreiben, um sicherzustellen, dass das Format korrekt ist, aber das sagt uns nicht **ob die Wörter richtig sind**.

„Übersetzung ist der einfache Teil,” wie meine Frau gerne sagt.

So machten wir uns daran, herauszufinden, wie das richtige System aussehen könnte. Wir nannten es Glossia und beginnen nun, es für Menschen und Organisationen zu öffnen, die uns dabei helfen möchten, es gemeinsam weiterzuentwickeln.

## Was soll übersetzt werden

Der erste Aspekt, der unsere Aufmerksamkeit zog, war die Unterstützung von Menschen dabei, zu bestimmen, was übersetzt werden soll. Die Kosten für Übersetzungen werden weiter sinken, bleiben aber niemals auf Null. Organisationen sollten weiterhin selektiv bei der Auswahl der Sprachen vorgehen, in die sie investieren.

Manchmal folgt diese Entscheidung direkt aus einer Geschäftsentscheidung. Andere Male haben Teams nur eine grobe Vorstellung von ihren Communities und treffen eine fundierte Vermutung. Wir dachten, es gäbe viel zu lernen von den Menschen, die Ihre Websites besuchen oder Ihre Apps nutzen. Ihre Sprachpräferenzen, kombiniert mit Informationen über die Regionen, aus denen Ihre Produkte genutzt werden, können Ihnen eine bessere Grundlage für diese Entscheidungen bieten.

Das erste Feature, das wir in Glossia veröffentlichten, war Analytics. Fügen Sie eine Codezeile zu Ihrer Website hinzu, und die Analytics fließen in Ihr Konto. Wir präsentieren diese Informationen rund um die Entscheidung, die Sie treffen müssen: In welche Sprachen sollten Sie als Nächstes investieren?

In Zukunft werden wir untersuchen, wie man Experimente in die Sprachdimension eines Produkts integriert. Stellen Sie sich vor, messen zu können, wie oft Nutzer auf einen Call to Action klicken, wenn eine Seite verschiedene Stimmen in derselben Sprache verwendet. Wäre das nicht toll? Das Vergleichen von Varianten hat sich traditionell um Produkt- und Designentscheidungen gedreht, aber Sprachen sind Teil des Produkts auch.

## Von Null zur Übersetzung

Sobald Sie sich für eine Übersetzung eines Projekts entschieden haben, ist der nächste Schritt die Einrichtung. Als Entwickler vermeide ich Prozesse, die viel Reibung verursachen. Wir sind uns einig, dass der Weg von Null zur Übersetzung idealerweise nur einen Schritt umfassen sollte. Das ist das Niveau, auf das wir abzielen.

Die Einrichtung umfasst üblicherweise zwei Dinge. Erstens, das Extrahieren von Inhalten aus dem Repository, damit diese übersetzt werden können, da der Inhalt oft als wörtliche Strings im Code vorliegt. Zweitens, die Konfiguration des Projekts, um den richtigen Inhalt basierend auf der Sprache auszuwählen. Dies kann vom Gerät des Benutzers stammen oder, in fortgeschrittenen Fällen, eine von ihnen gewählte Präferenz.

Eine zuverlässige Automatisierung davon wäre vor ein paar Jahren ein Albtraum gewesen. Die Dinge haben sich geändert, und Agenten können dabei recht effektiv sein.

Der Ablauf ist wie folgt: Sie verbinden Ihr GitHub-Repository, wählen die Sprachen aus, in die Sie übersetzen möchten, und nach einiger Zeit wird ein Pull-Request mit den Änderungen erstellt. Sobald Sie es zusammenführen, beginnen die Übersetzungen. Das ist alles.

Wir speichern Übersetzungen im Repository, parallel zu den Formatprüfungen und anderen Validierungen, die Sie bereits im Rahmen von [kontinuierlichen Integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). Die Übersetzungspipeline leitet die Ergebnisse dieser Prüfungen an den Übersetzungs-Agenten zurück. Das eliminiert eine ganze Kategorie von Problemen, bei denen eine Plattform einen Pull-Request öffnet und Sie sich mit fehlgeschlagenen Prüfungen oder Merge-Konflikten auseinandersetzen müssen.

Kombiniert mit anderen Mechanismen zum Vertrauensaufbau ermöglicht dies, Übersetzungen automatisch zusammenzuführen. Das ist das Modell, an dem wir glauben. Es bringt wenig Nutzen, einen Entwickler darauf zu bitten, zu prüfen, ob ein Übersetzungs-Pull-Request grün ist, und einen Button zu klicken, besonders wenn sie die Sprache selbst nicht einschätzen können. Wir haben stets gesehen, dass diese zusätzliche Form der Zeremonie ein Zeichen dafür ist, dass das Design besser sein könnte.

Wir glauben, das beste Übersetzungssystem funktioniert, ohne dass Sie darüber nachdenken müssen.

## Übersetzung nur des Geänderten

Das Übersetzungssystem verdient einen eigenen Abschnitt. Tokens sind immer noch nicht kostenlos. Das ständige Übersetzen von allem ist langsam, teuer und eine Verschwendung von Ressourcen.

Um das zu lösen, haben wir ein Lockdatei-System entwickelt, das uns sagt, ob etwas übersetzt werden muss. Wir nennen dies **inkrementelle Übersetzung**. Die Idee ist nicht neu: Buildsysteme verwenden dies seit langem, um das Neukompilieren aller Teile bei jedem Build zu vermeiden. Wir haben dies auf Sprachen angepasst.

Das System berücksichtigt den gesamten Kontext, der eine bestimmte Übersetzung betrifft. Ein Teil dieses Kontexts liegt im Repository. Ein anderer Teil liegt in Glossia und erstreckt sich über mehrere Repositories. Wir erstellen einen Abhängigkeitsbaum und verwenden [Merkle-Bäume](https://en.wikipedia.org/wiki/Merkle_tree) um Hashes zu berechnen, die uns zeigen, ob sich die Eingaben einer Übersetzung geändert haben.

Die Lock-Datei bewahrt diesen Baum. Sie kann erklären, warum etwas zur Übersetzung gesendet wurde, oder warum es nicht, anstatt dass man raten muss.

[`L10N.md`](/docs/reference/l10n-md) Dateien bieten unseren Übersetzungsagenten Lokalisierungskontext, ähnlich wie `AGENTS.md` Dateien geben Anweisungen an Codierungsagenten. Sie unterstützen einen spezifischeren Kontext in verschachtelten Verzeichnissen sowie Sprachüberschreibungen auf jeder Ebene.

Für Informationen, die auf mehrere Repositories zutreffen, wie gemeinsam genutzte Terminologie, ist der Server die Quelle der Wahrheit. Das System stellt sicher, dass es den richtigen Kontext verwendet und diesen im lockfile widerspiegelt. Wenn sich dieser Kontext ändert, können wir die Änderung auf die Übersetzungen zurückverfolgen, die sie genutzt haben und aktualisiert werden müssen.

## Vertrauen in die Wörter aufbauen

Das System ist darauf ausgelegt, einem Qualitätsniveau näherzukommen. Um dies zu erreichen, verfügen wir über mehrere Werkzeuge.

Das erste sind Adversarial-Checks, die nach der Übersetzung laufen. Stellen Sie sich einen Kollegen vor, der den Code überprüft, den Sie in einem Pull-Request miteingebracht haben. Hier bringen die Checks linguistisches Wissen in die Prüfung ein. Zum Beispiel sollte eine Übersetzung die Bedeutung des Quelltextes weder hinzufügen noch entfernen. Das liegt daran, dass Sprachmodelle nicht immer dieselbe Ausgabe aus denselben Eingaben produzieren.

Da wir durch unsere Benutzer und unsere eigene Forschung zu Modellen und bestehenden Systemen mehr erfahren, werden wir weitere automatisierte Prüfungen in die Pipeline aufnehmen. Jede davon sollte das Vertrauen erhöhen, das Sie in eine Übersetzung setzen können.

Die Idee ist, einen Punkt zu erreichen, an dem Sie dem System vertrauen, so dass Sie nicht mehr den Bedarf verspüren, jeden Pull-Request zu durchgehen. Dieses Vertrauen hängt sowohl vom System als auch von den Modellen ab. Wir können bei der Auswahl von Modellen basierend auf der Zielsprache helfen, da nicht alle Modelle in denselben Sprachen gleich gut funktionieren.

Auch wenn diese Kontrollen vorhanden sind, müsst ihr eventuell doch ein übersetztes Element ändern. Es könnte eine Einzelkorrektur sein, Terminologie, die noch nicht im Kontext verankert wurde, oder eines der vielen Szenarien, die wir noch erleben werden.

Jemand sollte in der Lage sein, diese Änderungen direkt ins Repository einzubringen. Aber wir denken auch, dass das System diese Beiträge als Feedback verarbeiten soll und vorschlagen sollte, wie diese mit ihrem Kontext in Einklang gebracht werden. Das könnte bedeuten, einen Begriff ins Glossar aufzunehmen oder die Stimme anzupassen.

Das kann ein Mensch asynchron tun, ohne die kontinuierliche Übersetzung zu unterbrechen. Das System sollte euch dabei helfen, die Arbeit effektiver zu gestalten, indem es aus dem lernt, was Menschen dazu sagen. Könnten wir das so erweitern, dass Menschen Feedback direkt vom Produkt aus vorschlagen können? Wäre das nicht cool?

Diese Korrekturen müssen ebenfalls berücksichtigt werden, damit zukünftige Übersetzungen sie nicht überschreiben. Ein zustandsloser Übersetzungsauftrag kennt keine Änderungen, die Menschen davor vorgenommen haben. In traditionellen Systemen helfen Übersetzungsspeicher dabei, diese Rolle zu übernehmen. Der Bedarf, den sie erfüllen, verschwindet nicht, nur weil sich die Technologie verändert.

## Wo wir von hier anfangen

Das ist Glossia. Wir nutzen es bereits, um Glossia zu übersetzen, und ich arbeite daran, es so einzurichten, dass es die Dokumentation, die Marketing-Website und das Dashboard von Tuist in die Sprachen unserer Gemeinschaften übersetzt.

María José und ich bauen Glossia in unserer Freizeit, getrieben von einer Neugier, die seit Jahren Teil unserer Gespräche ist.

In der Programmierung stellen sich viele Menschen die Frage nach der Rolle von Programmierern und wie sie sich entwickeln wird. Ich denke, die Lokalisierungsbranche würde von einer ähnlichen Infragestellung ihrer Annahmen und Modelle profitieren. Wie können wir unserer Branche helfen, mehr, schneller und mit geringeren Kosten zu übersetzen, ohne die Qualität zu beeinträchtigen?

Wir haben noch keine Antworten auf alle Fragen. Aber wir glauben, dass wir auf dem richtigen Weg sind, mit der Einfachheit und handwerklichen Sorgfalt, die wir gerne in alles einbringen, was wir tun.

Wenn das bei Ihnen Anklang findet, [Lass uns sprechen](mailto:pedro@glossia.ai).
%{
  title: "Übersetzung ist der einfache Teil",
  slug: "translation-is-the-easy-part",
  summary:
    "Wie Gespräche über Sprachen, Softwareauslieferung und Vertrauen María José und mich dazu brachten, Glossia zu entwickeln.",
  author: "pedro"
}
---

Sprachen sind ein großartiges und unterbewertetes Instrument für Barrierefreiheit und für den Zugang technischer Produkte zu neuen Märkten. Wenn sich dein Produkt an Gemeinschaften richtet, deren Hauptsprache nicht Englisch ist, signalisierst du, dass du an sie gedacht hast. Das kann eine sehr tiefe Verbindung herstellen.

Ungllicherweise ist es vielen Teams unmöglich, ihre Produkte und Marken in mehreren Sprachen sprechen zu lassen. Sie finden sich oft selbst gezwungen, zwei von dreiem zu wählen: **qualität, Geschwindigkeit und Kosten**.

Wenn sie darauf ausgehen, dass Übersetzungen mit der Softwareauslieferung Schritt halten, können sie in ein dediziertes Team investieren, um die Qualität aufrechtzuerhalten, aber das kostet. Oder sie können stärker auf maschinelle Übersetzungen setzen, schnell vorankommen, aber niedrigere Qualität akzeptieren. Wenn sie Qualität und niedrige Kosten wählen, indem sie auf menschliche Übersetzung ohne ein dediziertes Team setzen, verzichten sie in der Regel auf Geschwindigkeit. Auf diesem Weg landen sie mit verworrenen Systemen, die Übersetzungen zwischen ihren Repositories und Drittanbieter-Tools drängen und ziehen.

Seit das [Large Language Models](https://en.wikipedia.org/wiki/Large_language_model) entstanden sind, habe ich mit meiner Frau, [María José](https://www.linkedin.com/in/mariajosesalmeron/), und ihr viel darüber gesprochen, ob sie uns dabei helfen können, auf diese Kompromisse zu verzichten. Sie liebt Sprachen und ist tief in der Lokalisierungsbranche verwurzelt. Ich bin ein Builder.

Tuist ist meine Hauptbeschäftigung. Als ich versuchte, das Produkt und seine Marketingoberflächen zu übersetzen, fand ich mich mit verworrenen Lösungen konfrontiert. Keines davon hielt unseren Liefergeschwindigkeit stand, und einige führten zu Konflikten, deren Lösung ein Albtraum war. Ich habe diesen "das fühlt sich falsch an"-Moment viele Male.

## Von Gesprächen zu Glossia

Jede Woche diskutierten wir über neue Muster, die sich um die Fähigkeiten von Sprachmodellen herum bildeten. Wir sahen immer mehr Entwickler, die ihre eigenen Übersetzungs-Pipelines bauten. Im Kern stellten diese Pipelines ein Modell vor: Quellsprache ein, Übersetzung aus, dann weitermachen.

Das fühlte sich nachvollziehbar an. So arbeiten wir Builder. Aber jemand, der näher an Sprachen und den Prozessen darum herum war, konnte sehen, wie es schiefgehen konnte, von Inkonsistenzen bis hin zu schlimmsten Falschübersetzungen.

Entwickler werden immer schneller. Sie können nicht aufhören, ein System einzuführen, dessen Arbeitsabläufe lange vor dem Internet entwickelt wurden, in einen Browser überführt wurden und trotzdem noch die Bedürfnisse von Softwareteams nicht erfüllen können.

So begann die Idee, Glossia zu bauen. Auf der einen Seite würden wir darauf wetten, dass Modelle in Sprachen außer Englisch und bei Übersetzungen besser werden. Auf der anderen Seite würden wir ein System bauen, das sich zunächst auf Softwareinhalte konzentriert und sich einfach an anschließen lässt. Etwas im Hintergrund, das mit deiner Liefergeschwindigkeit mithält und dir Sicherheit gibt, dass die Ausgabe korrekt und für die Produktion bereit ist.

Viele Entwickler behandeln Übersetzung als One-Prompt-Lösung. Ein paar Token, Englisch ein, Übersetzung aus, und damit fertig. Aber wenn du mit ihnen sprichst, wirst du erkennen, dass sie nicht wissen, ob die Ausgabe korrekt ist, die Stimme ihrer Organisation in dieser Sprache einfängt oder die beabsichtigte Nachricht effektiv communicates.

Ich habe eine ähnliche Pipeline bei Tuist, die auf Sprachen wie Japanisch übersetzt, und ich mache das mit einem riesigen Mangel an Vertrauen. Sprachen sind keine Logik. Wir können Tests schreiben, um sicherzustellen, dass das Format korrekt ist, aber das sagt uns nicht **, ob die Wörter richtig sind**.

"Übersetzung ist der einfache Teil," wie meine es gerne sagt.

So ließen wir uns auf das Wgehen, was das richtige System aussehen könnte. Wir nannten es Glossia, und wir beginnen es für Menschen und Organisationen zu öffnen, die sich dafür interessieren, uns gemeinsam dabei zu helfen, es zu iterieren.

## Was zu übersetzen ist

Der erste Teil, auf den wir uns konzentrierten, war es, Menschen zu helfen, zu entscheiden, was zu übersetzen ist. Die Kosten für Übersetzung sinken und werden weiter sinken, aber sie werden niemals bei Null liegen. Organisationen sollten weiterhin selektiv über die Sprachen sein, in die sie investieren.

Manchmal folgt diese Entscheidung direkt aus einer Geschäftsentcheidung. Manchmal haben Teams eine grobe Vorstellung ihrer Gemeinschaften und treffen eine fundierte Vermutung. Wir dachten, es gabe viel zu lernen von den Menschen, die deine Websites besuchen oder deine Apps verwenden. Ihre Sprachpräferenzen, kombiniert mit Informationen über die Regionen, aus denen sie deine Produkte verwenden, können dir eine bessere Basis für diese Entscheidungen geben.

Das Erste Feature, das wir in Glossia landen konnten, war Analysen. Füge eine Zeile Code zu deiner Website hinzu, und Analysen fließen in dein Konto ein. Wir präsentieren diese Informationen um die Entscheidung herum, die du treffen musst: In welche Sprachen solltest du als Nächstes investieren?

In Zukunft werden wir erforschen, wie man Experimente in die Sprachdimension eines Produkts bringt. Stell dir vor, du misst, wie oft Leute auf einen Call-to-Action klicken, wenn eine Seite in verschiedenen Stimmen derselben Sprache verwendet wird. Würde das nicht cool sein? Das Vergleich von Varianten hat sich traditionell um Produkt- und Designentscheidungen gedreht, aber Sprachen sind auch Teil des Produkts.

## Von Null zur Übersetzung

Sobald du entschieden hast, ein Projekt zu übersetzen, ist der nächste Schritt, es einzurichten. Als Entwickler hasse ich Prozesse, die mit viel Komplikation kommen. Wir waren uns einig, dass von Null zur Übersetzung im Idealfall nur ein Schritt dauern sollte. Das ist das Erlebnisniveau, auf das wir hinaus wollen.

Die Einrichtung umfasst normalerweise zwei Dinge. Erstens, den Inhalt aus dem Repository extrahieren, sodass er übersetzt werden kann, da es oft als Literierungsstrings im Code beginnt. Zweitens, das Projekt konfigurieren, um den richtigen Inhalt basierend auf der Sprache auszuwählen. Das kann vom Gerät des Benutzers kommen oder, in fortgeschritteneren Fällen, eine Präferenz, die sie gewählt haben.

Dies zuverlässig vor einem paar Jahren zu automatisieren wäre ein Albtraum gewesen. Die Dinge haben sich geändert, und Agenten können bei dem sehr effektiv sein.

Der Prozess läuft so: Du verbindest dein GitHub Repository, wählst die Sprachen aus, in die du übersetzen möchtest, und nach einer Weile öffnet sich eine Pull-Request mit den Änderungen. Sobald du ihn merge, beginnen die Übersetzungen. Damit ist es fertig.

Wir speichern Übersetzungen im Repository, zusammen mit den Format-Checks und anderen Validierungen, die du bereits als Teil von [kontinuierliche Integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions) ausführst. Die Übersetzungs-Pipeline leitet die Ergebnisse dieser Checks zurück an den Übersetzungs-Agenten. Das entfernt eine ganze Reihe von Problemen, bei denen eine Plattform eine Pull-Request öffnet und du dich mit fehlgeschlagenen Checks oder Merge-Konflikten auseinandersetzen musst.

Kombiniert mit anderen Mechanismen zum Aufbau von Vertrauen ermöglicht dies das automatische Zusammenführen von Übersetzungen. Das ist das Modell, an das wir glauben. Es bringt wenig, einen Entwickler hinzuzuziehen, um zu prüfen, ob eine Pull-Request für Übersetzungen grün ist und einen Button zu klicken, besonders wenn die Sprache selbst nicht bewertet werden kann. Wir betrachten diese zusätzliche Zeremonie immer als Zeichen dafür, dass das Design verbessert werden könnte.

Wir glauben, dass das beste Übersetzungssystem eines ist, das funktioniert, ohne dass du dich darum kümmern musst.

## Nur Geändertes übersetzen

Das Übersetzungssystem verdient einen eigenen Abschnitt. Tokens sind immer noch nicht kostenlos. Alles ständig zu übersetzen ist langsam, teuer und eine Verschwendung von Ressourcen.

Um das zu lösen, haben wir ein Lockfile-System erstellt, das uns meldet, ob etwas übersetzt werden muss. Wir nennen dies **inkrementelle Übersetzung**. Die Idee ist nicht neu: Buildsysteme nutzen es seit langem, um bei jedem Build alles neu zu kompilieren zu vermeiden. Wir haben es auf Sprachen übertragen.

Das System berücksichtigt den gesamten Kontext, der eine bestimmte Übersetzung beeinflusst. Ein Teil davon lebt im Repository. Ein anderer Teil lebt in Glossia und erstreckt sich über mehrere Repositories. Wir erstellen einen Abhängigkeitsbaum und nutzen [Merkle-Bäume](https://en.wikipedia.org/wiki/Merkle_tree), um Hashes zu berechnen, die uns sagen, ob die Eingaben einer Übersetzung sich geändert haben.

Das Lockfile behält diesen Baum bei. Es kann erklären, warum etwas zur Übersetzung gesendet wurde oder warum nicht, statt den Menschen zu raten lassen.

Die Dateien [`L10N.md`](/docs/reference/l10n-md) stellen Lokalisierungskontext für unsere Übersetzungs-Agenten bereit, ähnlich wie `AGENTS.md` Dateien Anweisungen für Programmierungs-Agenten liefern. Sie unterstützen spezifischeren Kontext in verschachtelten Verzeichnissen sowie Sprach-Overrides auf jeder Ebene.

Für Informationen, die für mehr als ein Repository gelten, wie etwa gemeinsame Terminologie, gilt der Server als die Einzige Quelle der Wahrheit. Das System stellt sicher, dass dies den richtigen Kontext verwendet und dies im Lockfile widerspiegelt. Wenn sich dieser Kontext ändert, können wir die Änderung den Übersetzungen zurückzuordnen, die sie genutzt haben und aktualisiert werden müssen.

## Vertrauen in die Worte aufbauen

Das System ist darauf ausgelegt, auf ein Qualitätsniveau zuzukonvergieren. Um dies zu erreichen, verfügen wir über verschiedene Werkzeuge.

Erstens sind adverarial checks, die nach der Übersetzung laufen. Stell dir einen Kollegen vor, der den Code geprüft hat, den du in einer Pull-Request eingeschlossen hast. Hier bringen die Checks linguistisches Wissen in die Überprüfung ein. Beispielsweise sollte eine Übersetzung der Quelle keine Bedeutung hinzufügen oder entfernen. Das kann passieren, denn Sprachmodelle produzieren nicht immer die gleiche Ausgabe aus den gleichen Eingaben.

Je mehr wir von unseren Nutzern lernen und durch unsere eigene Forschung zu Modellen und bestehenden Systemen, werden wir mehr automatisierte Checks in die Pipeline hinzufügen. Jeder sollte das Vertrauen erhöhen, das du in eine Übersetzung haben kannst.

Die Idee ist, einen Punkt zu erreichen, an dem du dem System vertrauen kannst, dass du nicht das Gefühl hast, jede Pull-Request durchgehen zu müssen. Dieses Vertrauen hängt sowohl vom System als auch von den Modellen ab. Wir können helfen, Modelle basierend auf der Zielsprache auszuwählen, weil nicht alle Modelle in den gleichen Sprachen gleich gut sind.

Selbst mit diesen Checks an Ort und Stelle, musst du möglicherweise ein übersetztes Stück ändern. Es könnte eine einmalige Korrektur sein, Terminologie, die noch nicht in den Kontext geschrieben wurde, oder eines der vielen Szenarien, die wir noch zu erwarten haben.

Jemand sollte in die Lage versetzt sein, diese Änderungen direkt an das Repository beizutragen. Aber wir denken auch, das System sollte diese Beiträge als Feedback verarbeiten und vorschlagen, wie man sie mit seinem Kontext vereinbaren kann. Das könnte bedeuten, einen Begriff zum Glossary hinzuzufügen oder die Stimme anzupassen.

Das ist etwas, das ein Mensch asynchron tun kann, ohne die kontinuierliche Übersetzung zu unterbrechen. Das System sollte dir helfen, die Arbeit effektiver zu gestalten, indem es von den Aussagen lernt, die Menschen machen. Wir könnten dies so weit ausbauen, dass Menschen Feedback direkt aus dem Produkt vorschlagen können. Würde das nicht cool sein?

Diese Korrekturen müssen auch berücksichtigt werden, damit zukünftige Übersetzungen sie nicht überschreiben. Ein stateless-Aufruf hat kein Wissen über die Änderungen, die Menschen vorher vorgenommen haben. In traditionellen Systemen übernehmen Ühersetzungsspeicher diese Aufgabe. Das Bedürfnis, das sie erfüllen, verschwindet nicht etwa nur, weil sich die Technologie ändert.

## Wo es weitergeht

Das ist Glossia. Wir nutzen es bereits, um Glossia zu übersetzen, und ich arbeite daran, es einzurichten, um Tuist's Dokumentation, Marketingseite und Dashboard in die Sprachen unserer Gemeinden zu übersetzen.

María José und ich bauen Glossia in unserer Freizeit, folgend einer Neugier, die Teil unserer Gespräche für Jahre war.

In der Programmierung hinterfragen viele Menschen die Rolle von Programmierern und wie sie sich weiterentwickeln wird. Ich denke, die Lokalisationsindustrie würde von einer ähnlichen Hinterfragung ihrer Annahmen und Modelle profitieren. Wie können wir unserer Branche dabei helfen, mehr, schneller und zu geringeren Kosten zu übersetzen, ohne die Qualität zu kompromittieren?

Wir haben noch keine Antworten auf alle Fragen. Aber wir glauben, wir gehen in die richtige Richtung, mit der Einfachheit und der Sorgfalt im Handwerk, die wir gerne in alles investieren, was wir tun.

Wenn dir das gefällt, [schreiben wir](mailto:pedro@glossia.ai).

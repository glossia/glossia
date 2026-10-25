%{
  title: "Übersetzung ist der einfache Teil",
  slug: "translation-is-the-easy-part",
  summary:
    "Wie Gespräche über Sprachen, Softwarebereitstellung und Vertrauen María José und mich dazu brachten, Glossia zu bauen.",
  author: "pedro"
}
---

Sprachen sind ein großartiges und oft unterschätztetes Werkzeug für Barrierefreiheit und den Zugang neuer Märkte mit Technologieprodukten. Wenn Ihr Produkt an Gemeinschaften spricht, deren Hauptsprache nicht Englisch ist, signalisieren Sie, dass Sie an sie gedacht haben. Das kann eine sehr tiefe Verbindung herstellen.

Leider ist es für viele Teams nicht bezahlbar, dass Ihr Produkt und eure Marke mehrere Sprachen sprechen. Sie finden sich oft so, dass sie zwei von drei auswählen müssen: **Qualität, Geschwindigkeit und Kosten**.

Wenn sie Übersetzungen wollen, die mit der Softwareauslieferung Schritt halten, können sie in ein spezialisiertes Team investieren, um Qualität zu erhalten, aber das ist mit Kosten verbunden. Oder sie stützen sich stärker auf maschinelle Übersetzung, arbeiten schnell, akzeptieren aber geringere Qualität. Wenn sie Qualität und niedrige Kosten wählen und auf menschliche Übersetzung ohne ein dediziertes Team vertrauen, geben sie in der Regel Geschwindigkeit auf. Auf diesem Weg landen sie oft mit verwickelten Systemen, die Übersetzungen zwischen ihren Repositories und Drittanbieterwerkzeugen hin- und herdrängen und -ziehen.

Seit [große Sprachmodelle](https://en.wikipedia.org/wiki/Large_language_model) entstanden, haben meine Frau [María José](https://www.linkedin.com/in/mariajosesalmeron/) und ich viel darüber gesprochen, ob sie uns dabei helfen könnten, diese Kompromisse zu verhindern. Sie liebt Sprachen und ist tief im Lokalisierungsbereich verankert. Ich bin ein Entwickler.

Tuist ist mein Hauptgeschäft. Als ich versuchte, das Produkt und seine Marketing-Oberflächen zu übersetzen, geriet ich mit verwickelten Lösungen zurecht. Keine von ihnen konnte mit unserer Auslieferungsgeschwindigkeit mithalten, und einige führten zu Konflikten, die ein Albtraum zu lösen waren. Ich hatte diesen Moment, dass "dies fühlt sich falsch an", viele Male.

## Von Gesprächen zu Glossia

Jede Woche diskutierten wir neue Muster, die sich rund um die Fähigkeiten von Sprachmodellen entwickelten. Wir sahen immer mehr Entwickler, die ihre eigenen Übersetzungs-Pipelines bauten. Im Kern forderten diese Pipelines ein Modell: Quellsprache rein, Übersetzung raus, dann weitermachen.

Es fühlte sich verständlich an. So arbeiten wir Entwickler. Aber jemand, der näher an Sprachen und den Prozessen darum herum ist, könnte sehen, wie es daneben gehen kann, von Inkonsistenzen im besten Fall bis hin zu Missverständnissen im schlechtesten Fall.

Entwickler bewegen sich immer schneller und schneller. Sie können nicht verlangsamen, um ein System einzuführen, dessen Arbeitsabläufe noch lange vor dem Internet konzipiert wurden, in einen Browser gewandert sind und immer noch Schwierigkeiten haben, den Bedürfnissen von Software-Teams gerecht zu werden.

So begann die Idee, Glossia zu bauen. Auf der einen Seite würden wir wetten, dass Modelle besser bei Sprachen anderen als Englisch und bei Übersetzungen werden. Auf der anderen Seite würden wir ein System bauen, das initiiert auf Softwareinhalt fokussiert ist, das sich "Plug-and-Play" anfühlte. Etwas im Hintergrund, das mit eurer Auslieferungsgeschwindigkeit mithält und euch das Vertrauen gibt, dass die Ausgabe korrekt ist und für die Produktion bereit.

Viele Entwickler betrachten Übersetzung als Lösung für einen einzigen Prompt. Ein paar Token, Englisch rein, Übersetzung raus, und damit ist es erledigt. Aber wenn man mit ihnen spricht, merkt man, dass sie nicht wissen, ob die Ausgabe präzise ist, die Stimme ihrer Organisation in dieser Sprache einfängt oder die beabsichtigte Botschaft effektiv überträgt.

Ich habe eine ähnliche Pipeline bei Tuist und übersetze in Sprachen wie Japanisch, und ich tue das mit einem enormen Mangel an Vertrauen. Sprachen sind keine Logik. Wir können Tests schreiben, um sicherzustellen, dass das Format korrekt ist, aber das sagt uns nicht **ob die Wörter richtig sind**.

"Übersetzung ist der einfache Teil," so mag meine Frau sagen.

So machten wir uns daran, herauszufinden, wie das richtige System aussehen könnte. Wir nannten es Glossia, und wir beginnen, es für Menschen und Organisationen zugänglich zu machen, die sich bereit erklären, uns beim gemeinsamen Schaffen zu unterstützen.

## Was zu übersetzen ist

Das erste Element, auf das wir uns konzentrierten, war Menschen dabei zu helfen, zu entscheiden, was zu übersetzen ist. Die Kosten der Übersetzung gehen zurück und werden weiterhin zurückgehen, aber sie werden nie null sein. Organisationen sollten weiterhin selektiv darüber entscheiden, in welche Sprachen sie investieren.

Manchmal folgt diese Entscheidung direkt einer Geschäftsentscheidung. Andere Male haben Teams eine grobe Vorstellung ihrer Gemeinschaften und machen eine fundierte Vermutung. Wir dachten, es gab viel zu lernen von den Menschen, die eure Websites besuchen oder eure Apps nutzen. Ihre Sprachpräferenzen, kombiniert mit Informationen über die Regionen, von denen aus sie eure Produkte nutzen, können euch eine bessere Grundlage für diese Entscheidungen geben.

Das erste Feature, das wir bei Glossia implementierten, war Analysen. Fügt eine Zeile Code auf eure Website hinzu, und Analysen beginnen, in Euren Account zu fließen. Wir präsentieren diese Informationen rund um die Entscheidung, die ihr treffen müsst: In welche Sprachen sollt ihr eure nächsten Investitionen tätigen?

In Zukunft erforschen wir, wie Experimente in die Sprachdimension eines Produkts integriert werden können. Stellt vor, wie oft Benutzer auf eine Handlungsaufforderung klicken, wenn eine Seite unterschiedliche Stimmen in derselben Sprache verwendet. Wäre das nicht cool? Das Vergleichen von Varianten ist traditionell um Produkt- und Designentscheidungen gewachsen, aber Sprachen sind auch Teil des Produkts.

## Von Null zur Übersetzung

Sobald ihr entschieden habt, ein Projekt zu übersetzen, ist der nächste Schritt die Einrichtung. Als Entwickler, mag ich Prozesse nicht, die mit viel Reibung kommen. Wir einigten uns darauf, dass der Weg von Null zur Übersetzung idealerweise nur einen Schritt dauert. Das ist das Erfahrungslevel, das wir anstreben.

Die Einrichtung umfasst normalerweise zwei Dinge. Erstens, extrahiert den Inhalt aus dem Repository, damit er übersetzt werden kann, da er oft als textliche Strings im Code beginnt. Zweitens, konfiguriert das Projekt, um den richtigen Inhalt auf Basis der Sprache auszuwählen. Das kann vom Gerät des Benutzers kommen oder in ausgeklügelten Fällen eine Präferenz, die diese gewählt haben.

Eine zuverlässige Automatisierung dieses Vorgangs vor ein paar Jahren wäre ein Albtraum gewesen. Die Dinge haben sich geändert, und Agenten können dabei sehr effektiv sein.

Der Prozess läuft so ab: Ihr verbindet euer GitHub Repository, wählt die Sprachen aus, in die ihr übersetzen mögt, und nach einer Weile öffnet sich ein Pull Request mit den Änderungen. Sobald ihr ihn mitgebt, beginnen die Übersetzungen. Das ist es.

Wir speichern die Übersetzungen im Repository, neben den Format-Checks und anderen Validierungen, die Sie bereits im Rahmen von [kontinuierliche Integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions) durchführen. Die Übersetzungs-Pipeline leitet die Ergebnisse dieser Checks zurück an den Übersetzungsagenten. Damit beseitigen wir eine ganze Klasse von Problemen, bei denen eine Plattform einen Pull Request öffnet und Sie mit fehlgeschlagenen Checks oder Merge-Konflikten allein lässt.

In Kombination mit weiteren Mechanismen, um Vertrauen aufzubauen, ermöglicht dies das automatische Zusammenführen von Übersetzungen. Das ist das Modell, an das wir glauben. Es hat little Wert, einen Entwickler zu bitten, zu prüfen, ob ein Übersetzungs-Pull Request grün ist und auf einen Button zu klicken, besonders wenn sie die Sprache selbst nicht bewerten können. Wir haben diese zusätzliche Zeremonie immer als Zeichen gesehen, dass das Design verbessert werden könnte.

Wir glauben, dass das beste Übersetzungssystem eines ist, das funktioniert, ohne dass Sie darüber nachdenken müssen.

## Nur das Übersetzen von Änderungen

Das Übersetzungssystem verdient seinen eigenen Abschnitt. Tokens sind immer noch nicht kostenlos. Alles immer wieder zu übersetzen ist langsam, teuer und eine Verschwendung von Ressourcen.

Um das zu lösen, haben wir ein Lockfile-System entwickelt, das uns sagt, ob etwas übersetzt werden muss. Wir nennen dies **inkrementelle Übersetzung**. Die Idee ist nicht neu: Build-Systeme nutzen es seit langem, um bei jedem Build zu vermeiden, alles neu zu kompilieren. Wir haben es auf Sprachen angepasst.

Das System berücksichtigt den gesamten Kontext, der eine bestimmte Übersetzung beeinflusst. Ein Teil dieses Kontextes lebt im Repository. Ein anderer Teil lebt in Glossia und erstreckt sich über mehrere Repositorys. Wir erstellen einen Abhängigkeitsbaum und verwenden [Merkle-Bäume](https://en.wikipedia.org/wiki/Merkle_tree), um Hashes zu berechnen, die uns sagen, ob die Eingaben einer Übersetzung sich geändert haben.

Die Lockdatei bewahrt diesen Baum. Sie kann erklären, warum etwas für Übersetzung gesendet wurde, oder warum nicht, statt Leute raten zu lassen.

[`L10N.md`](/docs/reference/l10n-md) Dateien liefern den Lokalisierungskontext für unsere Übersetzungsagenten, ganz so wie `AGENTS.md` Dateien Anweisungen für Coding-Agenten geben. Sie unterstützen einen spezifischeren Kontext in verschachtelten Verzeichnisse sowie Sprach-Overrides auf jeder Ebene.

Für Informationen, die auf mehr als ein Repository anwendbar sind, wie geteilte Terminologie, ist der Server die Quelle der Wahrheit. Das System stellt sicher, dass es den richtigen Kontext verwendet und diesen in der Lockdatei widerspiegelt. Wenn sich dieser Kontext ändert, können wir die Änderung auf die Übersetzungen zurückverfolgen, die ihn verwendet haben und aktualisiert werden müssen.

## Vertrauen in die Wörter aufbauen

Das System ist so konzipiert, dass es sich auf ein Qualitätsniveau zubewegt. Um dies zu erreichen, verfügen wir über verschiedene Tools.

Das erste sind adversarial checks, die nach der Übersetzung ausgeführt werden. Stellen Sie sich einen Kollegen vor, der den Code überprüft, den Sie in einem Pull Request enthalten. Hier bringen die Checks linguistisches Wissen in die Prüfung ein. Zum Beispiel sollte eine Übersetzung die Bedeutung der Quelle nicht hinzufügen oder entfernen. Das kann passieren, da Sprachmodelle nicht immer aus denselben Eingaben dieselbe Ausgabe erzeugen.

Je mehr wir von unseren Nutzern und unserer eigenen Forschung zu Modellen und bestehenden Systemen lernen, werden wir weitere automatisierte Checks in die Pipeline aufnehmen. Jeder sollte das Vertrauen erhöhen, das Sie in eine Übersetzung haben können.

Die Idee ist, einen Punkt zu erreichen, an dem Sie dem System vertrauen, dass Sie nicht jede Pull Request durchgehen müssen. Dieses Vertrauen hängt sowohl vom System als auch von den Modellen ab. Wir können beim Auswählen von Modellen basierend auf der Zielsprache helfen, da nicht alle Modelle in derselben Sprache gleich gut sind.

Selbst mit diesen Checks am Einsatzort müssen Sie möglicherweise eine übersetzte Komponente ändern. Es könnte eine einmalige Korrektur sein, eine Terminologie, die noch nicht in den Kontext geschrieben wurde, oder eines der vielen Szenarien, die wir noch zu begegnen haben.

Jemand sollte diese Änderungen direkt im Repository einbringen können. Wir denken aber auch, das System sollte diese Beiträge als Feedback verarbeiten und vorschlagen, wie man sie mit seinem Kontext in Einklang bringt. Das könnte bedeuten, einen Begriff in das Glossar aufzunehmen oder die Stimme anzupassen.

Das ist etwas, das ein Mensch asynchron tun kann, ohne die kontinuierliche Übersetzung zu unterbrechen. Das System sollte Ihnen helfen, diese Aufgabe effektiver zu gestalten, indem es von dem zu lernt, was Menschen zu sagen haben. Wir könnten das erweitern, damit Menschen Feedback direkt vom Produkt aus vorschlagen. Wäre das nicht cool?

Diese Korrekturen müssen auch berücksichtigt werden, damit zukünftige Übersetzungen sie nicht überschreiben. Ein stateless translation call hat keine Kenntnis der Änderungen, die Menschen vor ihm vorgenommen haben. In traditionellen Systemen helfen Translation Memories, diese Rolle zu erfüllen. Das Bedürfnis, das sie bedienen, verschwindet nicht einfach nur, weil sich die Technologie ändert.

## Wo wir von hier aus gehen

Dies ist Glossia. Wir nutzen es bereits, um Glossia zu übersetzen, und ich arbeite daran, es einzurichten, um Tuist's Dokumentation, Marketingseite und Dashboard in die Sprachen unserer Communities zu übersetzen.

María José und ich bauen Glossia in unserer Freizeit und verfolgen eine Neugier, die seit Jahren Teil unserer Gespräche ist.

In der Programmierung hinterfragen viele die Rolle der Programmierer und wie sie sich entwickeln wird. Ich glaube, die Lokalisierungsbranche würde von einer ähnlichen Hinterfragung ihrer Annahmen und Modelle profitieren. Wie können wir unserer Branche helfen, mehr, schneller und zu niedrigeren Kosten zu übersetzen, ohne die Qualität zu gefährden?

Wir haben noch keine Antworten auf alle Fragen. Aber wir glauben, wir bewegen uns in die richtige Richtung, mit der Einfachheit und Sorgfalt für die Handwerkskunst, die wir gerne in alles, was wir tun, einbringen.

Wenn dies bei Ihnen Anklang findet, [Lasst uns sprechen](mailto:pedro@glossia.ai).

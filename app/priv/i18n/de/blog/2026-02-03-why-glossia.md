%{
  title:
    "Lokalisierung steckte in der Vergangenheit fest. Wir haben Glossia entwickelt, um sie voranzutreiben.",
  summary:
    "Traditionelle Lokalisierungstools verursachen Overhead, unterbrechen CI und binden Sie an Anbieter-Ökosysteme. Wir erforschen, wie ein agenter Lokalisierungs-Workflow aussehen könnte.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie jemals Software in mehreren Sprachen ausgeliefert haben, kennen Sie die Routine. Man wählt eine Lokalisierungsplattform aus, verbindet sie mit dem Repository und verbringt den Rest seiner Zeit mit der Verwaltung der Synchronisation. Inhalte gehen raus, Übersetzungen kommen zurück, und irgendwo dazwischen geht etwas schief.

Dieser Aufwand, der ständige Hin- und Herzverkehr von Inhalten aus und in das Repository, ist die Gebühr, die jedes Team für den Einsatz heutiger Lokalisierungstools zahlt. Es klingt unwichtig, bis Sie selbst derjenige sind, der am Freitag um 18 Uhr debuggt, warum ein Übersetzungs-Pull Request Ihren Build Ihrer Website zerstört hat.

## Ein Design aus der Zeit vor dem Internet

Viele Lokalisierungsplattformen wurden nach Konzepten herum entwickelt, die dem modernen Entwicklungsworkflow vorangegangen sind. Übersetzungsspeicher. Fuzzy-Matching. Menschliche Übersetzer, die in proprietären Editoren arbeiten, unterstützt durch Tools, die ähnliche Zeichenketten aus einer Datenbank vorschlagen.

Diese Ideen machten Sinn, als Übersetzungen ein manueller, offline Prozess waren. Aber Unternehmen verwandelten Übersetzungsspeicher in einen Lock-in-Mechanismus. Ihre früheren Übersetzungen, das institutionelle Wissen, das Sie bezahlt haben, leben in ihrer Plattform. Ein Wechsel zu einem anderen Anbieter bedeutet, von vorne anzufangen oder für einen Export zu zahlen, der nie wirklich funktioniert.

Das Ergebnis ist eine Branche, die auf künstliche Reibung basiert. Ihr Inhalt verlässt Ihr Repo, fällt in eine schwarzen Box und kommt auf einem Zeitplan zurück, der von jemand anderem bestimmt ist.

## Der unterbrochene Feedback-Loop

Das Problem ist strukturell: Externe Lokalisierungstools können Ihre CI-Pipeline nicht ausführen. Sie wissen nichts über Ihre Linter, Ihre Build-Schritte, Ihren Link-Checker oder Ihr Frontmatter-Schema. Sie drücken Übersetzungs-Inhalte zurück in Ihr Repo und hoffen auf das Beste. Wenn es kaputt geht, und es kaputt geht, muss jemand im Team stoppen, was er tut, um Formatierungsprobleme, kaputte Syntaxen oder ungültiges Markup zu beheben, das das Übersetzungs-Tool eingeführt hat.

LLMs und agentische Erlebnisse bieten uns neue Möglichkeiten, diese Workflows komplett neu zu überdenken. Ein Agent, der eine Übersetzung generiert, Ihre Prüfungen ausführt, den Fehler sieht und erneut versucht, bis die Ausgabe gültig ist. Solch eine enge Rückmeldeschleife ändert alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er lebt: in Ihrem Repository. Sobald Sie es zu einer externen Plattform senden, kehren Übersetzungen auf einem Zeitplan eines anderen zurück, und die Integration bricht. Die Rückmeldung, die hätte sofort sein können, dauert jetzt Stunden oder Tage. Der Kontext, der es nützlich gemacht hat, ist längst interessiert. Sie verlieren die Schleife und damit den gesamten Vorteil, den agentische Workflows geben sollten.

## Beobachtungen, die Glossia geformt haben

Diese Frustrationen wurden nicht von selbst zu Glossia. Das Projekt entstand aus tiefer Erfahrung in Entwicklung und Lokalisierung, was Klarheit zu Problemen brachte, die von nur einer Seite schwer zu sehen sind. Das Verständnis der linguistischen Workflows, der menschlichen Dynamik von Übersetzungsteams und die Gründe, warum bestehende Tools so geworden sind, war entscheidend.

Zusammen kamen wir immer wieder zu denselben Schlüssen: Lokalisierungstools wurden für eine Welt ohne LLMs, ohne Code-Agenten und ohne CI-Pipelines entwickelt. Das gesamte Modell ging davon aus, dass Übersetzung etwas ist, das außerhalb des Entwicklungsworkflows passiert und in diesen zurückgeschoben wird. Das machte vor zehn Jahren Sinn. Es tut das nicht mehr.

Wir begannen zu fragen: **was wäre, wenn Lokalisierungsagenten genauso arbeiten könnten wie Code-Agenten?**

Wir haben Aufmerksamkeit dafür bezahlt, wie [Anthropic](https://anthropic.com) bei agentischen Workflows mit Claude denkt. Das Muster, bei dem einem Agent Zugriff auf Werkzeuge gegeben wird, aufgefordert wird, eine Aufgabe durchzudenken, seine eigene Ausgabe zu validieren und zu iterieren, wenn etwas nicht stimmt, passt erstaunlich gut zur Lokalisierung. Ein Übersetzungs-Agent, der Ihre Quelldateien lesen kann, den Projekt-Kontext versteht, Übersetzungen generieren kann, Ihren Linters ausführt und Probleme behebt, bevor ein Pull Request erstellt wird. Das ist keine Fantasie. Das ist der Workflow, den wir aufbauen.

## Glossia ist unser Geschenk an die Softwareindustrie

Wir haben Glossia gebaut, weil wir wollen, dass mehr Software lokalisiert wird, nicht weniger.

Komplizierte Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unzugänglich. Wenn Ihr Übersetzungsworkflow einen Beschaffungsprozess, eine Preisverhandlung pro Wort und einen Projektleiter zur Koordination der Übergabe erfordert, werden die meisten Teams einfach auf Englisch ausliefern und den Tag als erledigt betrachten.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Werkzeugen, nicht mit unseren.

Wir glauben, dass Lokalisierung so natürlich sein sollte wie das Ausführen Ihrer Testsuite.

## Ein Agent zuerst, Schnittstellen sekundär

Im Kern ist Glossia ein Agent. Wir beginnen mit dem Terminal als primäre Schnittstelle, weil dort die schwierigsten Probleme zuerst gelöst werden: das Lesen Ihrer Quelldateien, die Generierung von Übersetzungen, das Ausführen Ihrer Prüfungen sowie das Iterieren, bis die Ausgabe gültig ist. Dies ist derselbe Ansatz, den [OpenAI](https://openai.com) mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code) verfolgen. Sie bauen den Agenten, statten ihn mit einem Terminal aus und lassen ihn arbeiten.

Das Terminal ist jedoch nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der an der Qualität der Lokalisierung mitwirkt, ein Entwickler ist. Über dieses Thema sprechen wir viel intern. Diejenigen, denen Übersetzungsgenauigkeit, Ton und kulturelle Nuancen am meisten am Herzen liegen, sind oft Linguisten und Content-Spezialisten, die nicht in Kategorien wie Zweige, Kompilierung oder JSON denken.

Deshalb wollen wir neue Schnittstellen auf Basis dieses Agenten aufbauen. Etwas, bei dem ein Linguist den Inhalt, den Kontext und die Übersetzung nebeneinander sieht. Sie bringen das menschliche Urteil, das kein Modell ersetzen kann. Sie verfeinern, was verfeinert werden muss. Und der Agent übernimmt den Rest: Commit-Anweisungen ausführen, Validieren und Pull-Request eröffnen.

Wir haben noch nicht alle Antworten, und das ist beabsichtigt. Wir würden es lieber sorgfältig entwickeln als in eine Benutzeroberfläche eilen, die den eigentlichen Zweck verfehlt. Doch die Richtung ist klar: Glossia möchte alle willkommen heißen, die sich für die Aufgabe interessieren, Software in jeder möglichen Sprache sprechen zu lassen.

## Bleiben Sie dran

Glossia befindet sich noch am Anfang, und wir entwickeln es öffentlich. Wenn dies mit Ihrem Ansatz zur Lokalisierung übereinstimmt, behalten Sie das Projekt im Auge. Wir werden mehr teilen, wie wir voranschreiten.
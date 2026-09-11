%{
  title:
    "Lokalisierung war in der Vergangenheit stehengeblieben. Wir haben Glossia entwickelt, um sie voranzubringen.",
  summary:
    "Traditionelle Lokalisierungstools verursachen zusätzlichen Aufwand, unterbrechen die CI und binden Sie an Vendor-Ökosysteme. Wir erforschen, wie ein agentischer Lokalisierungsworkflow aussehen könnte.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie jemals Software in mehr als einer Sprache veröffentlicht haben, kennen Sie die Routine. Sie wählen eine Lokalisierungsplattform, verbinden sie mit Ihrem Repository und verbringen den Rest Ihrer Zeit mit der Verwaltung der Synchronisation. Inhalte gehen aus, Übersetzungen kommen zurück, und irgendwo dazwischen geht etwas schief.

Dieser Overhead, der ständige Inhaltstransfer zu und von Ihrem Repository, ist der Preis, den jedes Team für die Nutzung heutiger Lokalisierungstools zahlt. Es klingt geringfügig, bis Sie derjenige sind, der das debuggt, warum ein Übersetzungs-Pull-Request Ihren Website-Build um 6 Uhr am Freitag kaputt gemacht hat.

## Ein Design aus der Zeit vor dem Internet

Die meisten Lokalisierungsplattformen wurden um Konzepte herum entwickelt, die dem modernen Entwicklungsablauf vorausgehen. Übersetzungsgedächtnisse. Fuzzy matching. Menschliche Übersetzer arbeiten in proprietären Editoren, unterstützt durch Tools, die ähnliche Strings aus einer Datenbank vorschlagen.

Diese Ideen machten Sinn, als Übersetzungen noch ein manueller, offlineer Prozess waren. Doch Unternehmen wandelten Übersetzungsspeicher in einen Lock-in-Mechanismus um. Ihre früheren Übersetzungen und dasjenige institutionelle Wissen, für das Sie bezahlt haben, befinden sich in ihrer Plattform. Der Wechsel zu einem anderen Anbieter bedeutet, von vorne anzufangen oder für einen Export zu zahlen, der nie recht funktioniert.

Das Ergebnis ist eine Branche, die auf künstlicher Reibung basiert. Ihr Inhalt verlässt Ihr Repository, fällt in eine Black Box und kehrt im Zeitplan eines anderen zurück.

## Der unterbrochene Feedback-Loop

Das Problem liegt strukturell: Externe Lokalisierungstools können Ihre CI-Pipeline nicht ausführen. Sie kennen Ihre Linter, Ihren Build-Schritt, Ihren Link-Checker oder Ihre Frontmatter-Schema nicht. Sie übergeben den übersetzten Inhalt zurück in Ihr Repository und hoffen auf das Beste. Wenn es kaputt geht, und es tut es, muss jemand im Team innehalten, um Formatierungsprobleme, defekte Syntax oder ungültiges Markup zu beheben, das das Übersetzungstool eingeführt hat.

LLMs und agentische Erfahrungen eröffnen uns neue Möglichkeiten, diese Workflows vollständig neu zu denken. Ein Agent erstellt eine Übersetzung, führt Ihre Prüfungen aus, erkennt den Fehler und wiederholt dies, bis die Ausgabe gültig ist. Eine solche enge Feedback-Schleife verändert alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er gehört: in Ihrem Repository. Sobald Sie ihn an eine externe Plattform senden, kehren Übersetzungen auf einem fremden Zeitplan zurück und die Integration bricht. Das Feedback, das hätte sofort kommen können, dauert nun Stunden oder Tage. Der Kontext, der es nützlich machte, ist längst Geschichte. Sie verlieren die Schleife und mit ihr den gesamten Vorteil, den agentische Workflows eigentlich Ihnen bieten sollten.

## Beobachtungen, die Glossia geprägt haben

Diese Frustrationen wurden nicht einfach zu Glossia. Das Projekt wuchs aus tiefen Erfahrungen in beiden Bereichen, Entwicklung und Lokalisierung, hervor, was Klarheit für Probleme bot, die aus nur einer Seite schwer zu erkennen sind. Das Verständnis der linguistischen Workflows, der menschlichen Dynamiken in Übersetzungsteams und der Gründe, warum bestehende Tools genau so endeten, wie sie es taten, war essentiell.

Zusammen kamen wir immer wieder zu denselben Beobachtungen: Lokalisierungstools wurden für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines entwickelt. Das gesamte Modell ging davon aus, dass Übersetzung etwas war, was außerhalb des Entwicklungsworkflows stattfand und dann nachgeschoben wurde. Das hatte vor zehn Jahren noch Sinn. Heute nicht mehr.

Wir haben angefangen, zu fragen: **was wäre, wenn Lokalisierungsagenten genauso funktionieren könnten wie Coding-Agenten?**

Wir haben uns genau angesehen, wie [Anthropic](https://anthropic.com) denkt über agentische Workflows mit Claude nach. Das Muster, einem Agenten Zugriff auf Tools zu gewähren, es dabei unterstützt, eine Aufgabe durchzudenken, seine eigene Ausgabe zu validieren und zu iterieren, wenn etwas nicht passt, passt erstaunlich gut zur Lokalisierung. Ein Übersetzungsagent, der Ihre Quelldateien lesen, den Projektzusammenhang verstehen, Übersetzungen generieren, Ihren Linter ausführen und Probleme beheben kann, bevor ein Pull Request erstellt wird. Das ist keine Fantasie. Das ist der Workflow, den wir entwickeln.

## Glossia ist unser Geschenk an die Softwareindustrie

Wir haben Glossia entwickelt, weil wir wollen, dass mehr Software lokalisiert wird, statt weniger.

Komplexe Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unerschwinglich. Wenn Ihr Übersetzungsworkflow einen Beschaffungsprozess, Verhandlungen über Preise pro Wort und einen Projektleiter zur Koordinierung der Übergaben erfordert, liefern die meisten Teams einfach auf Englisch aus und betrachten es als erledigt.

Glossia verwendet Modelle, auf die Sie bereits Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Tools, nicht mit unseren.

Wir glauben, dass Lokalisierung so natürlich sein sollte wie das Ausführen Ihrer Testsuite.

## Ein Agent zuerst, Schnittstellen zweitrangig.

Im Kern ist Glossia ein Agent. Wir beginnen mit dem Terminal als primärer Schnittstelle, weil dort die schwierigsten Probleme zuerst gelöst werden: Lesen Ihrer Quelldateien, Generierung von Übersetzungen, Durchführen Ihrer Prüfungen und Iterieren, bis die Ausgabe gültig ist. Dies ist dasselbe Muster, das [OpenAI](https://openai.com) verfolgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Sie bauen den Agenten, geben ihm ein Terminal und lassen ihn arbeiten.

Aber das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Qualität der Lokalisierung beiträgt, ein Entwickler ist. Wir besprechen dies häufig intern. Diejenigen, die sich am meisten für Übersetzungspräzision, Ton und kulturelle Nuancen interessieren, sind oft Linguisten und Content-Spezialisten, die nicht in Bezug auf Zweige, Kompilierung oder JSON denken.

Genau deshalb wollen wir neue Schnittstellen auf demselben Agenten aufbauen. Etwas, bei dem ein Linguist Inhalt, Kontext und Übersetzung nebeneinander sieht. Sie bringen die menschliche Urteilskraft, die kein Modell ersetzen kann. Sie verfeinern, was verfeinert werden muss. Und der Agent übernimmt den Rest: Commit, Validieren, Erstellen eines Pull-Requests.

Wir haben noch nicht alle Antworten, und das ist beabsichtigt. Wir würden es lieber sorgfältig bauen als eilig in eine UI stürmen, die den Punkt verfehlt. Aber die Richtung ist klar: Glossia soll alle willkommen heißen, die sich dafür einsetzen, dass Software jede Sprache spricht.

## Bleibt dran

Glossia befindet sich noch in der Anfangsphase, und wir entwickeln es offen. Wenn dies mit Ihrer Vorstellung von Lokalisierung übereinstimmt, halten Sie das Projekt im Auge. Wir werden mehr teilen, während wir fortfahren.
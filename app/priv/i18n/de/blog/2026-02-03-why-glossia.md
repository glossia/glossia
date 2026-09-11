%{
  title:
    "Die Lokalisierung war in der Vergangenheit stecken geblieben. Wir haben Glossia gebaut, um sie voranzutreiben.",
  summary:
    "Traditionelle Lokalisierungstools verursachen Overhead, stören CI und binden Sie fest an Vendor-Ökosysteme. Wir erforschen, wie ein agentenbasierter Lokalisierungs-Workflow aussehen könnte.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie bereits einmal Software in mehr als einer Sprache ausgeliefert haben, kennen Sie das Prinzip. Sie wählen eine Lokalisierungsplattform, verbinden diese mit Ihrem Repository und verbringen den Rest Ihrer Zeit mit der Verwaltung der Synchronisation. Inhalte gehen raus, Übersetzungen kommen zurück, und irgendwo dazwischen geht etwas schief.

Dieser Aufwand, der ständige Hin- und Rücktransfer von Inhalten zu und von Ihrem Repository, ist die Gebühr, die jedes Team für die Nutzung heutiger Lokalisierungstools zahlt. Er wirkt vernachlässigbar, bis Sie selbst debuggen müssen, warum ein Pull Request mit Übersetzungen Ihren Website-Build am Freitag um 18 Uhr zerstört hat.

## Ein Design aus der Zeit vor dem Internet

Die meisten Lokalisierungsplattformen wurden um Konzepte entwickelt, die der modernen Entwicklungs-Workflow vorausgehen. Übersetzungsspeicher. Fuzzy Matching. Menschliche Übersetzer in proprietären Editoren, unterstützt von Tools, die ähnliche Strings aus einer Datenbank vorschlagen.

Diese Ideen machten Sinn, als Übersetzung ein manueller, offline-Prozess war. Aber Unternehmen verwandelten Übersetzungsspeicher in einen Lock-in-Mechanismus. Ihre früheren Übersetzungen, das institutionelle Wissen, für das Sie bezahlt haben, leben in ihrer Plattform. Ein Wechsel zu einem anderen Anbieter bedeutet, von vorne beginnen oder für einen Export zu zahlen, der nie ganz funktioniert.

Das Ergebnis ist eine Branche, die auf künstlicher Reibung aufgebaut ist. Ihr Inhalt verlässt Ihr Repository, betritt eine Black Box und kehrt zu einem anderen Zeitplan zurück.

## Der unterbrochene Feedback-Loop

Das Problem ist strukturell: externe Lokalisierungstools können Ihre CI-Pipeline nicht ausführen. Sie wissen nicht um Ihre Linter, Ihren Build-Schritt, Ihren Link-Checker oder Ihr frontmatter-Schema. Sie schieben den übersetzten Inhalt zurück in Ihr Repository und hoffen auf das Beste. Wenn es schiefgeht, und es schiefgeht, muss jemand im Team innehalten, um Formatierungsfehler, defekte Syntax oder ungültiges Markup zu beheben, das das Übersetzungs-Tool eingeführt hat.

LLMs und KI-Agenten bieten uns neue Möglichkeiten, diese Workflows grundlegend neu zu denken. Ein Agent, der eine Übersetzung generiert, Ihre Prüfungen durchführt, den Fehler erkennt und erneut versucht, bis die Ausgabe gültig ist. Solch eine enge Feedback-Schleife verändert alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er ist: in Ihrem Repository. Sobald Sie es an eine externe Plattform senden, kommen die Übersetzungen im Zeitplan von jemand anderem an, und die Integration bricht. Das Feedback, das hätte sofort kommen können, dauert jetzt Stunden oder Tage. Der Kontext, der es nützlich made hat, ist längst verschwunden. Sie verlieren die Schleife und damit den gesamten Vorteil, den KI-Agenten-Workflows Ihnen eigentlich bieten sollten.

## Beobachtungen, die Glossia geprägt haben

Diese Frustrationen wurden nicht von selbst zu Glossia. Das Projekt entstand aus tiefer Erfahrung sowohl in der Entwicklung als auch in der Lokalisierung, was Klarheit bei Problemen bot, die nur schwer von einer Seite aus zu erkennen sind. Ein Verständnis der linguistischen Workflows, der menschlichen Dynamiken in Übersetzungsteams und der Gründe, warum bestehende Werkzeuge so geworden waren, war essenziell.

Gemeinsam kamen wir immer wieder auf dieselben Beobachtungen zurück: Lokalisierungswerkzeuge wurden für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines entwickelt. Das gesamte Modell ging davon aus, dass Übersetzung etwas ist, was außerhalb des Entwicklungsworkflows stattfindet und dann hineingeschoben wird. Das machte vor zehn Jahren Sinn. Heute nicht mehr.

Wir begannen zu fragen: **was wäre, wenn Lokalisationsagenten so arbeiten könnten wie Coding-Agenten?**

Wir beobachten genau, wie [Anthropic](https://anthropic.com) denkt über Agenten-Workflows mit Claude. Das Muster, einem Agenten den Zugang zu Werkzeugen zu gewähren, ihm dabei zuzulassen, eine Aufgabe durchzudenken, die eigene Ausgabe zu validieren und zu iterieren, wenn etwas schief läuft, lässt sich hervorragend auf Lokalisierung übertragen. Ein Übersetzungsagent, der Ihre Quelldateien lesen kann, den Projektkontext versteht, Übersetzungen generiert, Ihren Linter ausführt und Probleme behebt, bevor ein Pull Request erstellt wird. Das ist keine Phantasie. Das ist der Workflow, den wir entwickeln.

## Glossia ist unser Geschenk für die Software-Industrie

Wir haben Glossia entwickelt, weil wir wollen, dass mehr Software lokalisiert wird, nicht weniger.

Komplexe Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Side-Projects unerschwinglich. Wenn Ihr Übersetzungsworkflow ein Beschaffungsverfahren, eine Preisverhandlung pro Wort und einen Projektmanager zur Koordinierung der Übergabe erfordert, werden die meisten Teams einfach auf Englisch ausliefern und damit einen Schlussstrich ziehen.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben, und validiert die Ausgabe mit Ihren eigenen Tools, nicht mit unseren.

Wir glauben, dass Lokalisierung so natürlich sein sollte wie das Ausführen Ihrer Testsuite.

## Ein Agent zuerst, Schnittstellen zweitens.

Im Kern ist Glossia ein Agent. Wir starten mit dem Terminal als primärer Schnittstelle, da dort die härtesten Probleme zuerst gelöst werden: das Lesen Ihrer Quelldateien, das Generieren von Übersetzungen, das Ausführen Ihrer Checks und das Iterieren, bis die Ausgabe als gültig gilt. Dies ist dasselbe Muster, das [OpenAI](https://openai.com) folgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Du baust den Agenten, gibst ihm ein Terminal und lässt ihn arbeiten.

Aber das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der sich für die Qualität der Lokalisierung einsetzt, ein Entwickler ist. Über dieses Thema sprechen wir oft intern. Diejenigen, die sich am meisten um Übersetzungspräzision, Tonfall und kulturelle Nuancen kümmern, sind oft Linguisten und Content-Spezialisten, die nicht in Bezug auf Zweige, Kompilierung oder JSON denken.

Deshalb wollen wir neue Schnittstellen auf denselben Agenten aufbauen. Etwas, bei dem ein Linguist Inhalt, Kontext und die Übersetzung nebeneinander sieht. Sie bringen das menschliche Urteil, das kein Modell ersetzen kann. Sie verfeinern, was verfeinert werden muss. Und der Agent übernimmt alles andere: Committing, Validieren, das Öffnen von Pull Requests.

Wir haben noch nicht alle Antworten parat, und das ist beabsichtigt. Wir würden dies lieber sorgfältig aufbauen als hetzen, weil wir keine Benutzeroberfläche wollen, die den Punkt verfehlt. Aber die Richtung ist klar: Glossia sollte jeden willkommen heißen, der sich dafür einsetzt, dass Software in jeder Sprache sprechen kann.

## Bleibt dran

Glossia befindet sich noch in der Anfangsphase, und wir entwickeln es offen. Wenn dies Ihre Vorstellungen von Lokalisierung widerspiegelt, behalten Sie das Projekt im Auge. Wir werden im weiteren Verlauf mehr darüber berichten.
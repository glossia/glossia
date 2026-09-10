%{
  title:
    "Die Lokalisierung stand in der Vergangenheit still. Wir haben Glossia entwickelt, um sie voranzutreiben.",
  summary:
    "Traditionelle Lokalisierungstools verursachen Overhead, unterbrechen CI und binden Sie in Anbieter-Ökosysteme ein. Wir erforschen, wie ein agentischer Lokalisierungsworkflow aussehen kann.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie je Software auf mehrere Sprachen ausgeliefert haben, kennen Sie das Prinzip. Sie wählen eine Lokalisierungsplattform, verbinden sie mit Ihrem Repository und verbringen den Rest der Zeit mit der Verwaltung der Synchronisation. Der Inhalt geht raus, Übersetzungen kommen zurück, und irgendwo dazwischen gehen die Dinge kaputt.

Dieser Overhead, der konstante Hin-und-Her-Transfer von Inhalten von und in Ihr Repository, ist der Preis, den jedes Team für den Einsatz der heutigen Lokalisierungstools zahlt. Das klingt bagatell, bis Sie debuggen müssen, warum eine Übersetzungs-PR um 17 Uhr am Freitag Ihren Website-Build kaputt gemacht hat.

## Ein Design, das aus der Zeit vor dem Internet stammt

Die meisten Lokalisierungsplattformen wurden um Konzepte herum entwickelt, die vor dem modernen Entwicklungsworkflow liegen. Übersetzungsspeicher. Fuzzy Matching. Menschliche Übersetzer, die in proprietären Editoren arbeiten, unterstützt durch Tools, die ähnliche Strings aus einer Datenbank vorschlagen.

Diese Ideen hatten Sinn, als Übersetzung ein manueller, offline-Prozess war. Aber Unternehmen haben Translation Memories zu einem Lock-in-Mechanismus gemacht. Ihre früheren Übersetzungen, das institutionelle Wissen, für das Sie bezahlt haben, leben innerhalb ihrer Plattform. Eine Migration zu einem anderen Anbieter bedeutet einen Neuanfang von Null oder Bezahlung für einen Export, der nie ganz funktioniert.

Das Ergebnis ist eine Branche, die auf künstliche Reibung basiert. Ihr Inhalt verlässt Ihr Repo, gelangt in eine Blackbox und kehrt auf jemand anders' Zeitplan zurück.

## Der kaputte Feedback-Loop

Das Problem ist strukturell: externe Lokalisierungs-Tools können Ihren CI-Pipeline nicht ausführen. Sie wissen nichts von Ihren Linter, Ihrem Build-Schritt, Ihrem Link-Checker oder Ihrem frontmatter schema. Sie pushen übersetzten Content zurück in Ihr Repo und hoffen auf das Beste. Wenn es kaputt wird und es tut, muss jemand im Team das, was sie gerade tun, aufhören, um Formatierungsprobleme, gebrochene Syntax oder ungültiges Markup zu reparieren, das das Übersetzungstool eingeführt hat.

LLMs und agentische Erfahrungen bieten uns neue Möglichkeiten, diese Workflows fundamental neu zu denken. Ein Agent, der eine Übersetzung generiert, Ihre Prüfungen ausführt, den Fehler erkennt und erneut versucht, bis die Ausgabe gültig ist. Solcher enger Feedback-Loop verändert alles.

Es funktioniert jedoch nur, wenn der Inhalt dort bleibt, wo er ist: in Ihrem Repository. Sobald Sie ihn an eine externe Plattform senden, kommen die Übersetzungen auf einem fremden Zeitplan zurück, und die Integration bricht. Feedback, das eigentlich sofort hätte kommen können, benötigt jetzt Stunden oder Tage. Der Kontext, der es nützlich gemacht hat, ist längst dahin. Sie verlieren den Loop und damit den gesamten Vorteil, den agentische Workflows eigentlich versprechen sollten.

## Einsichten, die Glossia geprägt haben

Diese Frustrationen führten nicht von selbst zu Glossia. Das Projekt entstand aus tiefer Erfahrung sowohl in der Entwicklung als auch in der Lokalisierung, was Klarheit für Probleme brachte, die von einer einzigen Seite aus schwer zu erkennen sind. Das Verständnis der linguistischen Workflows, der menschlichen Dynamik in Übersetzungsteams und der Gründe, warum bestehende Tools so entstanden sind wie sie sind, war essenziell.

Zusammen kamen wir immer wieder zu denselben Erkenntnissen: Lokalisierungstools wurden für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines entwickelt. Das gesamte Modell ging davon aus, dass Übersetzung etwas ist, das außerhalb des Entwicklungsworkflows stattfindet und danach wieder hineingebracht wird. Das machte vor zehn Jahren Sinn. Heute nicht mehr.

Wir begannen zu fragen: **was wäre, wenn Lokalisationsagenten genauso funktionieren könnten wie Coding-Agenten?**

Wir haben genau darauf geachtet, wie [Anthropic](https://anthropic.com) denkt über agentische Workflows mit Claude nach. Das Muster, einem Agenten Zugriff zu Tools zu gewähren, eine Aufgabe durchzudenken, die eigene Ausgabe zu validieren und zu iterieren, wenn etwas nicht stimmt, passt bemerkenswert gut zur Lokalisierung. Ein Übersetzungsagent, der deine Quelldateien lesen, den Projekt-Kontext verstehen, Übersetzungen generieren, deinen Linter ausführen und Probleme beheben kann, bevor du einen Pull-Request öffnest. Das ist keine Fantasie. Das ist der Workflow, den wir aufbauen.

## Glossia ist unser Geschenk an die Softwareindustrie

Wir haben Glossia gebaut, weil wir möchten, dass mehr Software lokalisiert wird, nicht weniger.

Komplizierte Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unzugänglich. Wenn Ihr Übersetzungsablauf einen Beschaffungsprozess, eine Verhandlung des Preises pro Wort und einen Projektmanager zur Koordination von Übergaben erfordert, veröffentlichen die meisten Teams einfach auf Englisch und lassen es dabei.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Werkzeugen, nicht mit unseren.

Wir glauben, dass Lokalisierung so natürlich sein sollte wie das Ausführen Ihrer Testsuite.

## Ein Agent zuerst, Schnittstellen sekundär.

Im Kern ist Glossia ein Agent. Wir beginnen mit dem Terminal als primäre Schnittstelle, weil dort die schwierigsten Probleme zuerst gelöst werden: das Lesen Ihrer Quelldateien, das Generieren von Übersetzungen, das Ausführen Ihrer Prüfungen und das Iterieren, bis die Ausgabe gültig ist. Dies ist das gleiche Muster, das [OpenAI](https://openai.com) folgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Du baust den Agenten, gibst ihm ein Terminal und lässt ihn arbeiten.

Aber das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Lokalisierungsqualität beiträgt, ein Entwickler ist. Wir sprechen darüber oft intern. Die Personen, die sich am meisten um Übersetzungsqualität, Ton und kulturelle Nuancen kümmern, sind oft Linguisten und Content-Spezialisten, die nicht in Begriffen von Zweigen, Kompilierung oder JSON denken.

Deshalb wollen wir neue Schnittstellen auf demselben Agenten aufbauen. Etwas, bei dem ein Linguist Inhalt, Kontext und Übersetzung nebeneinander sieht. Sie bringen die menschliche Urteilskraft, die kein Modell ersetzen kann. Sie verfeinern, was verfeinert werden muss. Und der Agent übernimmt alles andere: Committen, Validieren, Öffnen des Pull Requests.

Wir haben noch nicht alle Antworten, und das ist beabsichtigt. Wir würden dies lieber durchdacht entwickeln als in eine UI, die den Punkt verfehlt, zu stürmen. Aber die Richtung ist klar: Glossia sollte jeden willkommen heißen, der sich dafür einsetzt, dass Software jede Sprache spricht.

## Bleiben Sie dran

Glossia befindet sich noch in der Frühphase, und wir entwickeln es offen. Wenn sich dies mit Ihrer Vorstellung von Lokalisierung deckt, behalten Sie das Projekt im Blick. Wir werden im Laufe der Zeit mehr teilen.
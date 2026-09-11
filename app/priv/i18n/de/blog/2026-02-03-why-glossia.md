%{
  title:
    "Die Lokalisierung war in der Vergangenheit feststecken geblieben. Wir haben Glossia entwickelt, um sie voranzutreiben.",
  summary:
    "Traditionelle Lokalisierungstools verursachen Overhead, brechen CI und binden Sie an Anbieter-Ökosysteme. Wir erforschen, wie ein agentenbasierter Lokalisierungsworkflow aussehen könnte.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie jemals Software in mehr als einer Sprache veröffentlicht haben, kennen Sie das Spiel. Sie wählen eine Lokalisierungsplattform, verbinden diese mit Ihrem Repository und verbringen den Rest Ihrer Zeit mit der Verwaltung der Synchronisation. Inhalte gehen raus, Übersetzungen kommen zurück, und irgendwo dazwischen gehen die Dinge kaputt.

Dieser Aufwand, das ständige Roundtrip von Inhalten von und zu Ihrem Repository, ist die Steuer, die jedes Team für die Nutzung der heutigen Lokalisierungstools zahlt. Es klingt unbedeutend, bis Sie derjenige sind, der debuggt, warum eine Übersetzungs-PR Ihre Website-Aufgabe am Freitag um 18 Uhr zerstört hat.

## Ein Design, das aus der Zeit vor dem Internet geerbt wurde

Die meisten Lokalisierungsplattformen wurden um Konzepte herum entwickelt, die dem modernen Entwicklungsworkflow vorausgingen. Übersetzungsgedächtnisse. Fuzzy matching. Menschliche Übersetzer, die in proprietären Editoren arbeiten, unterstützt durch Tools, die ähnliche Strings aus einer Datenbank vorschlagen.

Diese Ideen machten Sinn, wenn Übersetzung ein manueller, Offline-Prozess war. Aber Unternehmen haben Übersetzungsgedächtnisse in einen Lock-In-Mechanismus verwandelt. Ihre früheren Übersetzungen, das institutionelle Wissen, für das Sie bezahlt haben, leben in ihrer Plattform. Das Wechseln zu einem anderen Anbieter bedeutet, bei Null anzufangen, oder für einen Export zu zahlen, der nie wirklich funktioniert.

Das Ergebnis ist eine Branche, die auf künstlicher Reibung basiert. Ihre Inhalte verlassen Ihr Repository, wandern in eine Black Box ein und kehren auf dem Zeitplan eines anderen zurück.

## Der kaputte Feedback-Loop

Das Problem ist strukturell: Externe Lokalisierungstools können Ihre CI-Pipeline nicht ausführen. Sie kennen Ihre Linter, Ihren Build-Schritt, Ihren Link-Checker oder Ihr Frontmatter-Schema nicht. Sie schieben übersetzten Inhalt zurück in Ihr Repository und hoffen auf das Beste. Wenn es abbricht, und es passiert, muss jemand im Team aufhören, womit er beschäftigt ist, um Formatierungsprobleme, defekte Syntax oder ungültiges Markup zu beheben, das das Übersetzungstool eingeführt hat.

LLMs und agentische Erfahrungen eröffnen uns neue Möglichkeiten, diese Arbeitsabläufe vollständig neu zu denken. Ein Agent, der eine Übersetzung generiert, Ihre Prüfungen ausführt, den Fehler erkennt und solange erneut versucht, bis die Ausgabe gültig ist. Solche enge Feedback-Schleifen ändern alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er ist: in Ihrem Repository. Sobald Sie ihn an eine externe Plattform senden, kehren Übersetzungen auf einer fremden Zeitleiste zurück und die Integration bricht. Das Feedback, das sofort erfolgen könnte, dauert nun Stunden oder Tage. Der Kontext, der es nutzbringend machte, ist längst verschwunden. Sie verlieren die Schleife und damit den gesamten Vorteil, den agentische Arbeitsabläufe Ihnen eigentlich bieten sollten.

## Beobachtungen, die Glossia geprägt haben

Diese Frustrationen haben Glossia nicht von selbst entstehen lassen. Das Projekt gründete sich auf tiefe Erfahrung in Entwicklung und Lokalisierung, was Klarheit über Probleme bot, die von einer Seite aus schwer zu erkennen sind. Das Verständnis der linguistischen Arbeitsabläufe, der menschlichen Dynamiken in Übersetzungsteams und der Gründe, warum sich bestehende Werkzeuge so entwickelten, wie sie es getan haben, war essenziell.

Gemeinsam kamen wir immer wieder zu denselben Beobachtungen zurück: Lokalisierungswerkzeuge wurden für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines entwickelt. Das gesamte Modell ging davon aus, dass Übersetzung etwas war, das außerhalb des Entwicklungsablaufs stattfand und nachträglich in den Workflow hineingeschoben wurde. Das hat vor zehn Jahren noch Sinn gemacht. Heute nicht mehr.

Wir begannen zu fragen: **was wäre, wenn Lokalisierungsagenten genau so arbeiten würden wie Coding-Agenten?**

Wir beobachten genau, wie [Anthropic](https://anthropic.com) denkt über agentische Workflows mit Claude nach. Das Muster, einem Agenten Zugriff auf Tools zu gewähren, das es ermöglicht, eine Aufgabe zu reflektieren, seine eigene Ausgabe zu validieren und bei Fehlern zu iterieren, passt hervorragend auf die Lokalisierung. Ein Übersetzungsagent, der Ihre Quelldateien liest, den Projektkontext versteht, Übersetzungen generiert, Ihren Linter ausführt und Probleme behebt, bevor er einen Pull-Request erstellt. Das ist keine Fantasie. Das ist der Workflow, den wir aufbauen.

## Glossia ist unser Geschenk an die Softwareindustrie

Wir haben Glossia entwickelt, weil wir wollen, dass mehr Software lokalisiert wird, nicht weniger.

Komplexe Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unzugänglich. Wenn Ihr Übersetzungsworkflow einen Beschaffungsprozess, eine Preisverhandlung pro Wort und einen Projektmanager zur Koordinierung der Übergaben erfordert, veröffentlichen die meisten Teams das Produkt einfach auf Englisch und beenden den Tag damit.

Glossia verwendet Modelle, auf die Sie bereits Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Tools, nicht mit unseren.

Wir denken, Lokalisierung sollte so natürlich sein wie das Ausführen Ihrer Testsuite.

## Zuerst ein Agent, Schnittstellen zweiter.

Im Kern ist Glossia ein Agent. Wir starten mit dem Terminal als primäre Schnittstelle, denn dort werden die schwierigsten Probleme zuerst gelöst: das Lesen Ihrer Quelldateien, das Generieren von Übersetzungen, das Ausführen Ihrer Checks und das Iterieren, bis die Ausgabe gültig ist. Dies ist das gleiche Muster, das [OpenAI](https://openai.com) folgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Du baust den Agenten, gibst ihm ein Terminal und lässt es arbeiten.

Aber das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Lokalisierungsqualität beiträgt, ein Entwickler ist. Wir sprechen das oft intern an. Diejenigen, die sich am meisten um Übersetzungspräzision, Tonfall und kulturelle Nuancen kümmern, sind oft Linguisten und Content-Spezialisten, die nicht in Bezug auf Branches, Kompilierung oder JSON denken.

Deshalb wollen wir neue Schnittstellen auf denselben Agenten aufbauen. Etwas, bei dem ein Linguist Inhalt, Kontext und die Übersetzung nebeneinander sieht. Sie bringen die menschliche Urteilsfähigkeit, die kein Modell ersetzen kann. Sie verfeinern das, was verfeinert werden muss. Und der Agent erledigt alles andere: das Commiten, Validieren und das Erstellen des Pull-Requests.

Wir haben nicht alle Antworten parat, und das ist beabsichtigt. Wir würden dies lieber durchdacht aufbauen als in eine UI stürmen, die den Kern verfehlt. Doch die Richtung ist klar: Glossia sollte jeden willkommen heißen, der sich dafür einsetzt, dass Software in jeder Sprache spricht.

## Bleibt dran

Glossia steckt noch in den Anfängen und wir entwickeln sie offen. Wenn sich das mit Ihrer Sicht auf Lokalisierung deckt, halten Sie das Projekt im Auge. Wir werden mehr teilen, je weiter wir kommen.
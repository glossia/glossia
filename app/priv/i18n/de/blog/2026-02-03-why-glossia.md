%{
  title:
    "Die Lokalisierung war in der Vergangenheit festgefahren. Wir haben Glossia gebaut, um sie voranzutreiben.",
  summary:
    "Traditionelle Lokalisierungswerkzeuge verursachen Overhead, unterbrechen CI und binden Sie an Anbieterökosysteme. Wir erforschen, wie ein agentenbasierter Lokalisierungs-Workflow aussehen kann.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie Software in mehr als einer Sprache veröffentlicht haben, kennen Sie den Ablauf. Sie wählen eine Lokalisierungsplattform, verbinden sie mit Ihrem Repository und verbringen den Rest Ihrer Zeit mit dem Synchronisieren. Inhalte gehen heraus, Übersetzungen kommen zurück und irgendwo dazwischen brechen die Dinge.

Dieser Aufwand, der ständige Hin- und Rücktransport von Inhalt aus und zu Ihrem Repository, ist die Steuer, die jedes Team für die Nutzung aktueller Lokalisierungstools zahlt. Es klingt verschwindend klein, bis Sie selbst derjenige sind, der debuggt, warum eine Übersetzungs-PR Ihren Build am Freitag um 18 Uhr zerstört hat.

## Ein Erbe aus der Zeit vor dem Internet

Die meisten Lokalisierungsplattformen wurden um Konzepte herum entworfen, die vor dem modernen Entwicklungsworkflow liegen. Übersetzungsspeicher. Fuzzy Matching. Menschliche Übersetzer, die in proprietären Editoren arbeiten, unterstützt durch Tools, die ähnliche Zeichenfolgen aus einer Datenbank vorschlagen.

Diese Ideen hatten Sinn, als Übersetzung ein manueller, offline-Prozess war. Aber Unternehmen verwandelten Übersetzungsspeicher in einen Lock-in-Mechanismus. Ihre vergangenen Übersetzungen, das institutionelle Wissen, das Sie bezahlt haben, leben in ihrer Plattform. Ein Wechsel zu einem anderen Anbieter bedeutet, von vorne anzufangen, oder für einen Export zu bezahlen, der nie wirklich funktioniert.

Das Ergebnis ist eine Branche, die auf künstlicher Reibung basiert. Ihr Inhalt verlässt Ihr Repository, betritt eine Black Box und kehrt auf einem fremden Zeitplan zurück.

## Der unterbrochene Feedback-Loop

Das Problem ist strukturell: Externe Lokalisierungstools können Ihre CI-Pipeline nicht ausführen. Sie kennen Ihre Linter, Ihren Build-Schritt, Ihren Link-Checker oder Ihr Frontmatter-Schema nicht. Sie pushen übersetzten Inhalt zurück in Ihr Repository und hoffen auf das Beste. Wenn es bricht und das passiert, muss jemand im Team anhalten, was sie tun, um Formatierungsfehler, fehlerhaften Syntax oder ungültiges Markup zu beheben, die das Übersetzungstool eingeführt hat.

LLMs und agentische Erfahrungen eröffnen uns neue Möglichkeiten, um diese Workflows vollständig neu zu denken. Ein Agent generiert eine Übersetzung, führt Ihre Prüfungen durch, erkennt den Fehler und versucht erneut, bis die Ausgabe gültig ist. Eine solche enge Feedback-Schleife ändert alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er lebt: in Ihrem Repository. Sobald Sie ihn auf eine externe Plattform senden, kehren die Übersetzungen auf fremden Zeitplänen zurück und die Integration bricht. Das Feedback, das eigentlich sofort hätte kommen können, dauert nun Stunden oder Tage. Der Kontext, der es nützlich machte, ist längst verloren. Sie verlieren die Schleife und damit den gesamten Vorteil, den agentischen Workflows ursprünglich bieten sollten.

## Beobachtungen, die Glossia geprägt haben.

Diese Frustrationen haben sich nicht von selbst in Glossia verwandelt. Das Projekt entstand aus tiefer Erfahrung in Entwicklung und Lokalisierung, was Klarheit schuf bei Problemen, die von einer Seite aus schwer einsehbar sind. Das Verständnis der linguistischen Workflows, der menschlichen Dynamiken in Übersetzungsteams und der Gründe, warum bestehende Tools auf die heutige Weise entstanden sind, war unerlässlich.

Zusammen kamen wir immer wieder auf dieselben Beobachtungen: Lokalisierungstooling wurde für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines entworfen. Das gesamte Modell ging davon aus, dass Übersetzung außerhalb des Entwicklungs-Workflows stattfand und erst nachträglich in den Workflow integriert wurde. Das hat vor zehn Jahren Sinn gemacht. Heute schon gar nicht mehr.

Wir begannen zu fragen. **Was wäre, wenn Lokalisierungsagenten genauso funktionieren könnten wie Coding-Agenten?**

Wir achten genau darauf, wie [Anthropic](https://anthropic.com) denkt über agentische Workflows mit Claude nach. Das Muster, einem Agenten Zugriff auf Tools zu gewähren, es durch eine Aufgabe zu durchdenken lassen, seine eigene Ausgabe zu validieren und zu iterieren, wenn etwas nicht stimmt, lässt sich erstaunlich gut auf Lokalisierung übertragen. Ein Übersetzungsagent, der Ihre Quelldateien lesen, den Projektkontext verstehen, Übersetzungen generieren, Ihren Linter ausführen und Probleme beheben kann, bevor ein Pull-Request eröffnet wird. Das ist keine Fantasie. Das ist der Workflow, den wir aufbauen.

## Glossia ist unser Geschenk an die Software-Industrie

Wir haben Glossia gebaut, weil wir wollen, dass mehr Software lokalisiert wird, nicht weniger.

Komplizierte Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unerschwinglich. Wenn Ihr Übersetzungsworkflow einen Beschaffungsprozess, eine Verhandlung zum Pro-Wort-Preis und einen Projektmanager zur Koordinierung von Übergaben erfordert, veröffentlichen die meisten Teams einfach auf Englisch und betrachten die Aufgabe als erledigt.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Werkzeugen, nicht mit unseren.

Wir glauben, dass Lokalisierung so natürlich sein sollte, wie das Ausführen Ihrer Testsuite.

## Ein Agent zuerst, Schnittstellen zweite.

Im Kern ist Glossia ein Agent. Wir starten mit dem Terminal als primäre Schnittstelle, denn dort werden die härtesten Probleme zuerst gelöst: das Lesen Ihrer Quelldateien, das Erstellen von Übersetzungen, das Ausführen Ihrer Prüfungen und das Iterieren, bis die Ausgabe gültig ist. Das ist das gleiche Muster, das, [OpenAI](https://openai.com) verfolgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Sie bauen den Agenten, geben ihm ein Terminal und lassen ihn arbeiten.

Aber das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Lokalisierungsqualität beiträgt, ein Entwickler ist. Wir sprechen dies häufig intern. Die Personen, die sich am meisten für Übersetzungsgenauigkeit, Ton und kulturelle Nuancen interessieren, sind oft Linguisten und Content-Spezialisten, die nicht in Bezug auf Zweige, Kompilierung oder JSON denken.

Deshalb wollen wir neue Schnittstellen auf demselben Agenten aufbauen. Etwas, wo ein Linguistik Inhalt, Kontext und Übersetzung nebeneinander sieht. Sie bringen das menschliche Urteil, das kein Modell ersetzen kann. Sie verfeinern, was verfeinert werden muss. Und der Agent übernimmt alles andere: das Committen, Validieren und die Erstellung des Pull-Requests.

Wir haben noch nicht alle Antworten, und das ist beabsichtigt. Wir ziehen es vor, dies sorgfältig zu entwickeln, als in eine Benutzeroberfläche zu stürzen, die den Punkt verfehlt. Aber die Richtung ist klar: Glossia sollte alle willkommen heißen, die sich dafür einsetzen, dass Software jede Sprache sprechen kann.

## Bleibt dran

Glossia befindet sich noch in der Anfangsphase, und wir entwickeln es öffentlich. Wenn das mit eurer Vorstellung von Lokalisierung übereinstimmt, schaut dem Projekt bitte weiter zu. Wir werden euch mehr mitteilen, je weiter wir vorankommen.
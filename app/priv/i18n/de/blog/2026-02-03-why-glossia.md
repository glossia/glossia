%{
  title: "Lokalisierung war in der Vergangenheit stecken geblieben. Wir haben Glossia gebaut, um es voranzutreiben.",
  summary: "Traditionelle Lokalisierungstools verursachen Overhead, unterbrechen CI und binden Sie an Anbieter-Ökosysteme. Wir erforschen, wie ein agentengestützter Lokalisierungsworkflow aussehen kann.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie jemals Software in mehr als einer Sprache ausgeliefert haben, kennen Sie das Prinzip. Sie wählen eine Lokalisierungsplattform, verbinden sie mit Ihrem Repository und verbringen den Rest Ihrer Zeit mit der Verwaltung der Synchronisation. Inhalte gehen raus, Übersetzungen kommen zurück, und irgendwo dazwischen geht etwas kaputt.

Diese Überlastung, die ständige Hin- und Her-Bewegung von Inhalten von und zu Ihrem Repository, ist die Steuer, die jedes Team heute für den Einsatz von Lokalisierungswerkzeugen zahlt. Das klingt nicht viel, bis Sie es sind, der debuggen muss, warum eine Übersetzungs-Pull-Request Ihren Site-Aufbau um 18 Uhr am Freitag zerstört hat.

## Ein Design, das vor dem Internet geerbt wurde

Die meisten Lokalisierungsplattformen wurden um Konzepte herum konstruiert, die dem modernen Entwicklungsablauf vorangehen. Übersetzungsspeicher. Fuzzy-Matching. Menschenübersetzer arbeiten innerhalb proprietärer Editoren, unterstützt durch Werkzeuge, die ähnliche Zeichenfolgen aus einer Datenbank vorschlagen.

Diese Ideen hatten Sinn, als Übersetzung ein manueller, offline Prozess war. Aber Unternehmen verwandelten Übersetzungsspeicher in einen Lock-In-Mechanismus. Ihre früheren Übersetzungen, das institutionelle Wissen, für das Sie bezahlt haben, leben innerhalb ihrer Plattform. Ein Wechsel zu einem anderen Anbieter bedeutet den Neuanfang, oder die Bezahlung für ein Exportformat, das niemals genau funktioniert.

Das Ergebnis ist eine Branche, die auf künstlicher Reibung basiert. Ihre Inhalte verlassen Ihr Repo, dringen in eine Black-Box ein, und kehren auf dem Zeitplan von jemand anderem zurück.

## Der gebrochene Feedback-Loop

Das Problem ist strukturell: Externe Lokalisierungswerkzeuge können Ihre CI-Pipeline nicht ausführen. Sie wissen nichts über Ihre Linter, Ihren Build-Schritt, Ihren Link-Checker oder Ihr Frontmatter-Schema. Sie drücken übersetzten Inhalt zurück in Ihr Repo und hoffen auf das Beste. Wenn es kaputtgeht, und es tut, muss jemand im Team aufhören, was sie tun, um Formatierungsprobleme, fehlerhafte Syntax oder ungültiges Markup zu beheben, die das Übersetzungstool eingeführt hat.

LLMs und Agenten-Erfahrungen präsentieren uns neue Möglichkeiten, diese Workflows komplett neu zu denken. Ein Agent, der eine Übersetzung generiert, Ihre Prüfungen ausführt, den Fehler sieht und sich neu probiert, bis der Output gültig ist. Dieser enge Feedback-Loop ändert alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er lebt: in Ihrem Repository. Im Moment, dass Sie ihn an eine externe Plattform senden, kommen Übersetzungen auf dem Zeitplan von jemand anderem zurück, und die Integration bricht. Das Feedback, das hätte sofort entstehen können, nimmt jetzt Stunden oder Tage. Der Kontext, der es nützlich gemacht hat, ist lange weg. Sie verlieren den Loop, und damit den ganzen Vorteil, den Agenten-Workflows Ihnen geben sollten.

## Beobachtungen, die Glossia geprägt haben

Diese Frustrationen wurden nicht einfach allein zu Glossia. Das Projekt wuchs aus tiefer Erfahrung in beiden Bereichen, Entwicklung und Lokalisierung, und beitrug Klarheit für Probleme, die von nur einer Seite schwer zu erkennen sind. Das Verständnis der linguistischen Arbeitsabläufe, der menschlichen Dynamiken von Übersetzungsteams und der Gründe, warum existierende Tools so wurden, war essentiell.

Zusammen kamen wir immer wieder auf dieselbe Beobachtung: Lokalisierungswerkzeuge wurden für eine Welt ohne LLMs, ohne Programmierungs-Agenten und ohne CI-Pipelines konzipiert. Das gesamte Modell nahm an, dass Übersetzung etwas war, das außerhalb des Entwicklungsablaufs geschah und wieder hineingestoßen wurde. Das hat vor zehn Jahren Sinn gemacht. Das tut es nicht mehr.

Wir begannen zu fragen: **was wäre, wenn Lokalisierungs-Agenten genauso funktionieren könnten wie Code-Agenten?**

Wir haben genau beobachtet, wie [Anthropic](https://anthropic.com) über Agenten-Workflows mit Claude denkt. Das Muster des Gebens von Zugang zu Werkzeugen, des Denkens durch eine Aufgabe, der Validierung der eigenen Ausgabe und der Iteration, wenn etwas hakt, passt hervorragend zur Lokalisierung. Ein Übersetzungs-Agent, der Ihre Quelldateien lesen, den Projekt-Kontext verstehen, Übersetzungen generieren, Ihren Linter ausführen und Probleme lösen kann, bevor eine Pull-Request erstellt wird. Das ist keine Fantasie. Das ist der Workflow, den wir aufbauen.

## Glossia ist unsere Gabe an die Software-Branche

Wir haben Glossia gebaut, weil wir wollen, dass mehr Software lokalisiert wird, nicht weniger.

Komplizierte Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unzugänglich. Wenn Ihr Übersetzungsworkflow einen Beschaffungsprozess, eine Verhandlung über die Preisgestaltung pro Wort und einen Projektleiter zur Koordination der Übergaben erfordert, versenden die meisten Teams einfach auf Englisch und erledigen den Tag damit.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Tools, nicht mit unseren.

Wir glauben, Lokalisierung sollte so natürlich sein wie das Ausführen Ihrer Testsuite.

## Ein Agent zuerst, Schnittstellen zweitrangig

Im Kern ist Glossia ein Agent. Wir beginnen mit dem Terminal als primärer Schnittstelle, weil dort die schwierigsten Probleme zuerst gelöst werden: das Lesen Ihrer Quelldateien, das Generieren von Übersetzungen, das Ausführen Ihrer Prüfungen und das Iterieren, bis die Ausgabe gültig ist. Dies ist das gleiche Muster, das [OpenAI](https://openai.com) mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code) verfolgt hat. Sie bauen den Agenten, geben ihm ein Terminal und lassen ihn arbeiten.

Aber das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Qualität der Lokalisierung beiträgt, ein Entwickler ist. Wir sprechen dies oft intern an. Die Personen, die sich am meisten um die Genauigkeit der Übersetzung, den Ton und die kulturelle Nuance kümmern, sind oft Linguisten und Content-Spezialisten, die nicht in Begriffen wie Branches, Kompilierung oder JSON denken.

Deshalb wollen wir neue Schnittstellen über demselben Agenten aufbauen. Etwas, wo ein Linguist Inhalt, Kontext und Übersetzung nebeneinander sieht. Sie bringen das menschliche Urteil, das kein Modell ersetzen kann. Sie verfeinern, was verfeinert werden muss. Und der Agent kümmert sich um alles Weitere: Committing, Validieren, das Öffnen des Pull-Requests.

Wir haben noch nicht alle Antworten, und das ist beabsichtigt. Wir würden lieber bedacht daran arbeiten als in eine Oberfläche zu stürzen, die den Kern verfehlt. Aber die Richtung ist klar: Glossia soll alle willkommen heißen, die sich darum kümmern, dass Software jede Sprache spricht.

## Bleiben Sie dran

Glossia ist noch am Anfang, und wir entwickeln es offen. Wenn irgend etwas davon mit Ihrem Ansatz zur Lokalisierung in Resonanz steht, behalten Sie das Projekt im Auge. Wir werden mehr teilen, während wir dabei sind.
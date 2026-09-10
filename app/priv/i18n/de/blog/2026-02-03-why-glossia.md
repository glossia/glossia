%{
  title:
    "Die Lokalisierung war in der Vergangenheit festgefahren. Wir haben Glossia entwickelt, um sie vorwärts zu bringen.",
  summary:
    "Herkömmliche Lokalisierungstools verursachen Overhead, unterbrechen CI und binden Sie an Anbieter-Ökosysteme. Wir erforschen, wie ein agentenbasierter Lokalisierungsworkflow aussehen kann.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie jemals Software in mehreren Sprachen ausgeliefert haben, kennen Sie das Spiel. Sie wählen eine Lokalisierungsplattform, verbinden diese mit Ihrem Repository und verbringen den Rest der Zeit mit dem Synchronisieren. Inhalte gehen raus, Übersetzungen kommen zurück, und irgendwo dazwischen gehen die Dinge schief.

Dieser Overhead, der ständige Hin- und Her-Versand von Inhalten zu und von Ihrem Repository, ist die Steuer, die jedes Team für den Einsatz heutiger Lokalisierungstools entrichtet. Es klingt bagatell, bis Sie selbst debuggen müssen, warum ein Übersetzungs-Pull Request den Build Ihrer Website um 18 Uhr am Freitag zerstört hat.

## Ein Design aus der Zeit vor dem Internet

Die meisten Lokalisierungsplattformen wurden um Konzepte herum entwickelt, die dem modernen Entwicklungsworkflow vorausgingen. Übersetzungsgedächtnisse. Fuzzy Matching. Menschliche Übersetzer, die in proprietären Editoren arbeiten, unterstützt durch Tools, die ähnliche Strings aus einer Datenbank vorschlagen.

Diese Ideen machten Sinn, als Übersetzung ein manueller, offline-Prozess war. Doch Unternehmen wandelten Übersetzungsgedächtnisse in einen Lock-in-Mechanismus. Ihre vergangenen Übersetzungen, das institutionelle Wissen, für das Sie bezahlt haben, leben in ihrer Plattform. Der Wechsel zu einem anderen Anbieter bedeutet, von vorne beginnen oder für einen Export zu zahlen, der nie ganz funktioniert.

Das Ergebnis ist eine Branche, die auf künstliche Reibung gebaut ist. Ihr Inhalt verlässt Ihr Repository, fällt in eine Black Box und kehrt auf einem fremden Zeitplan zurück.

## Der gebrochene Feedback-Loop

Das Problem ist strukturell: Externe Lokalisierungstools können Ihre CI-Pipeline nicht ausführen. Sie wissen nichts über Ihre Linter, Ihren Build-Schritt, Ihren Link-Checker oder Ihre frontmatter-Schema. Sie schieben übersetzten Inhalt zurück in Ihr Repository und hoffen auf das Beste. Wenn es bricht, und es passiert, muss jemand im Team seine Arbeit unterbrechen, um Formatierungsprobleme, fehlerhafte Syntax oder ungültiges Markup zu beheben, das das Übersetzungstool eingeführt hat.

LLMs und agentische Erfahrungen bieten uns neue Möglichkeiten, diese Workflows gänzlich neu zu denken. Ein Agent, der eine Übersetzung generiert, Ihre Prüfungen durchführt, den Fehler erkennt und erneut versucht, bis die Ausgabe gültig ist. Ein solcher enger Feedback-Loop verändert alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er liegt: in Ihrem Repository. Sobald Sie ihn auf eine externe Plattform senden, kehren Übersetzungen auf einem fremden Zeitplan zurück und die Integration bricht. Das Feedback, das hätte sofort sein können, dauert nun Stunden oder Tage. Der Kontext, der es nützlich machte, ist längst verschwunden. Sie verlieren den Loop, und mit ihm den gesamten Vorteil, den Ihnen agentische Workflows eigentlich gewähren sollten.

## Beobachtungen, die Glossia prägten.

Aus diesen Frustrationen wurde Glossia nicht von selbst. Das Projekt entstand aus tiefer Erfahrung in Entwicklung und Lokalisierung, die Klarheit für Probleme brachte, die von einer Seite aus schwer zu erkennen sind. Das Verständnis der linguistischen Workflows, der menschlichen Dynamiken in Übersetzungsteams und der Gründe dafür, warum bestehende Tools so endeten, war essenziell.

Gemeinsam gelangten wir immer wieder zu denselben Beobachtungen: Lokalisierungswerkzeuge waren für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines konzipiert. Das gesamte Modell ging davon aus, dass Übersetzung etwas ist, das außerhalb des Entwicklungs-Workflows geschieht und zurückgespielt wird. Das machte vor zehn Jahren Sinn. Heute nicht mehr.

Wir begannen uns zu fragen: **Was wäre, wenn Lokalisierungsagenten genauso arbeiten könnten wie Coding-Agenten?**

Wir verfolgen genau, wie [Anthropic](https://anthropic.com) denkt über agentische Arbeitsabläufe mit Claude nach. Das Muster, einem Agenten Zugriff auf Tools zu gewähren, es über eine Aufgabe nachzudenken, seine eigene Ausgabe zu validieren und zu iterieren, wenn etwas nicht stimmt, lässt sich erstaunlich gut auf die Lokalisierung übertragen. Ein Übersetzungsagent, der Ihre Quelldateien lesen, den Projekt-Kontext verstehen, Übersetzungen generieren, Ihren Linter ausführen und Probleme beheben kann, bevor er einen Pull Request öffnet. Das ist keine Fantasie. Das ist der Workflow, den wir aufbauen.

## Glossia ist unser Geschenk an die Softwareindustrie

Wir haben Glossia entwickelt, weil wir wollen, dass mehr Software lokalisiert wird, nicht weniger.

Komplizierte Abläufe und teure Plattformen machen die Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unzugänglich. Wenn Ihr Übersetzungsworkflow einen Beschaffungsprozess, eine Preisverhandlung pro Wort und einen Projektmanager für die Koordinierung von Übergaben erfordert, veröffentlichen die meisten Teams einfach auf Englisch und machen damit Schluss.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben. Und es validiert den Output mit Ihren eigenen Tools, nicht mit unseren.

Wir glauben, Lokalisierung sollte so natürlich sein wie das Ausführen Ihrer Testsuite.

## Ein Agent zunächst, Schnittstellen später

Im Kern ist Glossia ein Agent. Wir starten mit dem Terminal als primärer Schnittstelle, denn dort werden die schwierigsten Probleme zuerst gelöst: das Lesen Ihrer Quelldateien, das Generieren von Übersetzungen, das Ausführen Ihrer Prüfungen und das Iterieren, bis der Output gültig ist. Dies ist das gleiche Muster, das [OpenAI](https://openai.com) folgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Sie bauen den Agenten, geben ihm ein Terminal und lassen ihn arbeiten.

Doch das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Qualität der Lokalisierung beiträgt, ein Entwickler ist. Wir sprechen dies oft intern an. Diejenigen, die sich am meisten um Übersetzungspräzision, Tonfall und kulturelle Nuance kümmern, sind oft Linguisten und Content-Spezialisten, die nicht in Begriffen wie Zweig, Kompilierung oder JSON denken.

Deshalb wollen wir neue Schnittstellen über denselben Agenten aufbauen, bei dem ein Linguist Inhalt, Kontext und Übersetzung nebeneinander sieht. Sie bringen das menschliche Urteil, das kein Modell ersetzen kann. Sie verfeinern, was verfeinert werden muss. Und der Agent übernimmt alles andere: das Erstellen von Commits, das Validieren und das Öffnen eines Pull-Requests.

Wir würden es lieber mit Bedacht aufbauen, als in ein UI zu eilen, das den Punkt verfehlt. Noch haben wir nicht alle Antworten, und das ist beabsichtigt. Doch die Richtung ist klar: Glossia soll alle willkommen heißen, die dafür sorgen wollen, dass Software jede Sprache spricht.

## Bleib dran

Glossia befindet sich noch in der Frühphase, und wir entwickeln es im offenen Prozess. Wenn dies mit deiner Vorstellung von Lokalisierung übereinstimmt, halte das Projekt im Auge. Wir werden mehr teilen, während wir vorankommen.
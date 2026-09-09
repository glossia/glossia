%{
  title:
    "Lokalisierung steckte in der Vergangenheit fest. Wir haben Glossia entwickelt, um das voranzutreiben.",
  summary:
    "Traditionelle Lokalisierungstools verursachen Overhead, unterbrechen CI und binden Sie in Anbieter-Ökosysteme ein. Wir erkunden, wie ein agentenbasiertes Lokalisierungsworkflow aussehen könnte.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie jemals Software in mehr als einer Sprache veröffentlicht haben, kennen Sie den Ablauf. Sie wählen eine Lokalisierungsplattform, verbinden diese mit Ihrem Repository und verbringen den Rest Ihrer Zeit damit, den Sync zu verwalten. Inhalte gehen raus, Übersetzungen kommen zurück, und irgendwo dazwischen geht etwas schief.

Dieser Overhead, der ständige Hin- und Herweg des Inhalts zu und von Ihrem Repository, ist der Preis, den jedes Team zahlt, wenn es heutige Lokalisierungs-Tools verwendet. Es klingt nach Kleinigkeit, bis Sie selbst debuggen müssen, warum eine Übersetzungs-PR Ihren Build am Freitag um 18 Uhr zerstört hat.

## Ein Design, das vor dem Internet geerbt wurde

Die meisten Lokalisierungsplattformen wurden nach Konzepten entwickelt, die dem modernen Entwicklungsworkflow vorausgehen. Übersetzungsspeicher. Fuzzy matching. Übersetzer in proprietären Editoren, unterstützt durch Tools, die ähnliche Strings aus einer Datenbank vorschlagen.

Diese Überlegungen hielten Sinn, als die Übersetzung ein manueller, offline-Prozess war. Doch Unternehmen verwandelten Übersetzungsspeicher in einen Lock-in-Mechanismus. Ihre früheren Übersetzungen, das von Ihnen bezahlte institutionelle Wissen, leben in ihrer Plattform. Ein Wechsel zu einem anderen Anbieter bedeutet, bei Null anzufangen, oder für einen Export zu zahlen, der nie wirklich funktioniert.

Das Ergebnis ist eine Branche, die auf künstlicher Reibung basiert. Ihr Inhalt verlässt Ihr Repo, gelangt in eine Black Box und kommt auf einem fremden Zeitplan zurück.

## Der kaputte Feedback-Loop

Das Problem ist strukturell: Externe Lokalisierungstools können Ihre CI-Pipeline nicht ausführen. Sie wissen nichts über Ihre Linter, Ihren Build-Schritt, Ihren Link Checker oder Ihr Frontmatter-Schema. Sie pushen den übersetzten Inhalt zurück in Ihr Repo und hoffen auf das Beste. Wenn es scheitert, und es scheitert, muss jemand im Team innehalten, um Formatierungsfehler, fehlerhafte Syntax oder ungültiges Markup zu beheben, das das Übersetzungstool eingeführt hat.

LLMs und agentische Erfahrungen eröffnen uns neue Möglichkeiten, diese Workflows vollständig neu zu denken. Ein Agent, der eine Übersetzung generiert, Ihre Prüfungen ausführt, den Fehler erkennt und erneut versucht, bis die Ausgabe gültig ist. Ein solches enges Feedback-Loop verändert alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er liegt: in Ihrem Repository. Sobald Sie ihn an eine externe Plattform senden, kehren Übersetzungen auf einem fremden Zeitplan zurück, und die Integration bricht zusammen. Das Feedback, das hätte sofort erfolgen können, dauert jetzt Stunden oder Tage. Der Kontext, der es nützlich gemacht hat, ist längst verschwunden. Sie verlieren das Feedback-Loop und damit den gesamten Vorteil, den agentische Workflows eigentlich bieten sollten.

## Beobachtungen, die Glossia geprägt haben

Diese Frustrationen führten nicht automatisch zu Glossia. Das Projekt entstand aus tiefen Erfahrungen im Bereich Entwicklung und Lokalisierung, was Klarheit für Probleme schuf, die von einer Seite allein schwer zu erkennen sind. Das Verständnis linguistischer Workflows, der menschlichen Dynamiken in Übersetzungsteams und der Gründe, warum bestehende Tools so wurden, wie sie es taten, war essenziell.

Zusammen kamen wir immer wieder auf dieselbe Beobachtung zurück: Lokalisierungstooling wurde für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines entwickelt. Das gesamte Modell ging davon aus, dass Übersetzung etwas sei, das außerhalb des Entwicklungs-Workflows stattfindet und erst später nachträglich integriert wird. Das machte vor zehn Jahren Sinn. Heute nicht mehr.

Wir begannen zu fragen: **was wäre, wenn Lokalisierungsagenten genauso funktionieren würden wie Coding-Agenten?**

Wir achten genau darauf, wie [Anthropic](https://anthropic.com) beschäftigt sich mit agentischen Workflows mit Claude. Das Muster, einem Agenten Zugang zu Tools zu geben, es sich bei Aufgaben zu durchdenken, seine eigene Ausgabe zu validieren und bei Unstimmigkeiten zu iterieren, lässt sich hervorragend auf Lokalisierung übertragen. Ein Übersetzungsagent, der deine Quelldateien lesen, den Projektkontext verstehen, Übersetzungen generieren, deinen Linter ausführen und Probleme beheben kann, bevor ein Pull Request erstellt wird. Das ist keine Fantasie. Das ist der Workflow, den wir bauen.

## Glossia ist unser Geschenk an die Softwareindustrie.

Wir haben Glossia gebaut, weil wir möchten, dass mehr Software lokalisiert wird, nicht weniger.

Komplizierte Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unerschwinglich. Wenn Ihr Übersetzungsworkflow einen Beschaffungsprozess, eine Preisverhandlung pro Wort und einen Projektmanager erfordert, um Übergaben zu koordinieren, liefern die meisten Teams einfach auf Englisch und lassen es dabei.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Tools, nicht mit unseren.

Wir halten Lokalisierung für so natürlich wie die Ausführung Ihrer Testsuite.

## Ein Agent zuerst, Schnittstellen zweiter

Im Kern ist Glossia ein Agent. Wir beginnen damit, das Terminal als die primäre Schnittstelle zu nutzen, weil dort die schwierigsten Probleme zuerst gelöst werden: das Lesen Ihrer Quelldateien, das Generieren von Übersetzungen, das Ausführen Ihrer Prüfungen und die Iteration, bis die Ausgabe gültig ist. Dies ist dasselbe Muster, das [OpenAI](https://openai.com) verfolgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Du baust den Agenten, gibst ihm ein Terminal und lässt es arbeiten.

Aber das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Qualität von Lokalisierung beiträgt, ein Entwickler ist. Wir sprechen das oft intern an. Die Menschen, die am meisten auf Übersetzungsqualität, Ton und kulturelle Nuancen achten, sind oft Linguisten und Content-Spezialisten, die nicht in Begriffen wie Branches, Kompilierung oder JSON denken.

Deshalb wollen wir neue Schnittstellen auf denselben Agenten aufbauen. Etwas, in dem ein Linguist Inhalt, Kontext und Übersetzung nebeneinander sieht. Sie bringen das menschliche Urteil, das kein Modell ersetzen kann. Sie verfeinern das, was verfeinert werden muss. Und der Agent erledigt alles Weitere: Committing, Validieren, das Erstellen des Pull Requests.

Wir haben noch nicht alle Antworten, und das ist beabsichtigt. Wir würden es lieber durchdacht bauen, als uns in eine Benutzeroberfläche zu stürzen, die den Punkt verfehlt. Aber die Richtung ist klar: Glossia soll jeden willkommen heißen, der dafür sorgt, dass Software jede Sprache sprechen kann.

## Bleibt dran

Glossia ist noch am Anfang, und wir entwickeln es offen. Wenn dies mit Ihrer Vorstellung von Lokalisierung übereinstimmt, behalten Sie das Projekt im Auge. Wir werden im Laufe der Zeit mehr teilen.
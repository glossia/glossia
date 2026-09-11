%{
  title:
    "Lokalisierung war in der Vergangenheit festgefahren. Wir haben Glossia entwickelt, um es vorwärts zu bringen.",
  summary:
    "Herkömmliche Lokalisierungstools verursachen Overhead, brechen CI und binden Sie in Anbieter-Ökosysteme ein. Wir erforschen, wie ein agentenbasierter Lokalisierungsworkflow aussehen kann.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie jemals Software in mehr als einer Sprache ausgeliefert haben, kennen Sie das Ritual. Sie wählen eine Lokalisierungsplattform, verbinden sie mit Ihrem Repository und verbringen den Rest Ihrer Zeit mit dem Synchronisierungs-Management. Der Inhalt geht raus, Übersetzungen kommen zurück, und irgendwo dazwischen gehen die Dinge kaputt.

Dieser Overhead, der ständige Hin-und-Her-Takt des Inhalts zu und von Ihrem Repository, ist der Preis, den jedes Team für die Nutzung heutiger Lokalisierungstools zahlt. Es klingt unbedeutend, bis Sie debuggen müssen, warum eine Übersetzungs-PR um 18 Uhr am Freitag Ihren Site-Build kaputt gemacht hat.

## Ein von vor dem Internet geerbtes Design

Die meisten Lokalisierungsplattformen wurden um Konzepte entwickelt, die dem modernen Entwicklungsweg vorausgehen. Übersetzungsgedächtnisse. Fuzzy Matching. Menschliche Übersetzer in proprietären Editoren, unterstützt durch Tools, die ähnliche Zeichenketten aus einer Datenbank vorschlagen.

Diese Ideen machten Sinn, als Übersetzung ein manueller, offline Prozess war. Doch Firmen verwandelten Übersetzungsgedächtnisse in einen Lock-in-Mechanismus. Ihre vergangenen Übersetzungen, das institutionelle Wissen, für das Sie bezahlt haben, leben in ihrer Plattform. Zu einem anderen Anbieter zu wechseln bedeutet, bei Null anzufangen, oder für einen Export zu zahlen, der nie ganz funktioniert.

Das Ergebnis ist eine Branche, die auf künstlicher Reibung basiert. Ihr Inhalt verlässt Ihr Repository, durchläuft eine Black-Box und kehrt nach einem Zeitplan von jemand anderem zurück.

## Der kaputte Feedback-Loop

Das Problem ist strukturell: externe Lokalisierungstools können Ihre CI-Pipeline nicht ausführen. Sie wissen nicht über Ihre Linter, Build-Schritt, Link-Checker oder Ihr Frontmatter-Schema Bescheid. Sie schieben übersetzten Inhalt zurück ins Repository und hoffen auf das Beste. Wenn es kaputtgeht, muss jemand im Team die Arbeit unterbrechen, um Formatierungsprobleme, kaputte Syntax oder ungültiges Markup zu beheben, das das Übersetzungs-Tool eingeführt hat.

LLMs und agentische Erfahrungen bieten uns neue Möglichkeiten, diese Workflows komplett neu zu denken. Ein Agent, der eine Übersetzung generiert, Ihre Prüfungen durchführt, den Fehler erkennt und erneut versucht, bis der Output gültig ist. Solch ein enger Feedback-Loop verändert alles.

Es funktioniert nur, wenn der Inhalt dort bleibt, wo er ist: in Ihrem Repository. Sobald Sie ihn an eine externe Plattform senden, kommen Übersetzungen auf einer fremden Timeline zurück und die Integration bricht zusammen. Das Feedback, das sofort sein könnte, dauert jetzt Stunden oder Tage. Der Kontext, der es nützlich gemacht hat, ist längst verschwunden. Sie verlieren den Loop und mit ihm den gesamten Vorteil, den Agenten-Workflows bieten sollten.

## Beobachtungen, die Glossia geprägt haben

Diese Frustrationen haben sich nicht von selbst in Glossia verwandelt. Das Projekt wuchs aus tiefer Erfahrung in Entwicklung und Lokalisierung, die Klarheit über Probleme brachte, die von einer Seite schwer zu sehen sind. Das Verständnis sprachlicher Workflows, menschlicher Dynamiken in Übersetzungsteams und der Gründe, warum bestehende Tools so geworden sind wie sie sind, war entscheidend.

Zusammen kamen wir immer wieder auf dieselben Beobachtungen zurück: Lokalisierungswerkzeuge wurden für eine Welt ohne LLMs, ohne Codingagenten und ohne CI-Pipelines entworfen. Das gesamte Modell ging davon aus, dass Übersetzung außerhalb des Entwicklungsworkflows stattfand und später in den Workflow integriert wurde. Das hatte vor zehn Jahren Sinn. Das nicht mehr.

Wir fragten uns: **Was wäre, wenn Lokalisierungsagenten genauso arbeiten könnten wie Codingagenten?**

Wir achten genau darauf, wie [Anthropic](https://anthropic.com) denkt über agentische Workflows mit Claude nach. Das Muster, einem Agenten Zugriff auf Werkzeuge zu geben, ihm zu lassen, sich durch eine Aufgabe zu durchzudenken, seine eigene Ausgabe zu validieren und zu iterieren, wenn etwas nicht stimmt, lässt sich hervorragend auf die Lokalisierung übertragen. Ein Übersetzungsagent, der deine Quelldateien lesen, den Projektzusammenhang verstehen, Übersetzungen generieren, deinen Linter ausführen und Probleme beheben kann, bevor du einen Pull Request öffnest. Das ist kein Wunschtraum. Das ist der Workflow, den wir aufbauen.

## Glossia ist unser Geschenk an die Softwareindustrie

Wir haben Glossia gebaut, weil wir wollen, dass mehr Software lokalisiert wird, nicht weniger.

Komplizierte Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unerschwinglich. Wenn Ihr Übersetzungsablauf einen Beschaffungsprozess, eine Preisverhandlung pro Wort und einen Projektmanager zur Koordination der Übergabe erfordert, werden die meisten Teams einfach auf Englisch ausliefern und den Tag damit als erledigt ansehen.

Glossia nutzt Modelle, auf die Sie ohnehin Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Werkzeugen, nicht unseren.

Wir glauben, dass Lokalisierung so natürlich sein sollte wie die Ausführung Ihrer Test-Suite.

## Ein Agent zuerst, Schnittstellen zweiter.

Im Kern ist Glossia ein Agent. Wir beginnen mit dem Terminal als seiner primären Schnittstelle, denn dort werden die schwierigsten Probleme zuerst gelöst: das Lesen Ihrer Quelldateien, das Generieren von Übersetzungen, das Ausführen Ihrer Prüfungen und das Iterieren, bis die Ausgabe gültig ist. Dies ist das gleiche Muster, das [OpenAI](https://openai.com) verfolgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Du baust den Agenten, gib ihm ein Terminal und lass ihn arbeiten.

Aber das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Lokalisierungsqualität beiträgt, ein Entwickler ist. Wir sprechen dies oft intern an. Die Menschen, die sich am meisten um Übersetzungsgenauigkeit, Ton und kulturelle Nuancen kümmern, sind oft Linguisten und Content-Spezialisten, die nicht in Begriffen wie Branches, Kompilierung oder JSON denken.

Deswegen wollen wir neue Schnittstellen aufbauend auf demselben Agenten erstellen. Etwas, bei dem ein Linguist Inhalt, Kontext und die Übersetzung nebeneinander sieht. Sie bringen das menschliche Urteil, das kein Modell ersetzen kann. Sie verfeinern, was verfeinert werden muss. Und der Agent übernimmt das Übrige: Committing, Validieren und das Öffnen des Pull-Requests.

Wir haben noch nicht alle Antworten, und das ist beabsichtigt. Wir würden lieber bedacht aufbauen, als in eine Benutzeroberfläche zu stürzen, die den Punkt verfehlt. Aber die Richtung ist klar: Glossia soll jeden willkommen heißen, der es sich darum verdienen, dass Software jede Sprache spricht.

## Bleiben Sie dran

Glossia befindet sich noch in der Frühphase, und wir entwickeln es in offener Entwicklung. Wenn sich dies mit Ihrer Vorstellung von Lokalisierung deckt, bleiben Sie dem Projekt auf der Spur. Wir werden mehr teilen, während wir weitermachen.
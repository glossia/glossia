%{
  title:
    "Die Lokalisierung war in der Vergangenheit festgefahren. Wir haben Glossia entwickelt, um sie voranzutreiben.",
  summary:
    "Traditionelle Lokalisierungstools verursachen Overhead, brechen CI und binden Sie in Anbieter-Ökosysteme ein. Wir erforschen, wie sich ein agentischer Lokalisierungsworkflow gestalten könnte.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie bereits Software in mehr als einer Sprache ausgeliefert haben, kennen Sie das Prinzip. Sie wählen eine Lokalisierungsplattform, verbinden sie mit Ihrem Repository und verbringen den Rest Ihrer Zeit mit der Verwaltung der Synchronisation. Inhalte gehen raus, Übersetzungen kommen zurück und irgendwo dazwischen geht es schief.

Dieser Overhead, die konstante Hin- und Herfahrt von Inhalten zu und von Ihrem Repository, ist der Preis, den jedes Team für die Nutzung heutiger Lokalisierungs-Tools bezahlt. Es klingt vernachlässigbar, bis Sie selbst derjenige sind, der debuggt, warum eine Übersetzungs-Pull Request Ihren Website-Build am Freitag um 18:00 Uhr kaputt gemacht hat.

## Ein Design aus der Zeit vor dem Internet

Die meisten Lokalisierungsplattformen wurden basierend auf Konzepten gestaltet, die dem modernen Entwicklungsworkflow vorausgehen. Übersetzungsspeicher. Fuzzy Matching. Menschliche Übersetzer, die in proprietären Editoren arbeiten, unterstützt durch Tools, die ähnliche Zeichenfolgen aus einer Datenbank vorschlagen.

Diese Ideen machten Sinn, als Übersetzung ein manueller, offline-Prozess war. Aber Unternehmen verwandelten Übersetzungsspeicher in einen Lock-In-Mechanismus. Ihre vergangenen Übersetzungen, das institutionelle Wissen, das Sie bezahlt haben, leben in ihrer Plattform. Ein Wechsel zu einem anderen Anbieter bedeutet, bei Null anzufangen, oder für einen Export zu zahlen, der niemals ganz funktioniert.

Das Ergebnis ist eine Branche, die auf künstlicher Reibung aufbaut. Ihr Inhalt verlässt Ihr Repo, betritt eine Blackbox und kehrt auf einem fremden Zeitplan zurück.

## Der gebrochene Feedback-Loop

Das Problem ist strukturell: Externe Lokalisierungs-Tools können Ihre CI-Pipeline nicht ausführen. Sie kennen Ihre Linter, Ihren Build-Schritt, Ihren Link-Checker oder Ihr Frontmatter-Schema nicht. Sie schieben übersetzten Inhalt zurück in Ihr Repo und hoffen auf das Beste. Wenn es bricht, und es passiert, muss jemand im Team die Arbeit unterbrechen, um Formatierungsfehler, fehlerhafte Syntax oder ungültiges Markup zu beheben, das das Übersetzungs-Tool eingeführt hat.

LLMs und agentische Erfahrungen bieten uns neue Möglichkeiten, diese Workflows vollständig neu zu denken. Ein Agent, der eine Übersetzung erstellt, Ihre Prüfungen durchführt, den Fehler erkennt und erneut versucht, bis die Ausgabe gültig ist. Eine solche enge Rückkopplungsschleife verändert alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er liegt: in Ihrem Repository. Sobald Sie ihn an eine externe Plattform senden, kehren die Übersetzungen in fremden Zeitplänen zurück und die Integration bricht. Das Feedback, das eigentlich augenblicklich gewesen wäre, dauert nun Stunden oder Tage. Der Kontext, der es nützlich gemacht hat, ist längst weg. Sie verlieren die Schleife und damit den gesamten Vorteil, den agentische Workflows eigentlich bieten sollten.

## Beobachtungen, die Glossia geprägt haben

Diese Frustrationen hätten sich nicht von selbst in Glossia entwickelt. Das Projekt entstand aus tiefem Erfahrungswissen in Entwicklung und Lokalisierung, was Klarheit über Probleme brachte, die aus einer Perspektive schwer zu erkennen sind. Das Verständnis der linguistischen Workflows, der menschlichen Dynamiken in Übersetzungsteams und der Gründe, warum bestehende Werkzeuge so wurden, wie sie sind, war essenziell.

Zusammen sind wir immer wieder auf dieselben Beobachtungen gestoßen: Lokalisierungswerkzeuge wurden für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines entwickelt. Das gesamte Modell ging davon aus, dass Übersetzung außerhalb des Entwicklungsworkflows stattfindet und erst danach eingebaut wird. Das machte vor zehn Jahren Sinn. Das tut es nicht mehr.

Wir begannen uns zu fragen: **was wäre, wenn Lokalisierungsagenten genauso arbeiten könnten wie Coding-Agenten?**

Wir verfolgen aufmerksam, wie [Anthropic](https://anthropic.com) denkt über agentische Workflows mit Claude nach. Das Muster, einem Agenten Zugriff auf Tools zu gewähren, ihm das Durchdenken einer Aufgabe zu ermöglichen, seine eigene Ausgabe zu validieren und zu iterieren, wenn etwas nicht passt, entspricht erstaunlich gut der Lokalisierung. Ein Übersetzungsagent, der Ihre Quelldateien lesen, den Projektkontext verstehen, Übersetzungen generieren, Ihren Linter ausführen und Probleme beheben kann, bevor Sie einen Pull Request öffnen. Das ist keine Fantasie. Das ist der Workflow, den wir entwickeln.

## Glossia ist unser Geschenk an die Softwareindustrie

Wir haben Glossia gebaut, weil wir möchten, dass mehr Software lokalisiert wird, nicht weniger.

Komplexe Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unzugänglich. Wenn Ihr Übersetzungsablauf einen Beschaffungsprozess, eine pro-Wort-Preisverhandlung und einen Projektmanager zur Koordination von Übergaben erfordert, veröffentlichen die meisten Teams einfach auf Englisch und betrachten es als erledigt.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Tools, nicht unseren.

Wir meinen, dass Lokalisierung so natürlich sein sollte wie das Ausführen Ihrer Testsuite.

## Ein Agent zuerst, Schnittstellen zweite.

Im Kern ist Glossia ein Agent. Wir starten mit dem Terminal als primäre Schnittstelle, weil dort die schwierigsten Probleme zuerst gelöst werden: das Lesen Ihrer Quelldateien, die Generierung von Übersetzungen, das Ausführen Ihrer Prüfungen und das Iterieren, bis die Ausgabe gültig ist. Dies ist das gleiche Muster, das [OpenAI](https://openai.com) folgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Sie erstellen den Agenten, stellen ihm ein Terminal zur Verfügung und lassen ihn arbeiten.

Aber das Terminal ist nur das erste Interface, nicht das einzige. Wir wissen, dass nicht jeder, der zur Lokalisierungsqualität beiträgt, ein Entwickler ist. Davon sprechen wir oft intern. Diejenigen, die sich am meisten um Übersetzungspräzision, Ton und kulturelle Nuancen kümmern, sind oft Linguisten und Content-Spezialisten, die nicht in Begriffen von Branches, Kompilierung oder JSON denken.

Deshalb wollen wir neue Schnittstellen auf demselben Agenten aufbauen. Etwas, wo ein Linguist den Inhalt, den Kontext und die Übersetzung nebeneinander sieht. Sie bringen das menschliche Urteil, das kein Modell ersetzen kann. Sie verfeinern, was Verfeinerung bedarf. Und der Agent übernimmt alles andere: Commiten, Validieren und das Öffnen des Pull-Requests.

Wir haben noch nicht alle Antworten, und das ist so gewollt. Wir ziehen es vor, dies sorgfältig zu gestalten, statt in eine UI zu hetzen, die den Kern verfehlt. Aber die Richtung ist klar: Glossia soll alle willkommen heißen, die dafür sorgen, dass Software jede Sprache spricht.

## Bleibt dran

Glossia befindet sich noch in der Anfangsphase und wir entwickeln es offen. Wenn dies eure Vorstellung von Lokalisierung widerspiegelt, haltet das Projekt im Auge. Wir werden unterwegs noch mehr teilen.
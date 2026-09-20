%{
  title:
    "Lokalisierung steckte in der Vergangenheit fest. Wir haben Glossia entwickelt, um sie voranzutreiben.",
  summary:
    "Traditionelle Lokalisierungstools verursachen Overhead, unterbrechen CI und binden Sie an Anbieter-Ökosysteme. Wir erforschen, wie ein agentenbasierter Lokalisierungs-Workflow aussehen könnte.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie jemals Software in mehr als einer Sprache ausgeliefert haben, kennen Sie das Spiel. Sie wählen eine Lokalisierungsplattform, verbinden diese mit Ihrem Repository und verbringen den Rest Ihrer Zeit mit der Verwaltung der Synchronisation. Inhalte gehen raus, Übersetzungen kommen zurück, und irgendwo dazwischen gehen die Dinge kaputt.

Dieser Aufwand, der konstante Rundweg von Inhalten zu und von Ihrem Repository, ist der Preis, den jedes Team für den Einsatz aktueller Lokalisierungstools zahlt. Er wirkt vorerst geringfügig, bis Sie selbst gerade derjenige sind, der debuggt, warum eine Übersetzungs-PR Ihre Site-Build am Freitag um 17:00 Uhr zerstört.

## Ein aus der Zeit vor dem Internet übernommenes Design

Die meisten Lokalisierungsplattformen wurden um Konzepte herum entwickelt, die dem modernen Entwicklungsworkflow vorangingen. Übersetzungsspeicher. Fuzzy-Matching. Menschliche Übersetzer arbeiteten in proprietären Editoren, unterstützt durch Tools, die ähnliche Strings aus einer Datenbank vorschlagen.

Diese Ideen machten Sinn, als Übersetzung noch ein manueller, offline-Prozess war. Doch Firmen verwandelten Übersetzungsspeicher in einen Lock-in-Mechanismus. Ihre vergangenen Übersetzungen, das für Sie bezahlte institutionelle Wissen, leben in ihrer Plattform. Der Wechsel zu einem anderen Anbieter bedeutet, von Null anzufangen, oder den Preis für einen Export zu zahlen, der niemals wirklich funktioniert.

Das Ergebnis ist eine Branche, die auf künstlicher Reibung aufgebaut ist. Ihr Inhalt verlässt Ihr Repository, gelangt in eine Blackbox und kehrt auf fremden Zeitplänen zurück.

## Der unterbrochene Feedback-Loop

Das Problem ist strukturell: Externe Lokalisierungstools können Ihre CI-Pipeline nicht ausführen. Sie wissen nichts über Ihre Linter, Ihren Build-Schritt, Ihren Link-Checker oder Ihr Frontmatter-Schema. Sie drücken den übersetzten Inhalt zurück in Ihr Repository und hoffen auf das Beste. Wenn es bricht - und es tut das - muss jemand im Team seine Arbeit unterbrechen, um Formatierungsfehler, defekte Syntax oder ungültiges Markup zu beheben, das das Übersetzungstool eingeführt hat.

LLMs und agentische Erfahrungen eröffnen uns neue Möglichkeiten, diese Workflows grundlegend neu zu denken. Ein Agent, der eine Übersetzung erzeugt, Ihre Prüfungen durchführen lässt, den Fehler erkennt und erneut versucht, bis die Ausgabe gültig ist. Eine solche enge Feedback-Schleife verändert alles.

Aber es funktioniert nur, wenn der Inhalt dort bleibt, wo er ist: in Ihrem Repository. Sobald Sie ihn an eine externe Plattform senden, kehren Übersetzungen auf einem fremden Zeitplan zurück und die Integration bricht. Das Feedback, das eigentlich sofort gewesen wäre, dauert jetzt Stunden oder Tage. Der Kontext, der es nützlich machte, ist längst vergangen. Sie verlieren die Schleife und damit den gesamten Vorteil, den agentische Workflows Ihnen bieten sollten.

## Beobachtungen, die Glossia geformt haben.

Diese Frustrationen wurden nicht allein zu Glossia. Das Projekt entstand aus tiefer Erfahrung sowohl in der Entwicklung als auch in der Lokalisierung, was Klarheit für Probleme bot, die aus nur einer Perspektive schwer zu erkennen sind. Das Verständnis sprachlicher Workflows, der menschlichen Dynamiken in Übersetzungsteams und der Gründe, warum bestehende Tools so geworden sind, war unerlässlich.

Gemeinsam kamen wir immer wieder zu denselben Beobachtungen: Lokalisierungswerkzeuge waren für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines entworfen. Das gesamte Modell ging davon aus, dass Übersetzung etwas war, das außerhalb des Entwicklungsworkflows stattfand und erst später nachgereicht wurde. Das machte vor zehn Jahren Sinn. Heute schon nicht mehr.

Wir begannen uns zu fragen: **Was wäre, wenn Lokalisierungsagenten ebenso funktionieren könnten wie Coding-Agenten?**

Wir achten genau darauf, wie [Anthropic](https://anthropic.com) denkt über Agenten-Workflows mit Claude nach. Das Muster, einem Agenten Zugriff auf Werkzeuge zu gewähren, ihm das Durchdenken einer Aufgabe, das Validieren des eigenen Ergebnisses und das Iterieren bei Fehlern zu erlauben, passt erstaunlich gut zur Lokalisierung. Ein Übersetzungs-Agent kann Ihre Quelldateien lesen, den Projekt-Kontext verstehen, Übersetzungen generieren, Ihren Linter ausführen und Probleme beheben, bevor ein Pull Request eingereicht wird. Das ist keine Fantasie. Das ist der Workflow, den wir aufbauen.

## Glossia ist unser Geschenk an die Softwareindustrie.

Wir haben Glossia gebaut, weil wir möchten, dass mehr Software lokalisiert wird, nicht weniger.

Komplizierte Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unzugänglich. Wenn Ihr Übersetzungsworkflow einen Beschaffungsprozess, eine Verhandlung über die Preisgestaltung pro Wort und einen Projektmanager erfordert, um Übergaben zu koordinieren, veröffentlichen die meisten Teams auf Englisch und betrachten das als erledigt.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben. Und es validiert Ausgabe mit Ihren eigenen Tools, nicht unseren.

Wir glauben, dass Lokalisierung so natürlich sein sollte, wie das Ausführen Ihrer Test-Suite.

## Ein Agent zuerst, Schnittstellen später.

Im Kern ist Glossia ein Agent. Wir beginnen mit dem Terminal als primäre Schnittstelle, weil dort die härtesten Probleme zuerst gelöst werden: das Lesen Ihrer Quelldateien, das Generieren von Übersetzungen, das Durchführen Ihrer Prüfungen und das Iterieren, bis die Ausgabe gültig ist. Dies ist dasselbe Muster, das [OpenAI](https://openai.com) folgte mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Sie bauen den Agenten, geben ihm ein Terminal und lassen ihn arbeiten.

Aber das Terminal ist nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Qualität der Lokalisierung beiträgt, Entwickler ist. Wir besprechen dies oft intern. Diejenigen, denen Übersetzungspräzision, Ton und kulturelle Nuance am meisten am Herzen liegen, sind oft Linguisten und Content-Spezialisten, die nicht in Bezug auf Zweige, Kompilierung oder JSON denken.

Deshalb möchten wir neue Schnittstellen über denselben Agenten aufbauen. Etwas, bei dem ein Linguist Inhalt, Kontext und Übersetzung nebeneinander sieht. Sie bringen das menschliche Urteil, das kein Modell ersetzen kann. Sie verfeinern das, was verfeinert werden muss. Und der Agent übernimmt alles andere: Committing, Validieren und das Öffnen des Pull-Requests.

Wir haben noch nicht alle Antworten, und das ist beabsichtigt. Wir ziehen es vor, dies sorgfältig zu bauen, statt in eine UI zu hetzen, die den Punkt verfehlt. Doch die Richtung ist klar: Glossia sollte jeden willkommen heißen, der sich dafür einsetzt, dass Software jede Sprache spricht.

## Bleiben Sie auf dem Laufenden

Glossia befindet sich noch in der Frühphase, und wir entwickeln sie offen. Wenn dies mit Ihrer Vorstellung von Lokalisierung übereinstimmt, behalten Sie das Projekt im Auge. Wir werden im weiteren Verlauf weitere Informationen berichten.
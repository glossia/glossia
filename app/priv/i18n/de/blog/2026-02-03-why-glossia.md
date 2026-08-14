%{
  title: "Lokalisierung steckte in der Vergangenheit fest. Wir haben Glossia entwickelt, um sie voranzubringen.",
  summary: "Herkömmliche Lokalisierungstools verursachen Mehraufwand, unterbrechen die CI und binden Sie an Anbieter-Ökosysteme. Wir untersuchen, wie ein agentenbasierter Lokalisierungs-Workflow aussehen kann.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Wenn Sie jemals Software in mehr als einer Sprache bereitgestellt haben, kennen Sie das Prozedere. Sie wählen eine Lokalisierungsplattform, verbinden sie mit Ihrem Repository und verbringen die restliche Zeit mit der Verwaltung der Synchronisierung. Inhalte gehen raus, Übersetzungen kommen zurück, und irgendwo dazwischen geht etwas schief.

Dieser Aufwand, der ständige Kreislauf von Inhalten aus Ihrem und in Ihr Repository, ist die Gebühr, die jedes Team für die Nutzung heutiger Lokalisierungswerkzeuge zahlt. Es klingt unbedeutend, bis Sie am Freitagabend um 18:00 Uhr debuggen müssen, warum ein Übersetzungs-PR Ihren Website-Build beschädigt hat.

## Ein Design, das aus der Zeit vor dem Internet stammt

Die meisten Lokalisierungsplattformen wurden um Konzepte herum entwickelt, die älter sind als der moderne Entwicklungs-Workflow. Translation Memories. Fuzzy-Matching. Menschliche Übersetzer, die in proprietären Editoren arbeiten, unterstützt von Werkzeugen, die ähnliche Zeichenketten aus einer Datenbank vorschlagen.

Diese Ideen waren sinnvoll, als Übersetzung noch ein manueller Offline-Prozess war. Doch Unternehmen haben Translation Memories in einen Lock-in-Mechanismus verwandelt. Ihre vergangenen Übersetzungen, das institutionelle Wissen, für das Sie bezahlt haben, verbleiben auf deren Plattform. Der Wechsel zu einem anderen Anbieter bedeutet, wieder bei Null anzufangen oder für einen Export zu bezahlen, der nie richtig funktioniert.

Das Ergebnis ist eine Branche, die auf künstlichen Hürden aufbaut. Ihre Inhalte verlassen Ihr Repository, gelangen in eine Black Box und kehren nach dem Zeitplan eines anderen zurück.

## Die gestörte Feedback-Schleife

Das Problem ist struktureller Natur: Externe Lokalisierungswerkzeuge können Ihre CI-Pipeline nicht ausführen. Sie wissen nichts von Ihren Lintern, Ihrem Build-Schritt, Ihrem Link-Prüfer oder Ihrem Frontmatter-Schema. Sie übertragen übersetzte Inhalte zurück in Ihr Repository und hoffen das Beste. Wenn es scheitert, und das tut es, muss jemand im Team die Arbeit unterbrechen, um Formatierungsprobleme, fehlerhafte Syntax oder ungültiges Markup zu beheben, die das Lokalisierungswerkzeug verursacht hat.

LLMs und agentenbasierte Ansätze bieten uns neue Möglichkeiten, diese Workflows völlig neu zu überdenken. Ein Agent, der eine Übersetzung generiert, Ihre Prüfungen ausführt, den Fehler erkennt und es erneut versucht, bis das Ergebnis gültig ist. Eine derart enge Feedback-Schleife verändert alles.

Das funktioniert jedoch nur, wenn die Inhalte dort bleiben, wo sie hingehören: in Ihrem Repository. In dem Moment, in dem Sie sie an eine externe Plattform senden, kommen Übersetzungen nach dem Zeitplan anderer zurück und die Integration bricht zusammen. Das Feedback, das sofort hätte erfolgen können, dauert nun Stunden oder Tage. Der Kontext, der es nützlich gemacht hat, ist längst verloren. Sie verlieren die Schleife und damit den gesamten Vorteil, den agentenbasierte Workflows Ihnen eigentlich bieten sollten.

## Erkenntnisse, die Glossia geprägt haben

Diese Frustrationen haben sich nicht von selbst in Glossia verwandelt. Das Projekt entstand aus tiefgehender Erfahrung sowohl in der Entwicklung als auch in der Lokalisierung, was Klarheit über Probleme brachte, die aus nur einer Perspektive schwer zu erkennen sind. Es war unerlässlich, die linguistischen Arbeitsabläufe, die menschliche Dynamik von Übersetzungsteams und die Gründe zu verstehen, warum bestehende Werkzeuge so geworden sind, wie sie sind.

Gemeinsam kamen wir immer wieder zu derselben Erkenntnissen: Lokalisierungswerkzeuge wurden für eine Welt ohne LLMs, ohne Coding-Agenten und ohne CI-Pipelines entwickelt. Das gesamte Modell ging davon aus, dass Übersetzungen außerhalb des Entwicklungs-Workflows stattfanden und anschließend wieder zurückgespielt wurden. Das war vor zehn Jahren sinnvoll. Heute ist es das nicht mehr.

Wir begannen uns zu fragen: **Was wäre, wenn Lokalisierungs-Agenten genauso arbeiten könnten wie Coding-Agenten?**

Wir haben genau verfolgt, wie [Anthropic](https://anthropic.com) über agentenbasierte Workflows mit Claude denkt. Das Muster, einem Agenten Zugriff auf Werkzeuge zu geben, ihn eine Aufgabe durchdenken zu lassen, sein eigenes Ergebnis zu validieren und zu iterieren, wenn etwas nicht stimmt, lässt sich hervorragend auf die Lokalisierung übertragen. Ein Übersetzungs-Agent, der Ihre Quelldateien lesen, den Projektkontext verstehen, Übersetzungen generieren, Ihren Linter ausführen und Probleme beheben kann, bevor er einen Pull-Request öffnet. Das ist keine Fantasie. Das ist der Workflow, den wir entwickeln.

## Glossia ist unser Geschenk an die Softwareindustrie

Wir haben Glossia entwickelt, weil wir möchten, dass mehr Software lokalisiert wird, nicht weniger.

Komplizierte Prozesse und teure Plattformen machen Lokalisierung für kleine Teams, Indie-Entwickler und Nebenprojekte unzugänglich. Wenn Ihr Übersetzungsworkflow einen Beschaffungsprozess, Preisverhandlungen pro Wort und einen Projektmanager zur Koordination von Übergaben erfordert, werden die meisten Teams ihre Software einfach auf Englisch veröffentlichen und es dabei belassen.

Glossia nutzt Modelle, auf die Sie bereits Zugriff haben. Und es validiert die Ausgabe mit Ihren eigenen Werkzeugen, nicht mit unseren.

Wir sind der Ansicht, dass Lokalisierung so natürlich sein sollte wie das Ausführen Ihrer Testsuite.

## Zuerst ein Agent, dann die Schnittstellen

Im Kern ist Glossia ein Agent. Wir beginnen mit dem Terminal als primärer Schnittstelle, da dort die schwierigsten Probleme zuerst gelöst werden: das Lesen Ihrer Quelldateien, das Erstellen von Übersetzungen, das Ausführen Ihrer Prüfungen und das Iterieren, bis die Ausgabe gültig ist. Dies ist dasselbe Muster, das [OpenAI](https://openai.com) mit [Codex](https://openai.com/index/openai-codex/) und [Anthropic](https://anthropic.com) mit [Claude Code](https://docs.anthropic.com/en/docs/claude-code) verfolgt hat. Sie entwickeln den Agenten, geben ihm ein Terminal und lassen ihn arbeiten.

Das Terminal ist jedoch nur die erste Schnittstelle, nicht die einzige. Wir wissen, dass nicht jeder, der zur Lokalisierungsqualität beiträgt, ein Entwickler ist. Darüber sprechen wir intern oft. Die Personen, denen Übersetzungsgenauigkeit, Tonalität und kulturelle Nuancen am wichtigsten sind, sind häufig Linguisten und Inhaltsspezialisten, die nicht in Kategorien wie Branches, Kompilierung oder JSON denken.

Aus diesem Grund möchten wir neue Schnittstellen auf Basis desselben Agenten entwickeln. Eine Lösung, bei der Linguisten den Inhalt, den Kontext und die Übersetzung nebeneinander sehen. Sie bringen das menschliche Urteilsvermögen ein, das kein Modell ersetzen kann. Sie verfeinern, was verfeinert werden muss. Und der Agent übernimmt alles andere: Committen, Validieren und das Erstellen des Pull Requests.

Wir haben noch nicht alle Antworten, und das ist Absicht. Wir möchten dies lieber durchdacht aufbauen, anstatt eine Benutzeroberfläche zu überstürzen, die am Kern vorbeigeht. Die Richtung ist jedoch klar: Glossia soll jeden willkommen heißen, dem es wichtig ist, dass Software jede Sprache spricht.

## Bleiben Sie auf dem Laufenden

Glossia steht noch am Anfang, und wir entwickeln es öffentlich. Wenn diese Ansätze Ihrer Vorstellung von Lokalisierung entsprechen, behalten Sie das Projekt im Auge. Wir werden im weiteren Verlauf mehr Informationen teilen.
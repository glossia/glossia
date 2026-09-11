%{
  title:
    "Ein KI-zentriertes Unternehmen aufbauen, um eine Branche herauszufordern, die sich nicht selbst neu erfinden kann.",
  summary:
    "Etablierte Lokalisierungsunternehmen verfügen zwar über das Kapital, nicht aber über die Freiheit zu innovieren. Wir gestalten Glossia von Grund auf neu rund um KI und Agenten, nicht nur im Produkt, sondern auch in der Art und Weise, wie wir das gesamte Unternehmen betreiben.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten transformieren alles. Nicht nur, was Software leisten kann, sondern wie Unternehmen aufgebaut sind, um diese Software zu entwickeln. Bei [Glossia](https://glossia.ai), sehen wir dies als eine einmalige Chance für eine Generation, neu zu denken, wie Inhalte jede Sprache erreichen. Doch wir wissen auch, dass eine gute Produktidee allein nicht ausreicht. Sie benötigen eine Organisation, die schnell genug sein kann, um relevant zu sein.

Genau darum geht es in diesem Beitrag.

## Das Innovatordilemma, das sich in Echtzeit abspielt

Die Lokalisierungsbranche ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise bauen seit Jahren Tools und Dienstleistungen auf. Sie verfügen über Kunden, Umsätze, etablierte Workflows und Teams, die wissen, wie sie ihre Produkte verkaufen und unterstützen.

Also warum würde ein kleines, fokussiertes Team es überhaupt versuchen?

Weil es etwas war, das Clayton Christensen beschrieben hat in [Das Innovator-Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): Etablierte Unternehmen haben Schwierigkeiten, disruptive Innovationen anzunehmen, nicht wegen fehlender Ressourcen, sondern weil ihre bestehenden Geschäftsmodelle, Kundenerwartungen und Organisationsstrukturen dies verhindern.

Diese Unternehmen entwickelten ihre Produkte rund um Übersetzungsspeicher, pro-Wort-Preisgestaltung und Workflows menschlicher Übersetzer. Ihre Kunden haben mentale Modelle und Prozesse rund um diese Bausteine aufgebaut. Die Änderung des Fundaments bedeutet, Versprechen gegenüber bestehenden Kunden zu brechen, Teams neu auszubilden und Umsatzmodelle neu zu überdenken. Auch mit den besten Absichten und dem Kapital zu investieren ist die organisatorische Trägheit enorm.

Sie benötigen Innovationskapazität und die Unterstützung ihrer Belegschaft, um neue Ideen anzunehmen. Aber noch schwieriger ist es, ihre bestehenden Kunden mit an Bord zu nehmen. Und diese Kunden sind im alten Modell investiert.

Das ist die Chance, die wir sehen. Nicht trotz weniger Ressourcen, sondern gerade deswegen. Wir haben kein Altsystem zu schützen, keine Workflows zu bewahren, keine Kunden zu migrieren. Wir können alles von Grund auf entwerfen.

> \[\!NOTE\]
> Das Innovator-Dilemma geht nicht um Technologie. Es geht um Anreize. Etablierte Unternehmen optimieren für das, was ihre aktuellen Kunden wollen, was es fast unmöglich macht, etwas Grundsätzlich Anders zu verfolgen.

## KI im Zentrum, nicht am Rand

Die meisten Unternehmen übernehmen KI, indem sie sie lose an bestehende Prozesse anheften. Ein Chatbot hier, eine Vorschlagsmaschine dort. Wir gehen den anderen Weg: Wir gestalten das gesamte Unternehmen von Tag eins an KI-zentriert.

Das heißt, KI ist kein Feature des Produkts. Sie bestimmt, wie wir bauen, verkaufen, unterstützen und betreiben. Jeder Entscheidung beginnt mit einer Frage: kann ein Agent das?

Das Produkt selbst ist ein Agent, der in deinem Terminal lebt, deine Quelldateien liest, Übersetzungen generiert, deine CI-Checks durchführt und iteriert, bis die Ausgabe besteht. Das ist der Teil, den man sieht. Dahinter aber steuert die gleiche Philosophie das Unternehmen.

## Ein kleines Team, das alles andere an Agenten delegiert.

Wir halten das Team absichtlich klein und bleiben so lange dabei, solange es sinnvoll ist.

Es geht nicht um Kostenersparnis. Es geht darum, eine gesamte Kategorie von Arbeit zu eliminieren, die keinen Mehrwert für Nutzer liefert.

Je mehr Menschen du hinzufügst, desto mehr Koordination benötigst du. Du baust Vertrauenssysteme, Berechtigungsmodelle, Genehmigungsketten. Du löst Konflikte, richtest Prioritäten aus, planst Meetings. All das ist kreative Energie, die in die Aufrechterhaltung einer menschlichen Organisation investiert wird, statt ein Produkt zu bauen.

Der Weg, wie wir das tun, besteht darin, alles andere an Agenten zu delegieren. Marketinganalyse, Synthese von Kundenfeedback, Wettbewerbsforschung, Entwurf von Inhalten, operatives Monitoring: die Routinearbeiten, die das Geschäft betreiben, werden zunehmend von Agenten übernommen, die wir gestalten, überprüfen und verbessern.

## Bewusste Technologieentscheidungen

Wir sind sehr bewusst bei unserem Tech-Stack, denn dies beeinflusst direkt, wie schnell wir weiterkommen können und wie sich die Software für die Teams verhält, die sie selbst hosten.

**Für den Agenten (CLI):** Wir haben Rust gewählt. Es kompiliert zu einzelnen, portablen Binärdateien für Plattformen ohne Laufzeitabhängigkeiten für den Benutzer.

**Für den Server:** Wir haben [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org) Laufzeit. Die funktionale Natur von Elixir macht es zu einer idealen Lösung für Agenten-Workloads. Die Erlang-VM ist für Parallelverarbeitung und Fehlertoleranz bewährt. Und hier ist ein Bonus: Ein KI-Agent kann das laufende Erlang-System analysieren, um zu verstehen, was passiert, Erkenntnisse sammeln und sogar Probleme in der Produktion beheben.

**ZUR VERTEILUNG:** Glossia ist Open Source unter der [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Teams, die es selbst betreiben wollen, können das Helm-Chart im Repository auf jedem Kubernetes-Cluster installieren. Dieselbe Codebasis treibt den gehosteten Dienst bei glossia.ai und jede selbst gehostete Bereitstellung.

> \[\!WICHTIG\]
> Wir lassen uns bewusst technische Komplexität vermeiden, die Ingenieure oft zu früh anstreben, wenn sie nicht verdient ist. Jede Abhängigkeit und jede Infrastrukturebene muss ihr Gewicht rechtfertigen.

## Was dies ermöglicht

Die Führung des Unternehmens auf diese Weise ist nicht nur eine Effizienz-Strategie. Sie verändert, was wir bieten können, und wie schnell wir lernen können.

**Für mehr Teams zugänglich.** Die Lokalisierungsbranche hat ihre Tools durch komplexe Preisgestaltung, Pro-Wort-Gebühren und Unternehmensvertriebszyklen unzugänglich gemacht. Wenn Ihr Übersetzungsablauf Beschaffung, Preisverhandlungen und einen Projektmanager erfordert, veröffentlichen die meisten kleinen Teams lediglich auf Englisch. Indem wir eine effiziente Organisation aufbauen und die Software als Open Source veröffentlichen, damit Teams selbst hosten können, können wir Glossia wirklich zugänglich machen.

**Schnellere Innovation.** Wir wollen viele Ideen erkunden. Neue Schnittstellen für den Agenten, bessere Feedback-Schleifen, neue Wege, Linguisten in den Workflow einzubinden. Ein traditionelles Unternehmen müsste Personal aufstocken, Teams ausrichten und Roadmap-Reviews planen. Wir probieren einfach Dinge aus. Der Abstand zwischen einer Idee und einem umgesetzten Experiment wird in Stunden, nicht in Quartalen gemessen.

## Herausforderung, wie wir arbeiten, nicht nur was wir bauen.

Wir sind nicht emotional an die alten Arbeitsweisen gebunden. Wir hinterfragen aktiv, was Code-Review bedeutet, wenn ein Agent den meisten Code schreibt. Wie die Zusammenarbeit funktioniert, wenn das menschliche Team klein ist und Agenten die Routineaufgaben erledigen. Wie man einen Fehler behebt, wenn der Agent das laufende System analysieren kann.

Wir machen Fehler. Wir werden weitere machen. Aber indem wir offen bleiben gegenüber dem Design und dem Betrieb des Unternehmens, entdecken wir weiterhin Ideen, die das Produkt beeinflussen. Unsere Arbeitsweise ist nicht getrennt von dem, was wir bauen. Sie sind dasselbe.

[McKinsey hat kürzlich beschrieben.](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) was sie "die agentische Organisation" nennen, ein neues Betriebsmodell, bei dem KI-Agenten gleichwertige Partner im Geschäftsbetrieb sind. Wir betrachten es nicht als Modell. Es ist einfach, wie wir arbeiten.

## Die Wette

Wir setzen darauf, dass ein kleines Team mit den richtigen Werkzeugen, der richtigen Einstellung und ohne organisatorischen Ballast Unternehmen mit Hunderten von Mitarbeitern und Millionen in der Finanzierung überholen kann. Nicht an jeder Front, sondern auf der, die zählt: ein grundlegend besseres Lokalisierungserlebnis zu liefern.

Die Branche kann sich nicht neu erfinden. Wir können.
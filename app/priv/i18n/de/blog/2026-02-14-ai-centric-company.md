%{
  title:
    "Ein KI-zentriertes Unternehmen aufzubauen, um eine Branche herauszufordern, die sich nicht neu erfinden kann.",
  summary:
    "Etablierte Lokalisierungsunternehmen verfügen zwar über Kapital, doch fehlt ihnen die Freiheit zur Innovation. Wir gestalten Glossia von Grund auf neu rund um KI und Agenten, nicht nur im Produkt, sondern auch in der Art, wie wir das gesamte Unternehmen betreiben.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten transformieren alles. Nicht nur, was Software kann, sondern wie Unternehmen aufgebaut sind, um diese Software zu entwickeln. Bei [Glossia](https://glossia.ai), sehen wir dies als einmalige Gelegenheit einer Generation, neu darüber nachzudenken, wie Inhalte in jede Sprache gelangen. Doch wir wissen auch, dass eine gute Produktidee allein nicht reicht. Man braucht eine Organisation, die schnell genug ist, um tatsächlich einen Unterschied zu machen.

Der zweite Teil ist genau das, worum es in diesem Beitrag geht.

## Das Innovator-Dilemma, das sich in Echtzeit vollzieht.

Die Lokalisierungsbranche ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise haben seit Jahren Tools und Dienstleistungen entwickelt. Sie verfügen über Kunden, Einnahmen, etablierte Arbeitsabläufe und Teams, die wissen, wie man ihre Produkte verkauft und unterstützt.

Doch warum würde ein kleines, fokussiertes Team das überhaupt versuchen?

Aufgrund von etwas, das Clayton Christensen in beschrieben hat [Das Innovatoren-Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): Etablierte Unternehmen haben Schwierigkeiten, sich disruptiven Innovationen anzupassen, nicht wegen Ressourcenmangels, sondern weil ihre bestehenden Geschäftsmodelle, Kundenerwartungen und Organisationsstrukturen dies verhindern.

Diese Unternehmen bauten ihre Produkte auf Übersetzungsspeicher, Pro-Wort-Preise und Arbeitsabläufe menschlicher Übersetzer auf. Ihre Kunden haben mentale Modelle und Prozesse um diese Bausteine herum entwickelt. Ein Wechsel des Fundaments bedeutet, Versprechen an bestehende Kunden zu brechen, Teams neu auszubilden und Umsatzmodelle neu zu denken. Auch mit den besten Intentionen und dem Kapital zur Investition ist die organisatorische Trägheit enorm.

Sie benötigen Innovationsfähigkeit und Engagement ihrer Belegschaft, um neue Ideen aufzugreifen, aber noch schwieriger ist es, ihre bestehenden Kunden für die Reise mitzunehmen, und diese Kunden sind in das alte Modell investiert.

Das ist die Chance, die wir sehen. Nicht trotz weniger Ressourcen, sondern gerade aufgrund dessen. Wir haben keine Legacy zu schützen, keine Workflows zu bewahren, keine Kunden zu migrieren. Wir können alles von Grund auf entwerfen.

> \[\!NOTE\]
> Das Innovatoren-Dilemma ist keine Frage der Technologie. Es geht um Anreize. Etablierte Unternehmen optimieren für das, was ihre aktuellen Kunden wollen, wodurch es fast unmöglich ist, etwas Grundsätzlich Unterschiedliches zu verfolgen.

## KI im Zentrum, nicht am Rand

Die meisten Unternehmen integrieren KI, indem sie sie an bestehende Prozesse anschrauben. Hier ein Chatbot, dort eine Empfehlungsmaschine. Wir gehen den anderen Weg: Das gesamte Unternehmen von Tag eins an KI-zentriert zu gestalten.

Das bedeutet, KI ist kein Feature des Produkts. Sie formt, wie wir bauen, verkaufen, unterstützen und betreiben. Jede Entscheidung, die wir treffen, beginnt mit einer Frage: Kann ein Agent das?

Das Produkt selbst ist ein Agent, der in Ihrem Terminal lebt, Ihre Quelldateien liest, Übersetzungen generiert, Ihre CI-Prüfungen ausführt und iteriert, bis der Output durchgeht. Das ist der Teil, den die Leute sehen. Doch dahinter prägt die gleiche Philosophie das Unternehmen.

## Ein kleines Team: Alles andere wird an Agenten delegiert.

Wir behalten das Team absichtlich klein und bleiben so lange dabei, wie es Sinn ergibt.

Es geht nicht um Kosteneinsparung. Es geht darum, eine ganze Kategorie von Arbeit zu eliminieren, die für Nutzer keinen Mehrwert bietet.

Je mehr Menschen Sie hinzufügen, desto mehr Abstimmung benötigen Sie. Sie bauen Vertrauenssysteme, Berechtigungsmodelle, Genehmigungsketten. Sie verwalten Konflikte, passen Prioritäten an, planen Meetings. Das ist alles kreative Energie, die in die Führung einer menschlichen Organisation fließt, statt in die Entwicklung eines Produkts.

Der Weg, wie wir das umsetzen, besteht darin, alles andere an Agenten zu delegieren. Marketing-Analysen, Synthese von Kunden-Feedback, Wettbewerbsforschung, Inhaltserstellung, operative Überwachung: Die Routineaufgaben des Betriebs werden zunehmend von Agenten erledigt, die wir formen, überprüfen und verbessern.

## Bewusste Technologieentscheidungen

Wir sind bei unserem Stack sehr bewusst, da dies direkt beeinflusst, wie schnell wir vorankommen können und wie sich die Software für die Teams verhält, die es selbst hosten.

**Für den Agenten (CLI):** Wir haben Rust gewählt. Es kompiliert zu einzelnen, portablen Binärdateien über Plattformen hinweg, ohne Laufzeitabhängigkeiten für den Benutzer.

**Für den Server:** Wir haben [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org) Laufzeit. Die funktionelle Natur von Elixir macht es zu einer hervorragenden Wahl für agentische Workloads. Die Erlang VM ist für Parallelität und Fehlertoleranz bewährt. Und hier ist ein Bonus: Ein KI-Agent kann das laufende Erlang-System selbstbeobachten, um zu verstehen, was geschieht, Einblicke zu sammeln und sogar Probleme in der Produktion zu beheben.

**Für die Verteilung:** Glossia ist Open Source unter der [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Teams, die es selbst betreiben möchten, können den Helm-Chart im Repository auf jedem Kubernetes-Cluster installieren. Der gleiche Code treibt den gehosten Service auf glossia.ai sowie jede selbst gehostete Bereitstellung an.

> \[\!WICHTIG\]
> Wir sind bewusst darauf bedacht, technische Komplexität zu vermeiden, auf die Ingenieure oft zugreifen, wenn sie nicht verdient ist. Jede Abhängigkeit und jede Infrastrukturschicht muss ihr Gewicht rechtfertigen.

## Was dies freischaltet

So das Unternehmen zu führen, ist nicht nur ein Effizienzvorteil. Es verändert, was wir anbieten können und wie schnell wir lernen können.

**Zugänglich für mehr Teams.** Die Lokalisierungsbranche hat ihre Werkzeuge durch komplexe Preisgestaltung, Pro-Wort-Gebühren und Enterprise-Vertriebszyklen unzugänglich gemacht. Wenn Ihr Übersetzungsablauf Beschaffung, Preisverhandlungen und einen Projektmanager erfordert, veröffentlichen die meisten kleinen Teams einfach auf Englisch. Durch den Aufbau einer effizienten Organisation und das Veröffentlichen der Software als Open Source, sodass Teams sie selbst hosten können, können wir Glossia wirklich zugänglich machen.

**Schnellere Innovation.** Wir möchten viele Ideen erkunden. Neue Schnittstellen für den Agenten, bessere Feedback-Loops, neue Wege, Linguisten in den Workflow einzubinden. Ein traditionelles Unternehmen müsste Personal anstellen, Teams ausrichten und Roadmap-Reviews planen. Wir probieren einfach Dinge. Der Abstand zwischen einer Idee und einem implementierten Experiment wird in Stunden, nicht in Quartalen gemessen.

## Wir hinterfragen nicht nur, was wir bauen, sondern wie wir arbeiten.

Wir sind nicht emotional an alte Methoden gebunden. Wir hinterfragen aktiv, was Code-Reviews bedeutet, wenn ein Agent den Großteil des Codes schreibt. Wie Zusammenarbeit funktioniert, wenn das menschliche Team klein ist und Agenten die Routineaufgaben übernehmen. Wie man einen Fehler behebt, wenn der Agent das laufende System inspizieren kann.

Wir machen Fehler. Wir werden sie weiterhin machen. Doch indem wir offen für die Gestaltung und den Betrieb unseres Unternehmens bleiben, entdecken wir weiterhin Ideen, die das Produkt beeinflussen. Unsere Arbeitsweise ist nicht davon zu trennen, was wir bauen. Sie sind dasselbe.

[McKinsey hat kürzlich beschrieben](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) das, was sie "die agentische Organisation" nennen, ist ein neues Betriebsmodell, in dem KI-Agenten zu gleichberechtigten Beteiligten im Unternehmensablauf werden. Wir betrachten es nicht als Modell. Es ist schlicht, wie wir arbeiten.

## Die Wette

Wir setzen darauf, dass ein kleines Team mit den richtigen Werkzeugen, der richtigen Einstellung und ohne organisatorischen Ballast Unternehmen mit Hunderten Mitarbeitern und Millionen in der Finanzierung überholen kann. Nicht auf jeder Front, sondern auf derjenigen, die zählt: die Lieferung eines grundlegend besseren Lokalisierungserlebnisses.

Die Branche kann sich nicht neu erfinden. Wir können.
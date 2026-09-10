%{
  title:
    "Ein KI-zentriertes Unternehmen aufbauen, um eine Industrie herauszufordern, die sich nicht neu erfinden kann.",
  summary:
    "Etablierte Lokalisierungsunternehmen haben zwar das Kapital, aber nicht die Freiheit zur Innovation. Wir gestalten Glossia von Grund auf neu rund um KI und Agenten, nicht nur im Produkt, sondern auch in der Art, wie wir das gesamte Unternehmen betreiben.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten transformieren alles. Nicht nur was Software kann, sondern wie Unternehmen aufgebaut sind, um diese Software zu erstellen. Bei [Glossia](https://glossia.ai), sehen wir dies als eine Chance, die in Generationen einzigartig ist, neu zu denken, wie Inhalte jede Sprache erreichen. Doch wir wissen auch, dass eine gute Produktidee nicht ausreicht. Sie benötigen eine Organisation, die schnell genug sein kann, um relevant zu sein.

Dieser zweite Teil ist das Thema dieses Beitrags.

## Das Innovatordilemma, in Echtzeit ablaufend.

Die Lokalisierungsbranche ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise erschaffen seit Jahren Tools und Dienstleistungen. Sie verfügen über Kunden, Umsatz, etablierte Workflows und Teams, die wissen, wie sie ihre Produkte verkaufen und unterstützen.

Also warum würde ein kleines, fokussiertes Team es überhaupt versuchen?

Weil Clayton Christensen es in beschrieben hat. [Das Innovator's Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): etablierte Unternehmen kämpfen, disruptive Innovationen zu übernehmen, nicht weil sie Ressourcen fehlen, sondern weil ihre Geschäftsmodelle, Kundenanforderungen und Organisationsstrukturen sie daran hindern.

Diese Unternehmen bauten ihre Produkte auf translation Memories, stückpreis Pricing und menschlichen Übersetzungsabläufen auf. Ihre Kunden haben mentale Modelle und Prozesse um diese Bausteine herum entwickelt. Eine Veränderung des Fundaments heißt, Versprechen an bestehende Kunden zu brechen, Teams neu zu schulen und Umsatzmodelle zu überdenken. Selbst mit den besten Absichten und dem nötigen Kapital ist die organisationale Trägheit enorm.

Sie brauchen Innovationskapazität und Engagement ihrer Belegschaft, um neue Ideen zu übernehmen. Aber noch schwieriger: Sie müssen ihre bestehenden Kunden mitnehmen. Und diese Kunden sind im alten Modell investiert.

Das ist die Öffnung, die wir sehen. Nicht trotz weniger Ressourcen, sondern wegen ihrer. Wir haben keine Legacy zu schützen, keine Arbeitsabläufe zu bewahren, keine Kunden zu migrieren. Wir können alles von Grund auf entwerfen.

> \[\!NOTE\]
> Die Innovator's Dilemma ist nicht über Technologie. Es geht über Anreize. Etablierte Unternehmen optimieren für das, was ihre aktuellen Kunden wollen, was es fast unmöglich macht, etwas Fundament anders nachzugehen.

## AI im Zentrum, nicht an den Rändern

Die meisten Unternehmen integrieren KI, indem sie sie auf bestehende Prozesse einfach aufsetzen. Ein Chatbot hier, ein Vorschlagsmotor dort. Wir gehen den anderen Weg: Wir gestalten das gesamte Unternehmen von Tag eins an so, dass es KI-zentriert ist.

Das bedeutet, dass KI keine Funktion des Produkts ist. Sie prägt, wie wir entwickeln, verkaufen, unterstützen und betreiben. Jede Entscheidung beginnt mit einer Frage: Kann ein Agent das tun?

Das Produkt selbst ist ein Agent, der in deinem Terminal lebt, deine Quelldateien liest, Übersetzungen generiert, deine CI-Checks ausführt und iteriert, bis der Output bestanden ist. Das ist der Teil, den die Leute sehen. Aber dahinter leitet die gleiche Philosophie das Unternehmen.

## Ein kleines Team, das alles andere an Agenten delegiert

Wir halten das Team bewusst klein und bleiben das so lange, wie es sinnvoll ist.

Es geht nicht um Kostensenkung. Es geht darum, eine ganze Kategorie von Arbeit zu eliminieren, die keinen Nutzen für Benutzer bringt.

Je mehr Menschen du hinzufügst, desto mehr Abstimmung benötigst du. Du baust Vertrauenssysteme, Berechtigungsmodelle, Genehmigungsketten. Du verwaltest Konflikte, richtest Prioritäten aus, planst Meetings. All das ist kreative Energie, die in die Aufrechterhaltung einer menschlichen Organisation fließt, statt ein Produkt zu bauen.

Die Art und Weise, wie wir das funktionieren lassen, besteht darin, alles andere an Agenten zu delegieren. Marketing-Analysen, Synthese von Kundenrückmeldungen, Wettbewerbsforschung, Content-Entwürfe, Operations-Monitoring: die routinemäßige Arbeit des Geschäftsbetriebs wird zunehmend von Agenten übernommen, die wir gestalten, überprüfen und verbessern.

## Bewusste Technologieentscheidungen

Wir sind sehr bewusst mit unserem Tech-Stack, da er direkt beeinflusst, wie schnell wir vorankommen können und wie sich die Software für die Teams verhält, die ihn selbst hosten.

**Für den Agenten (CLI):** Wir haben uns für Rust entschieden. Es kompiliert zu einzelnen, portablen Binärdateien über alle Plattformen hinweg, ohne Laufzeitabhängigkeiten für den Benutzer.

**Für den Server:** Wir haben uns für [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org) Laufzeit. Die funktionale Natur von Elixir macht es hervorragend geeignet für agentenbasierte Workloads. Die Erlang VM ist für Parallelverarbeitung und Fehlertoleranz bewährt. Und hier ist noch ein Bonus: Ein KI-Agent kann das laufende Erlang-System analysieren, um zu verstehen, was passiert, Erkenntnisse sammeln und sogar Probleme in der Produktion beheben.

**Für die Verteilung:** Glossia ist Open Source unter der [O'Saasy Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md). Teams, die es selbst betreiben, können den Helm-Chart im Repository auf jedem Kubernetes-Cluster installieren. Der gleiche Code steuert auch den gehosteten Dienst bei glossia.ai und jede selbst gehostete Bereitstellung an.

> \[\!WICHTIG\]
> Wir verzichten bewusst auf technische Komplexität, die Ingenieure oft früh anstreben, bevor sie sich lohnt. Jede Abhängigkeit und jede Infrastrukturebene muss ihr Gewicht rechtfertigen.

## Was dies ermöglicht

Der Betrieb des Unternehmens auf diese Weise ist nicht nur ein Effizienz-Vorteil. Er verändert, was wir anbieten können und wie schnell wir lernen.

**Zugänglich für mehr Teams.** Die Lokalisierungsbranche hat ihre Werkzeuge durch komplexe Preisgestaltung, Pro-Wort-Gebühren und Unternehmensverkaufszyklen unzugänglich gemacht. Wenn Ihr Übersetzungsworkflow Beschaffung, Preisverhandlungen und einen Projektmanager erfordert, veröffentlichen die meisten kleinen Teams einfach nur auf Englisch. Indem wir eine effiziente Organisation aufbauen und die Software als Open Source bereitstellen, damit Teams sie selbst hosten können, machen wir Glossia wirklich zugänglich.

**Schnellere Innovation.** Wir wollen viele Ideen erkunden. Neue Schnittstellen für den Agenten, bessere Feedback-Schleifen, neue Wege, Linguisten in den Workflow zu integrieren. Ein traditionelles Unternehmen müsste Personal aufbauen, Teams ausrichten und Roadmap-Reviews planen. Wir probieren einfach nur Dinge aus. Der Abstand zwischen einer Idee und einem implementierten Experiment wird in Stunden, nicht in Quartalen gemessen.

## Infrage stellen, wie wir arbeiten, nicht nur, was wir bauen.

Wir sind nicht emotional an den alten Weg gebunden. Wir hinterfragen aktiv, was Code-Review bedeutet, wenn ein Agent den Großteil des Codes schreibt. Wie Zusammenarbeit funktioniert, wenn das menschliche Team klein ist und Agenten die Routinearbeit erledigen. Wie Sie einen Fehler beheben, wenn der Agent das laufende System inspizieren kann.

Wir machen Fehler. Wir werden sie weiterhin machen. Doch indem wir offen bleiben, wie wir das Unternehmen gestalten und betreiben, entdecken wir weiterhin Ideen, die das Produkt beeinflussen. Die Art und Weise, wie wir operieren, ist nicht getrennt von dem, was wir bauen. Sie sind das Gleiche.

[McKinsey hat kürzlich beschrieben](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) was sie "die agentische Organisation" nennen, ein neues Betriebsmodell, bei dem KI-Agenten als gleichwertige Teilnehmer in die Funktionsweise eines Unternehmens integriert sind. Wir betrachten es nicht als Modell. Es ist einfach so, wie wir arbeiten.

## Die Wette

Wir setzen darauf, dass ein kleines Team mit den richtigen Werkzeugen, der richtigen Einstellung und ohne organisatorischen Ballast Unternehmen mit hunderten Mitarbeitern und Millionen an Finanzierung übertreffen kann. Nicht an jeder Front, sondern auf dem, was zählt: ein grundlegend besseres Lokalisierungserlebnis zu liefern.

Die Branche kann sich nicht neu erfinden. Wir können.
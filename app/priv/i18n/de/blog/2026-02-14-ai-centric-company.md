%{
  title:
    "Aufbau eines KI-zentrierten Unternehmens, um eine Branche herauszufordern, die sich selbst nicht neu erfinden kann.",
  summary:
    "Etablierte Lokalisierungsunternehmen verfügen zwar über das Kapital, nicht jedoch über die Freiheit, zu innovieren. Wir bauen Glossia von Grund auf neu rund um KI und Agenten, nicht nur im Produkt, sondern auch in der Art, wie wir das gesamte Unternehmen betreiben.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten verändern alles. Nicht nur, was Software kann, sondern auch, wie Unternehmen aufgebaut sind, um diese Software zu erstellen. Bei [Glossia](https://glossia.ai), sehen wir dies als eine einmalige Chance einer Generation, neu zu überdenken, wie Inhalte jede Sprache erreichen. Aber wir wissen auch, dass eine gute Produktidee nicht ausreicht. Du brauchst eine Organisation, die schnell genug ist, um relevant zu sein.

Genau daran geht es in diesem Beitrag.

## Das Innovatoren-Dilemma, das sich in Echtzeit abspielt.

Die Lokalisierungsbranche ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise haben seit Jahren Werkzeuge und Dienstleistungen entwickelt. Sie verfügen über Kunden, Umsatz, etablierte Arbeitsabläufe und Teams, die wissen, wie sie ihre Produkte verkaufen und betreuen.

Also warum sollte sich ein kleines, fokussiertes Team überhaupt versuchen?

Weil Clayton Christensen es beschrieben hat in [Das Innovators-Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): etablierte Unternehmen kommen bei disruptiven Innovationen vor所说 nicht, weil sie Ressourcen fehlen, sondern weil ihre bestehenden Geschäftsmodelle, Kundenerwartungen und Organisationsstrukturen dies verhindern.

These companies built their products around translation memories, per-word pricing, and human translator workflows. Their customers have built mental models and processes around those building blocks. Changing the foundation means breaking promises to existing clients, retraining teams, and rethinking revenue models. Even with the best intentions and the capital to invest, the organizational inertia is enormous.

They need innovation capacity and commitment from their workforce to embrace new ideas. But even harder than that, they need their existing customers to come along for the ride. And those customers are invested in the old model.

This is the opening we see. Not despite having fewer resources, but because of it. We have no legacy to protect, no workflows to preserve, no clients to migrate. We can design everything from scratch.

> \[\!NOTE\]
> The innovator's dilemma is not about technology. It is about incentives. Established companies optimize for what their current customers want, which makes it nearly impossible to pursue something fundamentally different.

## \[AI at the center, not at the edges\]

Die meisten Unternehmen integrieren KI, indem sie sie auf bestehende Prozesse aufschrauben. Hier ein Chatbot, da ein Vorschlagsmotor. Wir gehen den anderen Weg: Wir gestalten das gesamte Unternehmen von Tag eins an zentriert auf KI.

Das bedeutet, dass KI kein Feature des Produkts ist. Sie prägt, wie wir entwickeln, verkaufen, betreuen und betreiben. Jede Entscheidung, die wir treffen, beginnt mit der Frage: Kann ein Agent das?

Das Produkt selbst ist ein Agent, der in deinem Terminal lebt, deine Quelldateien liest, Übersetzungen generiert, deine CI-Checks ausführt und iteriert, bis die Ausgabe die Prüfung besteht. Das ist der Teil, den die Leute sehen. Aber dahinter läuft dieselbe Philosophie, die das Geschäft steuert.

## Ein kleines Team, das alles andere an Agenten delegiert.

Wir halten das Team bewusst klein und bleiben das so lange, wie es Sinn ergibt.

Dies ist nicht um Kosteneinsparung. Es geht um die Eliminierung einer gesamten Kategorie von Arbeit, die keinen Wert für Nutzer hervorbringt.

Je mehr Menschen Sie hinzufügen, desto mehr Koordination benötigen Sie. Sie erstellen Vertrauenssysteme, Berechtigungsmodelle und Genehmigungsketten. Sie bewältigen Konflikte, harmonisieren Prioritäten und planen Treffen. All das ist kreative Energie, die in die Aufrechterhaltung einer menschlichen Organisation statt in die Entwicklung eines Produkts fließt.

So machen wir dies funktionieren, indem wir alles andere an Agenten delegieren. Marktanalyse, Synthese von Kundenfeedback, Wettbewerbsforschung, Inhaltserstellung und operatives Monitoring: Die Routinearbeit des Betriebs wird zunehmend von Agenten übernommen, die wir gestalten, überprüfen und verbessern.

## Bewusste Technologieentscheidungen

Wir sind bei unserem Tech-Stack sehr bewusst, da er direkt beeinflusst, wie schnell wir vorankommen können und wie sich die Software für Teams verhält, die ihn selbst hosten.

**Für den Agenten (CLI):** Wir haben Rust gewählt. Es compiliert zu einzelnen, portablen Binärdateien plattformübergreifend ohne Laufzeitabhängigkeiten für den Benutzer.

**Für den Server:** Wir haben [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org) Laufzeit. Die funktionale Natur von Elixir macht es zu einer hervorragenden Wahl für Agenten-Workloads. Die Erlang-VM ist für Parallelverarbeitung und Fehlertoleranz bewährt. Und hier ist ein Bonus: Ein KI-Agent kann das laufende Erlang-System introspektieren, um zu verstehen, was passiert, Einsichten zu sammeln und Probleme in der Produktion zu lösen.

**Für die Verteilung:** Glossia ist Open Source unter der [O'Saasy Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md). Teams, die es selbst betreiben möchten, können den Helm-Chart im Repository auf jedem beliebigen Kubernetes-Cluster installieren. Der gleiche Code steuert den gehosteten Dienst bei glossia.ai sowie jede selbstgehostete Bereitstellung.

> \[\!WICHTIG\]
> Wir sind bewusst dabei, technische Komplexität zu überspringen, die Ingenieure tendieren, sich früh anzueignen, wenn sie nicht verdient sind. Jede Abhängigkeit und jede Infrastrukturschicht muss ihr Gewicht rechtfertigen.

## Was dies ermöglicht

Das Unternehmen so zu führen, ist nicht nur ein Effizienz-Aspekt. Es verändert, was wir anbieten und wie schnell wir lernen können.

**Zugänglich für mehr Teams.** Die Lokalisierungsbranche hat ihre Tools durch komplexe Preisgestaltung, Gebühren pro Wort und Enterprise-Vertriebszyklen unzugänglich gemacht. Wenn Ihre Übersetzungsprozesse Beschaffung, Preisverhandlungen und einen Projektmanager erfordern, veröffentlichen die meisten kleinen Teams einfach auf Englisch. Indem wir eine effiziente Organisation aufbauen und die Software als Open Source bereitstellen, damit Teams selbst hosten können, machen wir Glossia wirklich zugänglich.

**Schnellere Innovation.** Wir wollen viele Ideen erkunden. Neue Schnittstellen für den Agenten, bessere Feedback-Loops, neue Wege, um Linguisten in den Workflow zu integrieren. Ein traditionelles Unternehmen müsste Personal rekrutieren, Teams ausrichten und Roadmap-Reviews planen. Wir probieren einfach Dinge aus. Die Distanz zwischen einer Idee und einem implementierten Experiment wird in Stunden, nicht in Quartalen gemessen.

## Wir hinterfragen, wie wir arbeiten, nicht nur, was wir bauen.

Wir sind nicht emotional an die alten Arbeitweisen gebunden. Wir hinterfragen aktiv, was Code-Review bedeutet, wenn ein Agent den Großteil des Codes schreibt. Wie die Zusammenarbeit funktioniert, wenn das menschliche Team klein ist und Agenten die Routineaufgaben übernehmen. Wie Sie einen Fehler beheben, wenn der Agent das laufende System inspizieren kann.

Wir machen Fehler. Wir werden sie weiterhin machen. Doch indem wir offen bleiben, wie wir das Unternehmen gestalten und leiten, entdecken wir weiterhin Ideen, die das Produkt beeinflussen. Unsere Arbeitsweise ist nicht getrennt von dem, was wir bauen. Es ist eine und dieselbe Sache.

[McKinsey hat kürzlich beschrieben](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) das, was sie "die agentische Organisation," nennen, ein neues Betriebsmodell, bei dem KI-Agenten Teilnehmer erster Klasse im Betrieb eines Unternehmens sind. Wir betrachten es nicht als ein Modell. Es ist einfach so, wie wir arbeiten.

## Das Wagnis

Wir setzen darauf, dass ein kleines Team mit den richtigen Werkzeugen, der richtigen Denkweise und ohne organisatorisches Gepäck Unternehmen mit Hunderten von Mitarbeitern und Millionen an Finanzierung übertreffen kann. Nicht auf allen Fronten, sondern auf der einen, die zählt: die Lieferung einer grundlegend besseren Lokalisierungserfahrung.

Die Branche kann sich nicht selbst erfinden. Wir können.
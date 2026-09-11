%{
  title:
    "Aufbau eines KI-zentrierten Unternehmens, um eine Industrie herauszufordern, die sich selbst nicht neu erfinden kann.",
  summary:
    "Etablierte Lokalisierungsfirmen verfügen zwar über Kapital, besitzen jedoch nicht die Freiheit zur Innovation. Wir gestalten Glossia von Grund auf neu rund um KI und Agenten, nicht nur im Produkt, sondern auch in der Art und Weise, wie wir das gesamte Unternehmen betreiben.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten verändern alles. Nicht nur, was Software kann, sondern wie Unternehmen aufgebaut werden, um diese Software zu erstellen. Bei [Glossia](https://glossia.ai), sehen wir das als eine einmalige Chance in einer Generation, neu zu denken, wie Inhalte jede Sprache erreichen. Doch wir wissen auch, dass eine gute Produktidee nicht ausreicht. Man braucht eine Organisation, die schnell genug ist, um relevant zu sein.

Genau dieser zweite Teil ist das Thema dieses Beitrags.

## Das Innovatoren-Dilemma, das in Echtzeit abspielt

Die Lokalisierungsbranche ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise entwickeln seit Jahren Tools und Dienstleistungen. Sie haben Kunden, Umsatz, etablierte Workflows und Teams, die wissen, wie sie ihre Produkte verkaufen und unterstützen.

Also warum würde ein kleines, fokussiertes Team es überhaupt versuchen?

Weil Clayton Christensen das in [Das Innovatoren-Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): Etablierte Unternehmen haben Schwierigkeiten, disruptive Innovationen anzunehmen, nicht wegen fehlender Ressourcen, sondern weil ihre bestehenden Geschäftsmodelle, Kundenbedürfnisse und Organisationsstrukturen dies verhindern.

Diese Unternehmen haben ihre Produkte um Übersetzungsspeicher, Wortweise Abrechnung und Workflows menschlicher Übersetzer herum konstruiert. Ihre Kunden haben mentale Modelle und Prozesse um diese Grundbausteine herum entwickelt. Eine Veränderung der Fundamente bedeutet, Verpflichtungen gegenüber bestehenden Kunden zu brechen, Teams neu auszubilden und Umsatzmodelle neu zu denken. Selbst bei den besten Absichten und dem verfügbaren Kapital ist die organisatorische Trägheit enorm.

Sie benötigen die Innovationsfähigkeit und das Engagement ihrer Belegschaft, um neue Ideen aufzunehmen. Aber noch schwieriger ist es, dass sie ihre bestehenden Kunden dabei haben wollen. Und diese Kunden sind im alten Modell investiert.

Das ist die Chance, die wir sehen. Nicht trotz begrenzterer Ressourcen, sondern eben wegen dessen. Wir haben kein altes Erbe zu beschützen, keine Workflows zu erhalten, keine Kunden, die migriert werden müssen. Wir können alles von Grund auf neu gestalten.

> \[\!NOTE\]
> Das Innovatoren-Dilemma ist nicht über Technologie. Es geht um Anreize. Etablierte Unternehmen optimieren für das, was ihre aktuellen Kunden wollen, was es nahezu unmöglich macht, etwas fundamentally Differenz zu verfolgen.

## KI im Zentrum, nicht an den Rändern.

Die meisten Unternehmen adoptieren KI, indem sie sie an bestehende Prozesse anfügen – hier ein Chatbot, dort ein Vorschlagsmotor. Wir gehen den anderen Weg: Wir gestalten das gesamte Unternehmen von Tag eins an zentriert auf KI.

Das bedeutet, KI ist keine Funktion des Produkts. Sie formt, wie wir entwickeln, verkaufen, unterstützen und operieren. Jede Entscheidung beginnt mit der Frage: Kann ein Agent das?

Das Produkt selbst ist ein Agent, der in deinem Terminal lebt, deine Quelldateien liest, Übersetzungen generiert, CI-Checks durchführt und iteriert, bis der Output erfolgreich ist. Das ist der Teil, den Nutzer sehen. Doch dahinter führt dieselbe Philosophie das Geschäft.

## Ein kleines Team, das alles andere an Agenten delegiert.

Wir halten das Team absichtsvoll klein und bleiben es so lange wie es Sinn ergibt.

Es geht nicht um Kostensenkung. Es geht darum, eine ganze Kategorie von Arbeit zu eliminieren, die keinen Wert für Nutzer schafft.

Je mehr Mitarbeiter Sie hinzufügen, desto mehr Koordination benötigen Sie. Sie bauen Vertrauenssysteme, Berechtigungsmodelle, Genehmigungsreihen. Sie verwalten Konflikte, richten Prioritäten aus, planen Treffen. Das alles ist kreative Energie, die in die Pflege einer menschlichen Organisation fließt, statt ein Produkt zu bauen.

Der Ansatz, dies zu realisieren, besteht darin, alles andere an Agenten zu delegieren. Marketinganalyse, Kundenfeedback-Synthese, Wettbewerbsforschung, Content-Entwurf, Operationsmonitoring: Die Routinearbeit des Geschäfts wird zunehmend von Agenten übernommen, die wir formen, überprüfen und verbessern.

## Bewusste Technologieentscheidungen

Wir sind sehr bewusst mit unserem Tech-Stack, da er direkt beeinflusst, wie schnell wir vorankommen und wie sich die Software für die Teams verhält, die es selbst hosten.

**Für den Agenten (CLI):** Wir haben Rust gewählt. Es compiliert zu einzelnen, portablen Binärdateien über Plattformen hinweg ohne Laufzeitabhängigkeiten für den Benutzer.

**Für den Server:** Wir haben gewählt [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org) Laufzeit. Die funktionale Natur von Elixir macht es zu einer hervorragenden Wahl für Arbeitslasten durch Agenten. Die Erlang VM ist in der Praxis erprobt für Parallelverarbeitung und Fehlertoleranz. Und hier ist ein Bonus: Ein KI-Agent kann das laufende Erlang-System analysieren, um zu verstehen, was gerade passiert, Einblicke zu gewinnen und sogar Probleme in der Produktion zu beheben.

**Für die Verteilung:** Glossia ist Open Source unter der [O'Saasy-Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md). Teams, die es selbst betreiben möchten, können das Helm-Chart im Repository auf jedem Kubernetes-Cluster installieren. Der gleiche Code betreibt den gehosteten Dienst bei glossia.ai sowie jede selbst gehostete Bereitstellung.

> \[\!WICHTIG\]
> Wir sind bewusst darauf bedacht, technische Komplexität zu vermeiden, die Ingenieure zu früh in Anspruch nehmen, bevor sie gerechtfertigt ist. Jede Abhängigkeit und jede Infrastrukturschicht muss ihr Gewicht rechtfertigen.

## Was dies ermöglicht

Unser Unternehmen auf diese Weise zu betreiben ist nicht nur ein Effizienzgewinn. Es verändert, was wir bieten können, und wie schnell wir lernen.

**Zugänglich für mehr Teams.** Die Lokalisierungsbranche hat ihre Tools durch komplexe Preisgestaltung, Gebühren pro Wort und Unternehmensvertriebszyklen unzugänglich gemacht. Indem wir eine effiziente Organisation aufbauen und die Software Open Source bereitstellen, damit Teams sie selbst hosten können, können wir Glossia wirklich zugänglich machen.

**Schnellere Innovation.** Wir wollen viele Ideen erforschen. Neue Schnittstellen für den Agenten, bessere Feedback-Schleifen, neue Wege, Linguisten in den Workflow zu bringen. Ein traditionelles Unternehmen müsste Personal aufstellen, Teams ausrichten und Roadmap-Reviews planen. Wir probieren einfach Dinge aus. Der Abstand zwischen einer Idee und einem bereitgestellten Experiment wird in Stunden gemessen, nicht in Quartalen.

## Das Hinterfragen, wie wir arbeiten, nicht nur das, was wir bauen

Wir sind nicht emotional an alte Vorgehensweisen gebunden. Wir hinterfragen aktiv, was Code-Reviews bedeutet, wenn ein Agent den meisten Code schreibt. Wie Kollaboration funktioniert, wenn das menschliche Team klein ist und Agenten die Routinearbeit übernehmen. Wie man einen Bug behebt, wenn der Agent das laufende System inspizieren kann.

Wir machen Fehler. Wir werden sie weiterhin machen. Aber indem wir offenbleiben, wie wir das Geschäft konzipieren und betreiben, entdecken wir weiterhin Ideen, die das Produkt beeinflussen. Unsere Art zu arbeiten ist nicht getrennt von dem, was wir bauen. Es ist dasselbe.

[McKinsey hat kürzlich beschrieben](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) was sie „die agentische Organisation“ nennen, ein neues Betriebsmodell, bei dem KI-Agenten zu gleichberechtigten Akteuren beim Unternehmensbetrieb werden. Wir betrachten es nicht als Modell. Es ist so, wie wir arbeiten.

## Die Wette

Wir setzen darauf, dass ein kleines Team mit den richtigen Werkzeugen, der richtigen Denkweise und ohne organisatorischen Ballast Unternehmen mit Hunderten von Mitarbeitern und Millionen an Finanzierung überholen kann. Nicht auf allen Fronten, sondern dort, wo es zählt: die Lieferung eines grundlegend besseren Lokalisierungserlebnisses.

Die Branche kann sich nicht neu erfinden. Wir schon.
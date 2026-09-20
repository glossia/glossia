%{
  title:
    "Ein KI-zentriertes Unternehmen aufzubauen, um eine Branche herauszufordern, die sich selbst nicht neu erfinden kann.",
  summary:
    "Etablierte Lokalisierungsunternehmen verfügen zwar über Kapital, aber nicht über die Freiheit zu innovieren. Wir entwickeln Glossia von Grund auf rund um KI und Agenten, nicht nur im Produkt, sondern auch in der Art und Weise, wie wir das gesamte Unternehmen betreiben.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten transformieren alles. Nicht nur, was Software leisten kann, sondern wie Unternehmen aufgebaut sind, um diese Software zu entwickeln. Bei [Glossia](https://glossia.ai), sehen wir dies als eine einmalige Chance einer Generation, um zu überdenken, wie Inhalte jede Sprache erreichen. Doch wir wissen auch, dass eine gute Produktidee nicht reicht. Sie benötigen eine Organisation, die schnell genug ist, um wirklich zu zählen.

Genau darum geht es in diesem Beitrag.

## Das Innovator-Dilemma, das sich in Echtzeit abspielt

Die Lokalisierungsbranche ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise bauen seit Jahren Tools und Dienste auf. Sie verfügen über Kunden, Einnahmen, etablierte Workflows und Teams, die wissen, wie sie ihre Produkte verkaufen und unterstützen.

Wieso sollte also ein kleines, fokussiertes Team das überhaupt versuchen?

Dies liegt an etwas, das Clayton Christensen in [Das Innovatoren-Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): etablierte Unternehmen haben Schwierigkeiten, disruptive Innovationen zu übernehmen, nicht weil sie Ressourcen vermissen, sondern weil ihre bestehenden Geschäftsmodelle, Kundenerwartungen und Organisationsstrukturen ihnen dies unmöglich machen.

Diese Unternehmen entwickelten ihre Produkte um Übersetzungsspeicher, pro-Wort-Preissysteme und menschliche Übersetzungs-Workflows. Ihre Kunden haben mentale Modelle und Prozesse um diese Bausteine herum entwickelt. Das Fundament zu ändern bedeutet, Versprechen gegenüber bestehenden Kunden zu brechen, Teams wieder einzuschulen und Umsatzmodelle zu überdenken. Selbst mit den besten Absichten und dem Kapital für Investitionen ist die organisatorische Trägheit enorm.

Sie benötigen Innovationsfähigkeit und das Engagement ihrer Belegschaft, um neue Ideen zu übernehmen. Aber noch schwieriger ist es, ihre bestehenden Kunden mit an Bord zu holen. Und diese Kunden stehen in dem alten Modell fest.

Das ist die Gelegenheit, die wir sehen. Nicht trotz geringerer Ressourcen, sondern gerade wegen ihrer geringen Anzahl. Wir haben kein Erbe zu schützen, keine Workflows zu bewahren, keine Kunden zu migrieren. Wir können alles von Grund auf neu gestalten.

> \[\!HINWEIS\]
> Das Innovatoren-Dilemma dreht sich nicht um Technologie. Es geht um Anreize. Etablierte Unternehmen optimieren darauf, was ihre aktuellen Kunden wollen, was es beinahe unmöglich macht, etwas grundlegend anderes zu verfolgen.

## KI im Zentrum, nicht am Rand.

Die meisten Unternehmen nutzen KI, indem sie sie auf bestehende Prozesse andocken. Ein Chatbot hier, ein Vorschlagsmotor dort. Wir gehen den anderen Weg: Wir entwerfen das gesamte Unternehmen von Tag eins als KI-zentriert.

Das heißt, KI ist kein Feature des Produkts. Sie prägt, wie wir bauen, verkaufen, unterstützen und operieren. Jede Entscheidung, die wir treffen, beginnt mit einer Frage: Kann ein Agent das?

Das Produkt selbst ist ein Agent, der in deinem Terminal lebt, deine Quelldateien liest, Übersetzungen generiert, deine CI-Checks durchführt und iteriert, bis die Ausgabe erfolgreich ist. Das ist der Teil, den Menschen sehen. Doch dahinter wird das Unternehmen von der gleichen Philosophie gesteuert.

## Ein kleines Team, das alles andere an Agenten delegiert

Wir halten das Team bewusst klein und bleiben das so lange, wie es sinnvoll ist.

Es geht nicht darum, Kosten zu sparen. Es geht darum, eine gesamte Kategorie an Arbeit zu eliminieren, die keinen Wert für Nutzer erzeugt.

Je mehr Menschen hinzukommen, desto mehr Koordination benötigst du. Du richtest Vertrauenssysteme, Berechtigungsmodelle und Genehmigungsketten ein. Du löst Konflikte, ausrichtest Prioritäten, planst Besprechungen. All das ist kreative Energie, die in die Aufrechterhaltung einer menschlichen Organisation statt in die Entwicklung eines Produkts fließt.

Der Weg, wie wir das umsetzen, lautet: Alles andere wird an Agenten delegiert. Marketinganalyse, Synthese von Kundenfeedback, Wettbewerbsforschung, Content-Entwurf, Überwachung des Betriebs: die Routinearbeit des Unternehmensbetriebs wird zunehmend von Agenten erledigt, die wir gestalten, prüfen und verbessern.

## Bewusste Technologieentscheidungen

Wir gehen bei unserem Tech-Stack sehr bewusst vor, da dies direkt beeinflusst, wie schnell wir vorankommen können und wie sich die Software für die Teams verhält, die es selbst hosten.

**Für den Agenten (CLI):** Wir haben Rust gewählt. Es compiliert zu einzelnen, portablen Binärdateien über Plattformen hinweg, ohne Laufzeitabhängigkeiten für den Benutzer.

**Für den Server:** Wir haben [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org) Laufzeit. Die funktionale Natur von Elixir macht es zu einer hervorragenden Wahl für Agenten-Workloads. Die Erlang-VM ist für Parallelverarbeitung und Fehlertoleranz bewährt. Und hier ist ein Bonus: ein KI-Agent kann das laufende Erlang-System introspektieren, verstehen, was passiert, Einsichten gewinnen und sogar Probleme in der Produktion beheben.

**Für die Verteilung:** Glossia läuft als gehosteter Dienst bei [glossia.ai](https://glossia.ai). Ein Codepfad, ein Deployment, ein einheitliches Konzept — keine Trennung zwischen einer On-Premise-Build und einer gehosteten Build, keine pro-Mandant-Infrastruktur zu koordinieren.

> \[\!WICHTIG\]
> Wir übergehen absichtlich technische Komplexität, auf die Ingenieure oft zu früh zugreifen, solange sie sich nicht gelohnt hat.

## Was dies ermöglicht

So das Unternehmen zu führen, ist nicht nur ein Effizienzgewinn. Es verändert, was wir bieten können und wie schnell wir lernen.

**Zugänglich für mehr Teams.** Die Lokalisierungsbranche hat ihre Tools durch komplexe Preisgestaltung, pro-Wort-Gebühren und Verkaufszyklen für Großunternehmen unzugänglich gemacht. Wenn Ihr Übersetzungsablauf die Beschaffung, Preisverhandlungen und einen Projektmanager erfordert, liefern die meisten kleinen Teams einfach auf Englisch aus. Indem wir eine effiziente Organisation aufbauen, können wir Glossia so preisen, dass das Veröffentlichen in einer zweiten Sprache eine Entscheidung ist, die jeder im Team treffen kann, kein Beschaffungsprojekt.

**Schnellere Innovation.** Wir wollen viele Ideen erkunden. Neue Schnittstellen für den Agenten, bessere Feedback-Schleifen, neue Wege, um Linguisten in den Workflow zu integrieren. Ein traditionelles Unternehmen müsste Personal aufstellen, Teams ausrichten und Roadmap-Reviews planen. Wir probieren einfach Dinge aus. Der Abstand zwischen einer Idee und einem bereitgestellten Experiment wird in Stunden, nicht in Quartalen gemessen.

## Herausforderung, wie wir arbeiten, nicht nur, was wir bauen

Wir sind nicht emotional an die alten Weisen gebunden. Wir hinterfragen aktiv, was Code-Review bedeutet, wenn ein Agent den Großteil des Codes schreibt. Wie die Zusammenarbeit funktioniert, wenn das menschliche Team klein ist und Agenten die Routineaufgaben erledigen. Wie behebst du einen Fehler, wenn der Agent das laufende System inspizieren kann.

Wir machen Fehler. Wir werden sie weiterhin machen. Aber indem wir offen darüber bleiben, wie wir das Unternehmen gestalten und betreiben, entdecken wir weiterhin Ideen, die das Produkt beeinflussen. Die Art, wie wir operieren, ist nicht getrennt von dem, was wir bauen. Sie sind dasselbe.

[McKinsey hat kürzlich beschrieben](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) was sie "die agentische Organisation" nennen, ein neues Betriebsmodell, bei dem KI-Agenten zu vollwertigen Teilnehmern werden, die bestimmen, wie ein Unternehmen funktioniert. Wir betrachten es nicht als ein Modell. Es ist einfach so, wie wir arbeiten.

## Die Wette

Wir setzen darauf, dass ein kleines Team mit den richtigen Werkzeugen, der richtigen Einstellung und ohne organisatorischen Ballast Unternehmen mit hunderten Mitarbeitern und Millionen an Finanzierung überholen kann. Nicht auf allen Fronten, sondern auf derjenigen, die zählt: die Bereitstellung einer grundlegend besseren Lokalisierungserfahrung.

Die Branche kann sich nicht neu erfinden. Wir können.
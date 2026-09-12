%{
  title:
    "Wir bauen eine KI-zentrierte Firma auf, um eine Branche herauszufordern, die sich nicht selbst neu erfinden kann.",
  summary:
    "Etablierte Lokalisierungsunternehmen verfügen zwar über Kapital, nicht aber über die Freiheit zur Innovation. Wir entwickeln Glossia von Grund auf neu rund um KI und Agenten, nicht nur im Produkt, sondern in der gesamten Unternehmensführung.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten verändern alles. Nicht nur, was Software leisten kann, sondern wie Unternehmen aufgebaut sind, um diese Software zu erstellen. Bei [Glossia](https://glossia.ai), sehen wir dies als eine Chance, die in einer Generation nur einmal vorkommt, neu zu denken, wie Inhalte in jede Sprache gelangen. Doch wir wissen auch, dass eine gute Produktidee nicht ausreicht. Sie brauchen eine Organisation, die schnell genug ist, um wirklich Wirkung zu zeigen.

Das zweite Thema ist genau das, worum es in diesem Beitrag geht.

## Das Innovatordilemma, das sich in Echtzeit abspielt

Die Lokalisierungsbranche ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise entwickeln seit Jahren Tools und Dienstleistungen. Sie verfügen über Kunden, Umsatz, etablierte Workflows und Teams, die wissen, wie sie ihre Produkte verkaufen und unterstützen.

Warum würde ein kleines, fokussiertes Team das überhaupt versuchen?

Weil Clayton Christensen in etwas beschrieben hat [Das Innovatörendilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): etablierte Unternehmen haben Schwierigkeiten, disruptive Innovationen zu übernehmen, nicht weil ihnen Ressourcen fehlen, sondern weil ihre bestehenden Geschäftsmodelle, Kundenerwartungen und Organisationsstrukturen dies verhindern.

Diese Unternehmen entwickelten ihre Produkte auf Übersetzungsspeichern, Preisen pro Wort und menschlichen Übersetzer-Workflows auf. Ihre Kunden haben mentale Modelle und Prozesse um diese Bausteine herum aufgebaut. Eine Veränderung des Fundaments bedeutet, Bestandskunden ihre Zusagen zu brechen, Teams umzuschulen und Umsatzmodelle zu überdenken. Selbst mit den besten Absichten und verfügbarem Investitionskapital ist die organisatorische Trägheit enorm.

Sie benötigen Innovationsfähigkeit und das Engagement ihrer Mitarbeiter, um neue Ideen aufzunehmen. Aber noch schwieriger als das müssen sie ihre bestehenden Kunden an Bord holen. Und diese Kunden sind im alten Modell investiert.

Dies ist die Gelegenheit, die wir sehen. Nicht trotz weniger Ressourcen, sondern gerade wegen dieser. Wir haben kein Erbe zu bewahren, keine Workflows zu erhalten, keine Kunden zu migrieren. Wir können alles von Grund auf neu gestalten.

> \[\!HINWEIS\]
> Das Innovatörendilemma dreht sich nicht um Technologie. Es geht um Anreize. Etablierte Unternehmen optimieren für das, was ihre aktuellen Kunden wollen, was es fast unmöglich macht, etwas grundlegend anderes zu verfolgen.

## KI im Zentrum, nicht an den Rändern

Die meisten Unternehmen setzen KI ein, indem sie sie lediglich an bestehende Prozesse anhängen. Ein Chatbot hier, eine Empfehlungsmaschine dort. Wir gehen den anderen Weg: Wir gestalten das gesamte Unternehmen von Tag eins an so, dass es KI-zentriert ist.

Dies bedeutet, dass KI keine Funktion des Produkts ist. Sie prägt, wie wir bauen, verkaufen, unterstützen und betreiben. Jede Entscheidung, die wir treffen, beginnt mit einer Frage: Kann ein Agent das?

Das Produkt selbst ist ein Agent, der in deinem Terminal lebt, deine Quelldateien liest, Übersetzungen generiert, deine CI-Checks durchführt und iteriert, bis die Ausgabe erfolgreich ist. Das ist der Teil, den die Leute sehen. Aber dahinter steuert die gleiche Philosophie das Unternehmen.

## Ein kleines Team, das alles andere an Agenten delegiert.

Wir halten das Team bewusst klein und bleiben es solange so, wie es Sinn macht.

Es geht nicht darum, Kosten zu sparen. Es geht darum, eine komplette Kategorie an Arbeit zu eliminieren, die keinen Wert für die Nutzer schafft.

Je mehr Menschen du hinzufügst, desto mehr Koordination benötigst du. Du baust Vertrauenssysteme, Berechtigungsmodelle, Genehmigungsketten auf. Du verwaltest Konflikte, richtest Prioritäten aus, planst Termine. All das ist kreative Energie, die statt in die Erstellung eines Produkts in die Aufrechterhaltung einer menschlichen Organisation fließt.

Der Weg, wie wir das umsetzen, ist alles andere an Agenten zu delegieren. Marketinganalyse, Synthese von Kundenfeedback, Wettbewerbsforschung, Content-Erstellung, operatives Monitoring: Die Routinearbeit des Unternehmens wird zunehmend von Agenten übernommen, die wir gestalten, prüfen und verbessern.

## Bewusste Technologieentscheidungen

Wir gehen sehr bewusst mit unserem Tech-Stack um, da dieser direkt beeinflusst, wie schnell wir vorgehen können und wie sich die Software verhält, wenn Teams ihn selbst hosten.

**Für den Agenten (CLI):** Wir haben Rust gewählt. Es kompiliert plattformübergreifend in einzelne, portierbare Binaries ohne Laufzeitabhängigkeiten für den Benutzer.

**Für den Server:** Wir haben [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org) Laufzeit. Die funktionale Natur von Elixir macht es ideal für KI-Agent-Workloads. Die Erlang VM ist für Parallelverarbeitung und Fehlertoleranz bewährt. Und hier ist ein Bonus: Ein KI-Agent kann das laufende Erlang-System introspektieren, um zu verstehen, was abläuft, Einblicke zu sammeln und sogar Probleme in der Produktion zu beheben.

**Für die Verteilung:** Glossia ist Open Source unter [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Teams, die es selbst betreiben möchten, können das Helm Chart im Repository auf jedem Kubernetes-Cluster installieren. Der gleiche Code treibt den gehosteten Service bei glossia.ai und jedes selbst gehostete Deployment an.

> \[\!WICHTIG\]
> Wir überspringen technische Komplexität bewusst, die Ingenieure typischerweise zu früh anstreben, bevor sie verdient ist. Jede Abhängigkeit und jede Infrastrukturschicht muss ihr Gewicht rechtfertigen.

## Was dies freischaltet

Das Unternehmen auf diese Weise zu betreiben, ist mehr als nur ein Effizienzgewinn. Es verändert, was wir anbieten können und wie schnell wir lernen können.

**Zugänglicher für mehr Teams.** Die Lokalisierungsbranche hat ihre Werkzeuge durch komplexe Preisgestaltung, Gebühren pro Wort und Unternehmensverkaufszyklen unzugänglich gemacht. Wenn Ihr Übersetzungsablauf Beschaffung, Preisverhandlungen und einen Projektmanager erfordert, liefern die meisten kleinen Teams einfach auf Englisch aus. Indem wir eine effiziente Organisation aufbauen und die Software Open Source veröffentlichen, sodass Teams selbst hosten können, können wir Glossia wirklich zugänglich machen.

**Schnellere Innovation.** Wir wollen viele Ideen erforschen. Neue Schnittstellen für den Agenten, bessere Feedbackschleifen, neue Wege, um Linguisten in den Workflow zu integrieren. Eine traditionelle Firma müsste Personal verstärken, Teams ausrichten und Roadmap-Reviews planen. Wir versuchen einfach Dinge. Der Abstand zwischen einer Idee und einem eingeführten Experiment wird in Stunden gemessen, nicht in Quartalen.

## Wir hinterfragen, wie wir arbeiten – nicht nur, was wir entwickeln.

Wir sind nicht emotional an alte Vorgehensweisen gebunden. Wir hinterfragen aktiv, was Code-Review bedeutet, wenn ein Agent den Großteil des Codes schreibt. Wie Zusammenarbeit funktioniert, wenn das menschliche Team klein ist und Agenten die Routinearbeit übernehmen. Wie man eine Fehler behebt, wenn der Agent das laufende System prüfen kann.

Wir machen Fehler. Wir werden weiterhin Fehler machen. Aber indem wir offen gegenüber der Gestaltung und dem Betrieb des Geschäfts bleiben, entdecken wir kontinuierlich Ideen, die das Produkt beeinflussen. Unsere Art des Arbeitens steht nicht losgelöst von dem, was wir entwickeln. Das ist dieselbe Sache.

[McKinsey beschrieb dies kürz](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) Was sie „die agentische Organisation“ nennen, ein neues Betriebsmodell, in dem KI-Agenten zu vollwertigen Akteuren werden, die darüber entscheiden, wie ein Unternehmen läuft. Wir betrachten es nicht als Modell. Es ist einfach nur die Art und Weise, wie wir arbeiten.

## Das Wagnis

Wir setzen darauf, dass ein kleines Team mit den richtigen Werkzeugen, dem richtigen Mindset und ohne organisatorischen Ballast Unternehmen mit hunderten von Mitarbeitern und Millionen an Finanzierung überholen kann. Nicht an jeder Front, sondern an derjenigen, die wirklich zählt: die Lieferung eines grundlegend besseren Lokalisierungserlebnisses.

Die Branche kann sich nicht neu erfinden. Wir schon.
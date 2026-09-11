%{
  title:
    "Ein KI-zentriertes Unternehmen aufzubauen, um eine Branche herauszufordern, die sich selbst neu erfinden kann",
  summary:
    "Etablierte Lokalisierungsunternehmen verfügen zwar über das Kapital, aber nicht über die Freiheit, zu innovieren. Wir gestalten Glossia von Grund auf rund um KI und Agenten, nicht nur im Produkt, sondern auch in der Art, wie wir das gesamte Unternehmen führen.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten transformieren alles. Nicht nur was Software leisten kann, sondern wie Unternehmen aufgebaut sind, um diese Software zu erstellen. Bei [Glossia](https://glossia.ai), sehen wir dies als eine Chance dieser Generation, um neu zu überdenken, wie Inhalte jede Sprache erreichen. Doch wir wissen auch, dass eine gute Produktidee nicht ausreicht. Man braucht eine Organisation, die schnell genug ist, um wirklich zu zählen.

Dieser zweite Teil ist das Thema dieses Beitrags.

## Das Dilemma des Innovators, das in Echtzeit stattfindet

Die Lokalisationsbranche ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise erstellen seit Jahren Tools und Dienste. Sie haben Kunden, Umsatz, etablierte Arbeitsabläufe und Teams, die wissen, wie sie ihre Produkte verkaufen und unterstützen.

Also, warum würde ein kleines, fokussiertes Team das überhaupt versuchen?

Das liegt an etwas, das Clayton Christensen in [Das Innovator-Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): etablierte Unternehmen haben Schwierigkeiten, disruptive Innovationen zu übernehmen, nicht weil ihnen Ressourcen fehlen, sondern weil ihre bestehenden Geschäftsmodelle, Kundenerwartungen und Organisationsstrukturen dies verhindern.

Diese Unternehmen bauten ihre Produkte rund um Translationsspeicher, Stundlich-Preise und menschliche Übersetzer-Arbeitsabläufe. Ihre Kunden haben mentale Modelle und Prozesse rund um diese Bausteine entwickelt. Ein Wechsel der Grundlagen bedeutet, Versprechen an bestehende Kunden zu brechen, Teams neu auszubilden und Umsatzmodelle neu zu denken. Selbst mit den besten Absichten und der notwendigen Investitionskapazität ist die organisatorische Trägheit enorm.

Sie benötigen Innovationskapazität und das Engagement ihrer Belegschaft, um neuen Ideen offen zu stehen. Doch noch schwieriger ist, dass sie ihre bestehenden Kunden mitnehmen müssen. Und diese Kunden sind im alten Modell investiert.

Das ist die Chance, die wir sehen. Nicht trotz, sondern wegen geringerer Ressourcen. Wir haben kein Legacy-System zu beschützen, keine Workflows zu bewahren, keine Kunden zu migrieren. Wir können alles von Grund auf neu gestalten.

> \[\!NOTE\]
> Das Innovator-Dilemma geht nicht um Technologie. Es geht um Anreize. Etablierte Unternehmen optimieren für das, was ihre aktuellen Kunden wollen, was es nahezu unmöglich macht, etwas grundsätzlich Anderes nachzuhalten.

## KI im Zentrum, nicht am Rand

Die meisten Unternehmen übernehmen KI, indem sie sie an bestehende Prozesse anheften. Einen Chatbot hier, ein Empfehlungsmotor dort. Wir gehen den anderen Weg: Wir gestalten das gesamte Unternehmen von Tag eins an, so dass es KI-zentriert ist.

Das bedeutet, dass KI keine Funktion des Produkts ist. Sie prägt, wie wir entwickeln, verkaufen, unterstützen und betreiben. Jede Entscheidung, die wir treffen, beginnt mit einer Frage: Kann ein Agent das?

Das Produkt selbst ist ein Agent, der in Ihrem Terminal lebt, Ihre Quelldateien liest, Übersetzungen generiert, Ihre CI-Checks ausführt und iteriert, bis die Ausgabe erfolgreich ist. Das ist der Teil, den die Leute sehen. Aber dahinter wird das Unternehmen von derselben Philosophie geleitet.

## Ein kleines Team, das alles andere an Agenten delegiert

Wir halten das Team bewusst klein und bleiben so lange, solange es Sinn macht.

Es geht nicht darum, Geld zu sparen. Es geht darum, eine ganze Kategorie von Arbeit zu eliminieren, die keinen Mehrwert für Nutzer schafft.

Je mehr Menschen Sie hinzufügen, desto mehr Koordination benötigen Sie. Sie errichten Vertrauenssysteme, Berechtigungsmodelle, Genehmigungswege. Sie verwalten Konflikte, richten Prioritäten aus, planen Meetings. All das ist kreative Energie, die in die Pflege einer menschlichen Organisation fließt, statt in die Erstellung eines Produkts.

Der Weg, wie wir das umsetzen, besteht darin, alles andere an Agenten zu delegieren. Marketinganalyse, Synthese von Kundenfeedback, Wettbewerbsforschung, Inhaltserstellung, Betriebsüberwachung: Die Routineaufgaben des Betriebs werden zunehmend von Agenten erledigt, die wir gestalten, überprüfen und verbessern.

## Bewusste Technologieentscheidungen

Wir sind sehr bewusst in Bezug auf unseren Tech-Stack, da dieser direkt beeinflusst, wie schnell wir vorankommen können und wie sich die Software für die Teams, die sie selbst hosten, verhält.

**Für den Agenten (CLI):** Wir wählten Rust. Es compiliert zu einzelnen, portablen Binärdateien plattformübergreifend ohne Laufzeitabhängigkeiten für den Nutzer.

**Für den Server:** Wir wählten [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org) Laufzeit. Die funktionale Natur von Elixir macht es zu einer hervorragenden Wahl für agentische Workloads. Die Erlang VM ist bewährt für Parallelverarbeitung und Fehlertoleranz. Und hier ist ein Bonus: Ein KI-Agent kann das laufende Erlang-System introspektieren, um zu verstehen, was passiert, Erkenntnisse zu sammeln und selbst Probleme in der Produktion zu beheben.

**Für die Verteilung:** Glossia ist Open Source unter der [O'Saasy Lizenz](https://github.com/glossia/glossia/blob/main/LICENSE.md). Teams, die es selbst betreiben möchten, können das Helm-Chart im Repository auf jedem Kubernetes-Cluster installieren. Der gleiche Code ist Grundlage für den gehosteten Dienst bei glossia.ai und jede selbstgehostete Bereitstellung.

> \[\!WICHTIG\]
> Wir überspringen bewusst technische Komplexität, die Ingenieure oft zu früh anstreben, bevor sie verdient ist. Jede Abhängigkeit und jede Infrastrukturschicht muss ihr Gewicht rechtfertigen.

## Was dies ermöglicht

Die Organisation des Unternehmens auf diese Weise ist nicht nur eine Effizienzmaßnahme. Sie verändert, was wir bieten und wie schnell wir lernen.

**Zugänglich für mehr Teams.** Die Lokalisierungsbranche hat ihre Tools durch komplexe Preisgestaltung, Pro-Wort-Gebühren und langwierige Unternehmensvertriebszyklen unzugänglich gemacht. Wenn Ihr Übersetzungsworkflow Beschaffungen, Preisverhandlungen und einen Projektmanager erfordert, veröffentlichen die meisten kleinen Teams lediglich auf Englisch. Indem wir eine effiziente Organisation aufbauen und die Software als Open Source veröffentlichen, damit Teams sie selbst hosten können, können wir Glossia wirklich zugänglich machen.

**Schnellere Innovation.** Wir wollen viele Ideen erkunden. Neue Schnittstellen für den Agenten, bessere Feedbackschleifen, neue Wege, Linguisten in den Workflow zu integrieren. Ein traditionelles Unternehmen müsste Personal aufstellen, Teams ausrichten und Roadmap-Besprechungen planen. Wir probieren einfach Dinge aus. Der Abstand zwischen einer Idee und einem implementierten Experiment wird in Stunden, nicht in Quartalen gemessen.

## Hinterfragen, wie wir arbeiten, nicht nur, was wir bauen

Wir sind nicht emotional an die alten Arten, Dinge zu tun, gebunden. Wir hinterfragen aktiv, was Code-Review bedeutet, wenn ein Agent den meisten Code schreibt. Wie Zusammenarbeit funktioniert, wenn das menschliche Team klein ist und Agenten die Routinarbeit erledigen. Wie man einen Bug behebt, wenn der Agent das laufende System inspizieren kann.

Wir machen Fehler. Wir werden sie weiterhin machen. Aber indem wir offen gegenüber der Gestaltung und dem Führen des Geschäfts bleiben, entdecken wir ständig Ideen, die das Produkt beeinflussen. Die Art und Weise, wie wir operieren, ist nicht getrennt von dem, was wir bauen. Sie sind das Gleiche.

[McKinsey hat kürzlich beschrieben](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) was sie "die agentische Organisation" nennen, ein neues Betriebsmodell, bei dem KI-Agenten gleichberechtigte Teilnehmer im Unternehmensbetrieb sind. Wir betrachten es nicht als Modell. Es ist einfach so, wie wir arbeiten.

## Das Wagnis

Wir setzen darauf, dass ein kleines Team mit den richtigen Werkzeugen, der richtigen Einstellung und ohne organisatorischen Ballast Unternehmen mit Hunderten Mitarbeitern und Millionen in der Finanzierung überholen kann. Nicht auf allen Fronten, sondern auf der einen, die zählt: die Lieferung einer grundlegend besseren Lokalisierungserfahrung.

Die Branche kann sich nicht neu erfinden. Wir können.
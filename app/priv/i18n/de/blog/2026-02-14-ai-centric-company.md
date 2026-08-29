%{
  title: "Ein KI-zentriertes Unternehmen aufbauen, um eine Branche herauszufordern, die sich nicht selbst erfinden kann.",
  summary: "Etablierte Lokalisierungsfirmen verfügen zwar über das Kapital, nicht aber über die Freiheit zu innovieren. Wir gestalten Glossia von Grund auf neu rund um KI und Agenten, nicht nur im Produkt, sondern auch darin, wie wir das gesamte Unternehmen führen.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten verändern alles. Nicht nur, was Software kann, sondern auch, wie Unternehmen aufgebaut sind, um diese Software zu entwickeln. Bei [Glossia](https://glossia.ai) sehen wir dies als eine einmalige Chance der Generation, neu zu denken, wie Inhalte jede Sprache erreichen. Aber wir wissen auch, dass eine gute Produktidee nicht ausreicht. Sie brauchen eine Organisation, die schnell genug agieren kann, um wirklich zu zählen.

Das zweite Stück ist genau das Thema dieses Beitrags.

## Das Innovator's Dilemma in Echtzeit

Die Lokalisierungsbranche ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise bauen seit Jahren Tools und Dienste auf. Sie haben Kunden, Einnahmen etablierter Workflows und Teams, die wissen, wie sie ihre Produkte verkaufen und unterstützen.

Warum würde also eine Zwei-Personen-Team eigentlich versuchen?

Aus etwas, das Clayton Christensen in [The Innovator's Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma) beschrieb: Etablierte Unternehmen haben Mühe, disruptive Innovation anzunehmen, nicht wegen Ressourcenmangel, sondern weil ihre bestehenden Geschäftsmodelle, Kundenerwartungen und Organisationsstrukturen es verhindern.

Diese Unternehmen bauten ihre Produkte um Translation Memories, Stichwortpreise und Workflows menschlicher Übersetzer. Ihre Kunden haben mentale Modelle und Prozesse rund um diese Bausteine entwickelt. Das Fundament zu ändern bedeutet, Verträge bestehenden Kunden zu brechen, Teams neu zu schulen und Ertragsmodelle neu zu denken. Selbst mit bester Absicht und den Mitteln zu investieren, ist die organisatorische Trägheit enorm.

Sie brauchen Innovationsfähigkeit und Commitment von Ihrer Belegschaft, um neue Ideen anzunehmen. Aber noch schwieriger ist es, ihre bestehenden Kunden mitzunehmen. Und diese Kunden sind im alten Modell investiert.

Hier liegt das, was wir sehen. Nicht trotz weniger Ressourcen, sondern wegen. Wir haben kein altes Erbe zu schützen, keine Workflows zu bewahren, keine Kunden zu migrieren. Wir können alles von Grund auf neu entwickeln.

> \[\!NOTE\]
> Das Innovator's Dilemma geht nicht um Technologie. Es geht um Anreize. Etablierte Unternehmen optimieren für das, was ihre aktuellen Kunden wollen, was es quasi unmöglich macht, etwas grundlegend anderes zu verfolgen.

## KI im Zentrum, nicht am Rand

Die meisten Unternehmen integrieren KI, indem sie sie an bestehenden Prozessen festklemmen. Ein Chatbot hier, ein Vorschlagsmodul dort. Wir gehen den anderen Weg: Wir designen das gesamte Unternehmen von Tag eins an KI-zentriert zu sein.

Das bedeutet, KI ist keine Funktion des Produkts. Sie bestimmt, wie wir bauen, verkaufen, unterstützen und betreiben. Jede Entscheidung beginnt mit einer Frage: Kann ein Agent das?

Das Produkt selbst ist ein Agent, der in deinem Terminal lebt, deine Quelldateien liest, Übersetzungen generiert, deine CI-Checks durchführt und zu iterieren, bis die Ausgabe akzeptiert ist. Das ist der Teil, den man sieht. Aber dahinter läuft dieselbe Philosophie im Unternehmen.

## Zwei Personen, Null organisatorischer Overhead

Wir halten das Team absichtlich so klein wie möglich möglich. Derzeit sind es genau zwei von uns. Unser Ziel ist es, bei zwei oder drei Personen so lange zu bleiben, wie wir können.

Es geht nicht um Geldersparnis (obwohl es hilft). Es geht darum, eine gesamte Kategorie von Arbeit abzuschaffen, die den Nutzern keine Wertschöpfung bringt.

Je mehr Menschen Sie hinzufügen, desto mehr Koordination benötigen Sie. Sie bauen Vertrauenssysteme, Berechtigungsmodelle, Genehmigungsreihen. Sie koordinieren Konflikte, passen Prioritäten an und planen Meetings. All das ist kreative Energie, die in das Aufrechterhalten einer menschlichen Organisation fließt, anstatt ein Produkt zu bauen.

Mit zwei Personen überspringen wir das alles. Wir vertrauen einander voll. Wir haben Zugriff auf alles. Es gibt keinen Overhead, keine Politik, keinen Prozess um des Prozesses willen.

Der Schlüssel, wie wir dies im großen Maßstab funktionieren, liegt darin, alles andere an Agenten zu delegieren.

## Discord, ein KI-Agent und eine einzige Kommandozeile

Hier kommt etwas, das seltsam klingen mag: Unsere primäre geschäftliche Schnittstelle ist ein [Discord](https://discord.com)-Server.

Wir verfügen über einen damit verbundenen KI-Agenten, der von [OpenAI](https://openai.com) angetrieben wird, Zugriff auf alle benötigten Tools zum Betrieb des Unternehmens. Statt zwischen Web-Dashboards, Analyseplattformen und Admin-Panels umzuschalten, sprechen wir mit dem Agenten. Text und Stimme sind die Einheit der Interaktion.

Durch den Agenten können wir:

- Marketing- und Produktanalysen abfragen
- Produktionsserver inspizieren
- Marktforschung durchführen
- Kundenfeedback sammeln
- Wettbewerbsanalysen durch Web-Browsing durchführen
- Inhalte entwerfen, Texte überprüfen und veröffentlichen

Keiner von uns ist auf den anderen angewiesen, um dies zu erledigen. Der Agent hat Zugriff auf unsere APIs, Datenbanken und Überwachungstools. Er kann das Web durchsuchen, Dokumentation lesen und Informationen synthetisieren. Es ist ein Discord-Server, eine OpenAI-Instanz und ein LLM-Schlüssel. Das ist das Betriebssystem des Unternehmens.

> \[\!TIP\]
> Wenn Sie ein kleines Team aufbauen und den Koordinierungsbedarf reduzieren wollen, sollten Sie Text und Stimme als primäres Interface für Geschäftsoperationen考虑 machen. Ein gemeinsamer Agent in einem Chat-Kanal kann dutzende Dashboards ersetzen und die meisten internen Tools überflüssig machen.

## Bewusste technologische Entscheidungen

Wir sind sehr bewusst mit unserem Stack, da dies direkt beeinflusst, wie schnell wir vorankommen und wie kostengünstig wir operieren können.

**Für den Agenten (CLI):** Wir haben uns für Go entschieden. Es kompiliert zu einzelnen, portablen Binärdateien über Plattformen hinweg ohne Laufzeitabhängigkeiten für den Benutzer.

**Für den Server:** Wir haben uns für [Elixir](https://elixir-lang.org) und das [Erlang](https://www.erlang.org) Runtime entschieden. Die funktionale Natur von Elixir macht es ideal für agentenbasierte Workloads. Die Erlang-VM ist für Parallelverarbeitung und Fehlertoleranz bewährt. Und hier ist ein Bonus: Ein KI-Agent kann das laufende Erlang-System introspektieren, um zu verstehen, was passiert, Erkenntnisse sammeln und sogar Probleme in der Produktion beheben.

**Für die Infrastruktur:** Alles läuft auf einer einzelnen VPS. Nicht nur der Glossia-Produktionsserver, sondern auch alle peripheren Dienste: [PostgreSQL](https://www.postgresql.org/) für die Datenbank, [Plausible](https://plausible.io) für datenschutzfreundliche Analysen, [Grafana](https://grafana.com) für Telemetrie und Observability. Alles wird aus version kontrollierten Infrastrukturdefinitionen bereitgestellt, die beschreiben, wohin was gehört.

Dies hält die Kosten extrem niedrig. Wir sind nicht von Drittanbieter-Cloud-Diensten, verwalteten Datenbanken oder Plattform-als-a-Service-Anbietern abhängig. Wir haben einige externe Abhängigkeiten, aber nur für Dinge, die uns eine lange Zeit zur Replikation erfordern würden und bei denen der Preis Sinn ergibt.

Wenn es die Zeit kommt, über Server hinweg zu skalieren, werden wir das Modell weiterentwickeln. Aber wir glauben, wir können eine lange Strecke mit dieser Aufstellung gehen. Und Geschwindigkeit zählt vorerst wichtiger als Größe.

> \[\!IMPORTANT\]
> Wir sind sehr bewusst dabei, technische Komplexität zu überspringen, der Ingenieure tendenziell frühzeitig streben. Kubernetes, Microservices, Multi-Region-Bereitstellungen. Dafür wird an dieser Stelle nichts benötigt und alles würde uns verlangsamen.

## Was dies ermöglicht

Das Unternehmen auf diese Weise zu führen ist nicht nur ein Effizienz-Vergnügen. Es ändert, was wir bieten können und wie schnell wir lernen können.

**Günstiger für Nutzer.** Die Lokalisierungsindustrie hat ihre Tools durch komplexe Preisgestaltung, pro-Wort-Gebühren und Enterprise-Verkaufszyklen unzugänglich gemacht. Wenn Ihr Übersetzungsworkflow Beschaffung, Preisverhandlungen und einen Projektmanager benötigt, werden die meisten kleinen Teams einfach auf Englisch veröffentlichen. Indem wir unsere Betriebskosten nahe Null halten, können wir etwas anbieten, das wirklich zugänglich ist.

**Schnellere Innovation.** Wir wollen viele Ideen erforschen. Neue Schnittstellen für den Agenten, bessere Feedbackschleifen, neue Wege, Linguisten in den Workflow zu bringen. Ein traditionelles Unternehmen müsste Personal aufnehmen, Teams ausrichten und Roadmap-Reviews planen. Wir versuchen einfach Dinge. Die Distanz zwischen einer Idee und einem eingeführten Experiment wird in Stunden gemessen, nicht in Quartalen.

## Wie wir arbeiten hinterfragen, nicht nur das, was wir bauen

Wir sind nicht emotionally an die alten Vorgehensweisen gebunden. Wir hinterfragen aktiv, was Code-Review bedeutet, wenn ein Agent den Großteil des Codes schreibt. Wie Zusammenarbeit funktioniert, wenn nur zwei Menschen beteiligt sind. Wie du einen Fehler behebst, wenn der Agent das laufende System prüfen kann.

Wir machen Fehler. Wir werden sie auch weiterhin begehen. Aber indem wir offen bleiben für die Art und Weise, wie wir das Unternehmen gestalten und betreiben, entdecken wir ständig Ideen, die das Produkt beeinflussen. Die Art, wie wir operieren, ist nicht von dem getrennt, was wir bauen. Sie sind dasselbe.

[McKinsey hat kürzlich beschrieben](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era), was sie »die agentische Organisation« nennen, ein neues Betriebsmodell, in dem KI-Agenten zu gleichberechtigten Teilnehmern werden, die bestimmen, wie ein Unternehmen funktioniert. Wir betrachten es nicht als Modell. Es ist einfach nur das, wie wir arbeiten.

## Die Wette

Wir setzen darauf, dass ein Zwei-Personen-Team mit den richtigen Werkzeugen, der richtigen Einstellung und ohne organisatorischen Ballast Unternehmen mit hunderten Mitarbeitern und Millionen an Finanzierung überholen kann. Nicht an jeder Front, sondern an derjenigen, die zählt: das Anbieten einer grundlegend besseren Lokalisierungserfahrung.

Die Branche kann sich nicht neu erfinden. Wir können.
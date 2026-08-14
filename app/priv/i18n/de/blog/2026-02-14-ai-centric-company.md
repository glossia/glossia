%{
  title: "Aufbau eines KI-zentrierten Unternehmens zur Herausforderung einer Branche, die sich nicht selbst neu erfinden kann",
  summary: "Etablierte Lokalisierungsunternehmen verfügen über das Kapital, aber nicht über die Freiheit zu Innovationen. Wir konzipieren Glossia von Grund auf um KI und Agenten herum, und zwar nicht nur im Produkt, sondern in der gesamten Struktur unseres Unternehmens.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten verändern alles. Nicht nur, was Software leisten kann, sondern auch, wie Unternehmen aufgebaut sind, die diese Software entwickeln. Bei [Glossia](https://glossia.ai) sehen wir dies als eine einmalige Chance für eine ganze Generation, die Bereitstellung von Inhalten in allen Sprachen grundlegend neu zu überdenken. Wir wissen jedoch auch, dass eine gute Produktidee allein nicht ausreicht. Es bedarf einer Organisation, die sich schnell genug bewegen kann, um eine Rolle zu spielen.

Um diesen zweiten Teil geht es in diesem Beitrag.

## Das Innovator-Dilemma in Echtzeit

Die Lokalisierungsbranche ist groß und kapitalkräftig. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise entwickeln seit Jahren Tools und Dienstleistungen. Sie verfügen über Kunden, Umsätze, etablierte Workflows und Teams, die ihre Produkte vertreiben und unterstützen können.

Warum sollte ein Zwei-Personen-Team es also überhaupt versuchen?

Wegen eines Phänomens, das Clayton Christensen in [The Innovator's Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma) beschrieben hat: Etablierte Unternehmen tun sich schwer damit, disruptive Innovationen zu übernehmen. Dies liegt nicht an einem Mangel an Ressourcen, sondern daran, dass ihre bestehenden Geschäftsmodelle, Kundenerwartungen und Organisationsstrukturen sie daran hindern.

Diese Unternehmen haben ihre Produkte um Translation Memories, Wortpreise und die Workflows menschlicher Übersetzer herum aufgebaut. Ihre Kunden haben mentale Modelle und Prozesse um diese Bausteine herum entwickelt. Eine Änderung des Fundaments bedeutet, Versprechen gegenüber bestehenden Kunden zu brechen, Teams umzuschulen und Erlösmodelle zu überdenken. Selbst bei besten Absichten und ausreichendem Investitionskapital ist die organisatorische Trägheit enorm.

Sie benötigen Innovationskapazität und das Engagement ihrer Belegschaft, um neue Ideen anzunehmen. Doch was noch schwerer wiegt: Sie müssen ihre bestehenden Kunden für diesen Weg gewinnen. Und diese Kunden haben bereits in das alte Modell investiert.

Hier sehen wir unsere Chance. Nicht trotz der geringeren Ressourcen, sondern genau deswegen. Wir müssen keine Altlasten schützen, keine bestehenden Workflows bewahren und keine Kunden migrieren. Wir können alles von Grund auf neu entwerfen.

> [!NOTE]
> Beim Innovator-Dilemma geht es nicht um Technologie. Es geht um Anreize. Etablierte Unternehmen optimieren für die Wünsche ihrer aktuellen Kunden, was es fast unmöglich macht, etwas grundlegend anderes zu verfolgen.

## KI im Zentrum, nicht am Rand

Die meisten Unternehmen führen KI ein, indem sie diese an bestehende Prozesse anflanschen. Ein Chatbot hier, eine Suggestion Engine dort. Wir gehen den umgekehrten Weg und richten das gesamte Unternehmen vom ersten Tag an konsequent auf KI aus.

Das bedeutet, dass KI kein bloßes Feature des Produkts ist. Sie prägt die Art und Weise, wie wir entwickeln, verkaufen, Support leisten und operieren. Jede Entscheidung, die wir treffen, beginnt mit der Frage: Kann ein Agent diese Aufgabe übernehmen?

Das Produkt selbst ist ein Agent, der in Ihrem Terminal läuft, Ihre Quelldateien liest, Übersetzungen generiert, Ihre CI-Prüfungen ausführt und so lange iteriert, bis das Ergebnis korrekt ist. Das ist der Teil, den die Anwender sehen. Doch im Hintergrund bestimmt dieselbe Philosophie die Führung des gesamten Unternehmens.

## Zwei Personen, kein organisatorischer Overhead

Wir halten das Team bewusst so klein wie möglich. Derzeit sind wir nur zu zweit. Unser Ziel ist es, so lange wie möglich mit zwei oder drei Personen zu arbeiten.

Dabei geht es nicht darum, Geld zu sparen (auch wenn es hilft). Es geht darum, eine ganze Kategorie von Arbeit zu eliminieren, die keinen Wert für die Nutzer schafft.

Je mehr Menschen hinzukommen, desto mehr Koordination ist erforderlich. Man baut Vertrauenssysteme, Berechtigungsmodelle und Genehmigungsketten auf. Man löst Konflikte, stimmt Prioritäten ab und plant Meetings. All dies verbraucht kreative Energie, die in den Erhalt einer menschlichen Organisation statt in den Aufbau eines Produkts fließt.

Mit zwei Personen überspringen wir all das. Wir vertrauen uns vollkommen. Wir haben Zugriff auf alles. Es gibt keinen Overhead, keine Politik und keine Prozesse um der Prozesse willen.

Um dieses Modell skalierbar zu machen, delegieren wir alles andere an Agenten.

## Discord, ein KI-Agent und eine einzige Befehlszeile

Hier ist etwas, das ungewöhnlich klingen mag: Unsere primäre Geschäftsschnittstelle ist ein [Discord](https://discord.com)-Server.

Wir haben einen KI-Agenten daran angeschlossen, der von [OpenAI](https://openai.com) unterstützt wird und Zugriff auf alle Tools hat, die wir für die Führung des Unternehmens benötigen. Anstatt zwischen Web-Dashboards, Analyseplattformen und Administrations-Panels zu wechseln, sprechen wir mit dem Agenten. Text und Stimme sind die Interaktionseinheiten.

Über den Agenten kann jeder von uns Folgendes tun:

- Marketing- und Produktanalysen abfragen
- Produktionsserver überprüfen
- Marktforschung betreiben
- Kundenfeedback einholen
- Wettbewerbsanalysen durch Websuche durchführen
- Inhalte entwerfen, Texte überprüfen und veröffentlichen

Keiner von uns ist bei diesen Aufgaben vom anderen abhängig. Der Agent hat Zugriff auf unsere APIs, Datenbanken und Monitoring-Tools. Er kann im Web surfen, Dokumentationen lesen und Informationen zusammenführen. Es ist ein Discord-Server, eine OpenAI-Instanz und ein LLM-Schlüssel. Das ist das Betriebssystem des Unternehmens.

> [!TIP]
> Wenn Sie ein kleines Team aufbauen und den Koordinationsaufwand reduzieren möchten, sollten Sie Text und Stimme zu Ihrer primären Schnittstelle für den Geschäftsbetrieb machen. Ein gemeinsam genutzter Agent in einem Chatkanal kann Dutzende von Dashboards ersetzen und den Bedarf an den meisten internen Tools überflüssig machen.

## Bewusste Technologieentscheidungen

Wir wählen unseren Stack sehr bewusst aus, da er sich direkt darauf auswirkt, wie schnell wir agieren und wie kostengünstig wir arbeiten können.

**Für den Agenten (CLI):** Wir haben uns für Go entschieden. Es lässt sich in einzelne, portable Binärdateien für verschiedene Plattformen kompilieren, ohne dass Laufzeitabhängigkeiten für den Benutzer entstehen.

**Für den Server:** Wir haben uns für [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org)-Laufzeitumgebung entschieden. Die funktionale Natur von Elixir eignet sich hervorragend für agentenbasierte Workloads. Die Erlang-VM ist für Nebenläufigkeit und Fehlertoleranz praxiserprobt. Und als Bonus: Ein KI-Agent kann das laufende Erlang-System analysieren, um zu verstehen, was passiert, Erkenntnisse zu gewinnen und sogar Probleme in der Produktion zu beheben.

**Für die Infrastruktur:** Alles läuft auf einem einzigen VPS. Nicht nur der Glossia-Produktionsserver, sondern auch alle Peripheriedienste: [PostgreSQL](https://www.postgresql.org/) für die Datenbank, [Plausible](https://plausible.io) für datenschutzfreundliche Analysen, [Grafana](https://grafana.com) für Telemetrie und Observability. Alles wird über versionierte Infrastrukturdefinitionen bereitgestellt, die beschreiben, was wohin gehört.

Dies hält die Kosten extrem niedrig. Wir sind nicht von Cloud-Diensten von Drittanbietern, verwalteten Datenbanken oder Platform-as-a-Service-Anbietern abhängig. Wir haben einige wenige externe Abhängigkeiten, aber nur für Dinge, deren Nachbildung uns viel Zeit kosten würde und bei denen die Kosten gerechtfertigt sind.

Wenn die Zeit für eine Skalierung über mehrere Server hinweg gekommen ist, werden wir das Modell weiterentwickeln. Wir glauben jedoch, dass wir mit diesem Setup sehr weit kommen können. Und Schnelligkeit ist im Moment wichtiger als Größe.

> [!IMPORTANT]
> Wir verzichten ganz bewusst auf technische Komplexität, zu der Entwickler in einem frühen Stadium neigen. Kubernetes, Mikroservices, Multi-Regionen-Deployments. Nichts davon wird in dieser Phase benötigt, und all das würde uns nur ausbremsen.

## Was dies ermöglicht

Das Unternehmen auf diese Weise zu führen, ist nicht nur eine Effizienzmaßnahme. Es verändert, was wir anbieten können und wie schnell wir lernen.

**Günstiger für Nutzer.** Die Lokalisierungsbranche hat ihre Tools durch komplexe Preisstrukturen, Wortgebühren und Enterprise-Vertriebszyklen unzugänglich gemacht. Wenn Ihr Übersetzungsworkflow Beschaffungsprozesse, Preisverhandlungen und einen Projektmanager erfordert, werden die meisten kleinen Teams ihre Produkte einfach nur auf Englisch veröffentlichen.

**Schnellere Innovation.** Wir wollen viele Ideen erproben. Neue Schnittstellen für den Agenten, verbesserte Feedback-Schleifen, neue Wege zur Einbindung von Linguisten in den Arbeitsablauf. Ein traditionelles Unternehmen müsste zusätzliches Personal einstellen, Teams aufeinander abstimmen und Roadmap-Reviews planen. Wir probieren Dinge einfach aus. Die Zeitspanne zwischen einer Idee und einem bereitgestellten Experiment bemisst sich in Stunden, nicht in Quartalen.

## Unsere Arbeitsweise hinterfragen, nicht nur das, was wir entwickeln

Wir hängen nicht emotional an alten Arbeitsweisen. Wir hinterfragen aktiv, was ein Code-Review bedeutet, wenn ein Agent den Großteil des Codes schreibt. Wie die Zusammenarbeit funktioniert, wenn es nur zwei Menschen gibt. Wie man einen Fehler behebt, wenn der Agent das laufende System inspizieren kann.

Wir machen Fehler. Wir werden auch weiterhin Fehler machen. Doch indem wir offen dafür bleiben, wie wir das Unternehmen gestalten und führen, entdecken wir kontinuierlich Ansätze, die das Produkt beeinflussen. Unsere Arbeitsweise ist nicht von dem getrennt, was wir entwickeln. Es ist ein und dasselbe.

[McKinsey beschrieb kürzlich](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ein Konzept, das sie als „die agentenbasierte Organisation“ bezeichnen. Dabei handelt es sich um ein neues Betriebsmodell, bei dem KI-Agenten zu vollwertigen Akteuren im laufenden Betrieb eines Unternehmens werden. Wir betrachten dies nicht als ein Modell. Es ist einfach unsere Arbeitsweise.

## Die Wette

Wir setzen darauf, dass ein Zwei-Personen-Team mit den richtigen Werkzeugen, der richtigen Mentalität und ohne organisatorischen Ballast Unternehmen mit Hunderten von Mitarbeitenden und Millioneninvestitionen überholen kann. Nicht an jeder Front, aber an der entscheidenden: der Bereitstellung einer grundlegend besseren Lokalisierungserfahrung.

Die Branche kann sich nicht neu erfinden. Wir können es.
%{
  title:
    "Aufbau eines KI-zentrierten Unternehmens, um eine Branche herauszufordern, die nicht neu erfinden kann",
  summary:
    "Etablierte Lokalisierungsunternehmen verfügen über das Kapital, aber nicht über die Freiheit zu innovieren. Wir gestalten Glossia von Grund auf rund um KI und Agenten, nicht nur im Produkt, sondern auch in der Art, wie wir das gesamte Unternehmen führen.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
LLMs und Agenten verwandeln alles. Nicht nur, was Software kann, sondern wie Unternehmen aufgebaut sind, um diese Software zu entwickeln. Bei [Glossia](https://glossia.ai) sehen wir dies als eine einmalige Chance, neu zu denken, wie Inhalte in jede Sprache gelangen. Aber wir wissen auch, dass eine gute Produktidee allein nicht ausreicht. Man braucht eine Organisation, die schnell genug agieren kann, um Relevanz zu gewinnen.

Genau darum geht es in diesem Beitrag.

## Das Innovators-Dilemma, das sich in Echtzeit abspielt

Die Lokalisierungswirtschaft ist groß und gut finanziert. Unternehmen wie Smartling, Phrase, Crowdin und Lokalise entwickeln seit Jahren Tools und Dienste. Sie haben Kunden, Umsatz, etablierte Arbeitsabläufe und Teams, die wissen, wie man ihre Produkte verkauft und unterstützt.

Warum sollte ein Team von nur zwei Personen es denn überhaupt versuchen?

Weil Clayton Christensen in [Das Innovators-Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma) beschreibt: Etablierte Unternehmen haben Schwierigkeiten, disruptive Innovationen anzunehmen, nicht wegen fehlender Ressourcen, sondern weil ihre bestehenden Geschäftsmodelle, Kundenerwartungen und Organisationsstrukturen dies verhindern.

Diese Unternehmen bauten ihre Produkte um einen Übersetzungsspeicher, Preise pro Wort und Arbeitsabläufe menschlicher Übersetzer herum. Ihre Kunden haben mentale Modelle und Prozesse um diese Bausteine herum aufgebaut. Das Fundament zu ändern bedeutet, Versprechungen gegenüber bestehenden Kunden zu brechen, Teams nachzuschrüben und Umsatzmodelle neu zu durchdenken. Selbst bei den besten Absichten und dem Kapital für Investitionen ist die organisatorische Trägheit enorm.

Sie brauchen Innovationsfähigkeit und Engagement ihrer Belegschaft, um neue Ideen anzunehmen. Aber noch schwieriger ist, dass sie ihre bestehenden Kunden für die Fahrt brauchen. Und diese Kunden sind im alten Modell investiert.

Das ist die Lücke, die wir sehen. Nicht trotz weniger Ressourcen, sondern gerade wegen davon. Wir haben kein veraltetes Erbe zu schützen, keine Abläufe zu erhalten und keine Kunden zu migrieren. Wir können alles von Grund auf entwerfen.

> \[\!NOTE\]
> Das Innovators-Dilemma geht nicht um Technologie. Es geht um Anreize. Etablierte Unternehmen optimieren für das, was ihre aktuellen Kunden wollen, was es nahezu unmöglich macht, etwas grundlegend anderes anzustreben.

## KI im Zentrum, nicht an den Rändern

Die meisten Unternehmen setzen KI ein, indem sie sie auf bestehende Prozesse aufbauen. Ein Chatbot hier, ein Suggestion-Engine dort. Wir gehen den anderen Weg: Wir gestalten das gesamte Unternehmen vom ersten Tag an als KI-zentriert.

Das bedeutet, KI ist keine Funktion des Produkts. Sie prägt, wie wir bauen, verkaufen, unterstützen und betreiben. Jede Entscheidung, die wir treffen, beginnt mit einer Frage: Kann ein Agent dies tun?

Das Produkt selbst ist ein Agent, der in deinem Terminal lebt, deine Quelldateien liest, Übersetzungen generiert, deine CI-Checks ausführt und iteriert, bis die Ausgabe validiert wird. Das ist der Teil, den die Leute sehen. Aber dahinter läuft die gleiche Philosophie über das Geschäft.

## Zwei Personen, kein organisatorischer Overhead

Wir halten das Team absichtlich so klein wie möglich. Momentan sind es gerade zwei von uns. Unser Ziel ist es, zwei oder drei Personen so lange wie möglich zu bleiben.

Es geht nicht darum, Geld zu sparen (obwohl es hilft). Es geht darum, eine ganze Kategorie von Arbeit zu eliminieren, die keinen Mehrwert für Benutzer liefert.

Je mehr Menschen Sie hinzufügen, desto mehr Koordination brauchen Sie. Sie bauen Vertrauenssysteme, Berechtigungsmodelle und Genehmigungsreihenfolgen auf. Sie lösen Konflikte, richten Prioritäten aus und planen Meetings. All das ist kreative Energie, die der Aufrechterhaltung einer menschlichen Organisation dient, statt ein Produkt zu bauen.

Mit zwei Personen überspringen wir das alles. Wir vertrauen einander voll und ganz. Wir haben Zugang zu allem. Es gibt keinen Overhead, keine Politik, keinen Prozess, nur um den Prozess willen.

Die Art und Weise, wie dies in großem Maßstab funktioniert, besteht darin, alles andere an Agenten zu delegieren.

## Discord, ein KI-Agent und eine einzige Kommandozeile

Hier ist etwas, das vielleicht ungewohnt klingt: Unsere primäre Geschäftsoberfläche ist ein [Discord](https://discord.com)-Server.

Wir verfügen über einen daran angeschlossenen KI-Agenten, der von [OpenAI](https://openai.com) angetrieben wird und Zugriff auf alle Tools hat, die wir brauchen, um das Geschäft zu betreiben. Anstatt zwischen Web-Dashboards, Analytics-Plattformen und Admin-Panele umzuschalten, sprechen wir mit dem Agenten. Text und Sprache sind die Interaktionseinheit.

Unter dem Agenten kann einer von uns:

- Marketing- und Produkt-Analysen abfragen
- Produktionsserver inspizieren
- Marktforschung durchführen
- Kundenfeedback sammeln
- Wettbewerbsanalysen durch Web-Surfen durchführen
- Inhalte entwerfen, Übersetzungen prüfen und veröffentlichen

Keiner von uns ist vom anderen abhängig, um dies zu erledigen. Der Agent hat Zugriff auf unsere APIs, Datenbanken und Monitoring-Tools. Er kann das Web durchsuchen, Dokumentation lesen und Informationen synthetisieren. Er ist ein Discord-Server, eine OpenAI-Instanz und ein LLM-Schlüssel. Das ist das Betriebssystem des Unternehmens.

> \[\!TIP\]
> Wenn Sie ein kleines Team aufbauen und Koordinationsaufwand reduzieren wollen, sollten Sie Texte und Sprache als Ihre primäre Schnittstelle für das Geschäftsbetrieb in Betracht ziehen. Ein gemeinsamer Agent in einem Chat-Kanal kann dutzende Dashboards ersetzen und die Notwendigkeit für die meisten internen Tools beseitigen.

## Gezielte Technologieentscheidungen

Wir sind sehr bewusst in Bezug auf unseren Stack, da dies direkt beeinflusst, wie schnell wir uns bewegen können und wie günstig wir operieren können.

**Für den Agenten (CLI):** Wir haben Go gewählt. Es kompiliert zu einzelnen, portablen Binärdateien auf Plattformen ohne Laufzeitabhängigkeiten für den Benutzer.

**Für den Server:** Wir haben [Elixir](https://elixir-lang.org) und die [Erlang](https://www.erlang.org)-Laufzeitumgebung gewählt. Die funktionale Natur von Elixir macht es zu einer hervorragenden Wahl für Agenten-Arbeitslasten. Die Erlang-VM ist für Parallelverarbeitung und Fehlertoleranz bewährt. Und hier ist ein Bonus: Ein KI-Agent kann das laufende Erlang-System inspizieren, um zu verstehen, was geschieht, Einblicke zu sammeln und sogar Probleme in der Produktion zu beheben.

**Für die Infrastruktur:** Alles läuft auf einem einzigen VPS. Nicht nur der Glossia-Produktions-Server, sondern auch alle peripheren Dienste: [PostgreSQL](https://www.postgresql.org/) für die Datenbank, [Plausible](https://plausible.io) für datenschutzfreundliche Analysen, [Grafana](https://grafana.com) für Telemetrie und Beobachtbarkeit. Alles wird von versionierten Infrastrukturdefinitionen bereitgestellt, die beschreiben, wohin es geht.

Dies hält die Kosten extrem niedrig. Wir sind nicht auf dritte Cloud-Dienste, verwaltete Datenbanken oder Plattform-als-Service-Anbieter angewiesen. Wir haben einige externe Abhängigkeiten, aber nur für Dinge, die uns eine lange Zeit kosten würden, um zu replizieren und bei denen die Kosten Sinn ergeben.

Wenn der Zeitpunkt gekommen ist, um auf mehrere Server zu skalieren, werden wir das Modell entwickeln. Aber wir glauben, dass wir mit dieser Einrichtung sehr weit kommen können. Und Geschwindigkeit ist derzeit wichtiger als Größe.

> \[\!IMPORTANT\]
> Wir sind sehr bewusst in Bezug auf das Auslassen technischer Komplexität, auf die Ingenieure oft zu früh zugreifen. Kubernetes, Microservices, Multi-Region-Deployments. Keine davon ist in dieser Phase notwendig und alles würde uns verlangsamen.

## Was das ermöglicht

Das Unternehmen auf diese Weise zu betreiben ist nicht nur ein Effizienz-Spiel. Es ändert, was wir bieten können und wie schnell wir lernen können.

**Günstiger für Nutzer.** Die Lokalisierungsbranche hat ihre Tools durch komplexe Preise, pro-Wort-Gebühren und Vertriebszyklen für Unternehmen unzugänglich gemacht. Wenn Ihr Übersetzungsworkflow von Beschaffung, Preisanbahnungen und einem Projektmanager abhängt, veröffentlichen die meisten kleinen Teams einfach auf Englisch. Indem wir unsere Betriebskosten auf Null halten, können wir etwas anbieten, das wirklich zugänglich ist.

**Schnellere Innovation.** Wir wollen viele Ideen erkunden. Neue Schnittstellen für den Agenten, bessere Feedback-Schleifen, neue Möglichkeiten, Linguisten in den Workflow einzubinden. Ein traditionelles Unternehmen müsste Personal nachrüsten, Teams ausrichten und Roadmap-Updates planen. Wir probieren einfach etwas aus. Der Abstand zwischen einer Idee und einem implementierten Experiment wird in Stunden gemessen, nicht in Quartalen.

## Herausfordern, wie wir arbeiten, nicht nur das, was wir bauen

Wir sind nicht emotional an die alten Vorgehensweisen gebunden. Wir hinterfragen aktiv, was Code-Reviews bedeutet, wenn ein Agent den Großteil des Codes schreibt. Wie Zusammenarbeit funktioniert, wenn nur zwei Menschen beteiligt sind. Wie man einen Fehler behebt, wenn der Agent das laufende System untersucht.

Wir machen Fehler. Wir machen sie weiterhin. Aber indem wir offen bleiben, wie wir das Geschäft konzipieren und betreiben, entdecken wir ständig Ideen, die das Produkt beeinflussen. Unsere Arbeitsweise ist nicht getrennt davon, was wir bauen. Sie sind dasselbe.

[McKinsey hat kürzlich beschrieben](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era), was sie als "die agentische Organisation" bezeichnen, ein neues Betriebsmodell, in dem KI-Agenten zu gleichrangigen Teilnehmern im Geschäftsablauf eines Unternehmens werden. Wir betrachten es nicht als Modell. Es ist einfach nur so, wie wir arbeiten.

## Die Wette

Wir wetten darauf, dass ein Zwei-Personen-Team mit den richtigen Werkzeugen, der richtigen Einstellung und ohne Organisationsballast Unternehmen mit hunderten Mitarbeitern und Millionen an Finanzierung überholen kann. Nicht auf allen Fronten, sondern auf der einen, die zählt: Ein grundlegend besseres Lokalisierungserlebnis zu liefern.

Die Branche kann sich nicht selbst neu erfinden. Wir können.
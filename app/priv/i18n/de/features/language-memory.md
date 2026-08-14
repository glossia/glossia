%{
  title: "Sprachgedächtnis",
  summary: "Eine versionierte Kontextschicht, die die Stimme, Terminologie und den Stil Ihrer Organisation erfasst. Das Sprachgedächtnis steuert jeden Agenten-Workflow und lässt sich über die API und MCP auf Ihre eigenen Tools ausweiten.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Erste Schritte",
  hero_cta_url: "/signup",
  highlights: [
    %{title: "Versioniert und überprüfbar", description: "Jede Änderung an Ihrer Stimme oder Terminologie erstellt eine neue, unveränderliche Version. Sie können den Verlauf einsehen, Iterationen vergleichen und auf eine frühere Version zurücksetzen, falls Abweichungen auftreten.", icon: "git-branch"},
    %{title: "Mehr als Lokalisierung", description: "Das Sprachgedächtnis dient nicht nur der Lokalisierung. Nutzen Sie es, um Marketingtexte zu generieren, Dokumentationsentwürfe zu erstellen, Pull Requests zu prüfen oder Social-Media-Beiträge zu verfassen, vollständig in der Stimme Ihrer Organisation.", icon: "megaphone"},
    %{title: "Offen und erweiterbar", description: "Greifen Sie über die REST-API oder den MCP-Server auf das Sprachgedächtnis zu. Integrieren Sie es in Ihre eigenen CI-Pipelines, Content-Tools oder benutzerdefinierten Agenten, um überall dort, wo Sie schreiben, Konsistenz zu gewährleisten.", icon: "puzzle"}
  ]
}
---
## Was ist das Sprachgedächtnis?

Das Sprachgedächtnis ist der kumulierte Kontext, der den Agenten von Glossia mitteilt, wie Ihre Organisation kommuniziert. Es besteht aus zwei Kernprimitiven, die Sie im Laufe der Zeit erstellen und verfeinern:

Die **Stimme** definiert, wie Inhalte klingen sollen. Tonfall, Formalitätsgrad, Zielgruppe und freie Richtlinien sind hier hinterlegt. Sie können eine Basis-Stimme für Ihr Konto festlegen und dann spezifische Felder für einzelne Locales überschreiben, sodass Ihre japanischen Texte formeller sein können, während Ihre englischen Texte umgangssprachlich bleiben.

Die **Terminologie** definiert, was Begriffe bedeuten und wie sie lokalisiert werden sollen. Jeder Eintrag enthält eine Definition und Übersetzungen pro Locale. Wenn ein Agent in Ihrem Ausgangsinhalt auf „workspace“ stößt, teilt die Terminologie ihm mit, ob der Begriff lokalisiert, transliteriert oder unverändert gelassen werden soll und welches Wort in der jeweiligen Zielsprache exakt zu verwenden ist.

Zusammen bilden Stimme und Terminologie eine Kontextschicht, die von den Agenten bei jeder Ausführung herangezogen wird. Je mehr Sie in diese Schicht investieren, desto weniger Überprüfung erfordern Ihre Ergebnisse.

## Unveränderliche Versionierung

Das Sprachgedächtnis ist rein additiv (append-only). Wenn Sie Ihre Stimme oder Terminologie aktualisieren, erstellt Glossia eine neue Version, anstatt die alte zu überschreiben. Jede Version zeichnet auf, wer sie wann erstellt hat, und enthält eine optionale Änderungsnotiz, die die Entwicklung erklärt.

Das bedeutet, dass Ihnen jederzeit ein vollständiges Audit-Protokoll zur Verfügung steht. Sie können Version 3 mit Version 7 vergleichen, um zu verstehen, wie sich Ihr Tonfall im Laufe eines Quartals verändert hat. Wenn eine kürzliche Änderung Inkonsistenzen verursacht hat, setzen Sie das System einfach auf eine vorherige Version zurück und fahren Sie fort.

Die Versionierung macht auch die Zusammenarbeit sicherer. Mehrere Teammitglieder können Änderungen an der Stimme vorschlagen, ohne Konflikte befürchten zu müssen, da jede Änderung ein eigenständiges, nachvollziebares Ereignis darstellt.

## Locale-sensitive Auflösung

Wenn ein Agent einen Workflow für eine bestimmte Locale ausführt, löst Glossia das Sprachgedächtnis für diesen Kontext auf. Das System beginnt mit Ihren Basis-Stimmeneinstellungen und wendet daraufhin alle locale-spezifischen Überschreibungen an. Dasselbe geschieht mit der Terminologie: Es werden nur Einträge einbezogen, die einen lokalisierten Begriff für die Ziel-Locale enthalten.

Dieser Auflösungsschritt stellt sicher, dass Agenten stets mit dem relevantesten Kontext arbeiten. Sie müssen keine separaten Konfigurationen pro Sprache pflegen. Definieren Sie Ihre Standards einmal, überschreiben Sie diese dort, wo es nötig ist, und überlassen Sie den Rest dem Auflösungssystem.

## Überrally einsetzbar

Das Sprachgedächtnis wurde für die Lokalisierung entwickelt, ist jedoch überall dort nützlich, wo Sie Texte erstellen. Da der Kontext über die [REST-API](/features/rest-api) und den [MCP-Server](/features/mcp-server) zugänglich ist, können Sie ihn über die Lokalisierung hinaus in weitere Workflows integrieren:

**Marketing- und Social-Media-Inhalte** - Integrieren Sie die Stimme Ihrer Organisation in einen Content-Agenten, der Social-Media-Beiträge, E-Mail-Kampagnen oder Landingpage-Texte entwirft. Die Terminologie sorgt für konsistente Markenbegriffe und die Stimmeneinstellungen stellen sicher, dass der Tonfall zu Ihrer Marke passt.

**Dokumentation** - Speisen Sie das Sprachgedächtnis in eine Dokumentations-Pipeline ein, damit die technische Dokumentation denselben Stilregeln folgt wie der Rest Ihrer Inhalte. Terminologieeinträge verhindern Abweichungen zwischen Dokumenten, Hilfeartikeln und produktinternen Texten.

**Code-Review** - Erstellen Sie einen Agenten, der Texte in Pull-Requests (Fehlermeldungen, Benutzeroberflächen-Labels, Onboarding-Texte) mit Ihrer Stimme und Terminologie abgleicht. Kennzeichnen Sie Inkonsistenzen, bevor sie produktiv gehen.

**Benutzerdefinierte Agenten** - Jeder MCP-kompatible Client kann das Sprachgedächtnis lesen und schreiben. Bitten Sie Ihren Programmierassistenten, „die Terminologie mit dem neuen Produktnamen zu aktualisieren“ oder „den Tonfall der Stimme für die deutsche Locale auf professionell zu setzen“, und er übersetzt Ihre Absicht in den richtigen API-Aufruf.

## Progressive Verfeinerung

Das Sprachgedächtnis verbessert sich mit der Nutzung. Jedes Mal, wenn ein Reviewer die Ausgabe eines Agenten korrigiert, fließt diese Korrektur in die nächste Version Ihrer Stimme oder Terminologie ein. Im Laufe der Zeit verringert sich die Kluft zwischen dem ersten Entwurf und dem Endergebnis, und der Überprüfungsschritt wird schneller.

Dies ist die Feedbackschleife im Zentrum von Glossia: Generieren, Überprüfen, Kontext verfeinern, erneut Generieren. Die Agenten befolgen nicht einfach nur Anweisungen. Sie arbeiten mit einem Kontext, der sich mit jedem Zyklus verbessert.
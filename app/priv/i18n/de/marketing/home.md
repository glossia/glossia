# Glossia: ein language OS für Teams

Glossia bringt Stimme, Terminologie, Übersetzung, Revisionshistorie und Lokalisierungsanalysen in ein einziges System. Es hilft Entwicklern, Linguisten und Produktteams, konsistent über Sprachen hinweg zu kommunizieren, ohne ihren Inhalt aus Git zu bewegen.

## Das Problem

Einschicken auf einer anderen Sprache ist nicht nur das Ersetzen von Wörtern. Teams müssen Bedeutung bewahren, die richtige Terminologie verwenden, den Ton an das Publikum anpassen und Übersetzungen aktuell halten, während sich das Produkt verändert. Kontext, der über Tabellen, Prompts und Übersetzungstools verstreut ist, führt zu inkonsistenter Schreibweise und wiederholter manueller Arbeit.

Ein LLM kann eine Übersetzung entwurfen, aber ein Entwurf allein bietet keine Versionshistorie, Validierung, selektive Updates oder einen Feedbackloop für die nächste Änderung.

## Die Rolle von Glossia

- **Sprachgedächtnis:** gemeinsam genutzte Stimmanleitung und Wörterbuch-Einträge helfen Personen und Agents, konsistente Sprache zu verwenden.
- **Repository-Lokalisierung:** verbinden Sie ein Repository, beschreiben Sie Quell- und Zielsprachen in der Konfiguration und prüfen Sie Änderungen über Pull Requests.
- **Progressive Verfeinerung:** Inhalts-Hashes helfen, unveränderten Inhalt nicht zu übersetzen. Validierung und Wiederherstellung machen Fehler sichtbar und handlungsrelevant.
- **Inhaltsrevisionierung:** bewahren Sie die Historie sprachlicher Entscheidungen und Änderungen, anstatt jede Generierung als isolierten Prompt zu behandeln.
- **Lokalisierungsanalysen:** datenschutzbewusste Webanalysen helfen Teams, ihr Publikum zu verstehen und wo Lokalisierung investiert werden sollte.
- **Agentenintegration:** ein OAuth-authentizierter MCP-Server und REST-Schnittstellen machen sprachlichen Kontext für bestehende Workflows verfügbar.

Glossia ersetzt nicht das redaktionelle Urteil. Es versorgt Teams mit dem Kontext, der Automatisierung und dem Review-Workflow, um dieses Urteil wiederholt anzuwenden.

## Erforschen

- [Erste Schritte](/docs/tutorials/getting-started.md): verbinden Sie ein Repository und führen Sie Ihren ersten Lokalisierungsablauf aus.
- [Warum Glossia](/docs/explanation/why-glossia.md): die Probleme, die das language OS lösen soll.
- [Funktionen](/features.md): Produktfähigkeiten und Anwendungsfälle.
- [Dokumentation](/docs.md): Tutorials, How-to-Guides, Referenzen und Erklärungen.
- [Blog](/blog.md): schriftlich über Lokalisierung und Sprachsysteme.
- [Change Log](/changelog.md): Produktänderungen.
- [Quellcode](https://github.com/glossia/glossia): überprüfen Sie die Implementierung und tragen Sie bei.

## Vergleiche

- [Glossia vs Crowdin](/docs/explanation/glossia-vs-crowdin.md)
- [Glossia vs Lokalise](/docs/explanation/glossia-vs-lokalise.md)
- [Glossia vs Phrase](/docs/explanation/glossia-vs-phrase.md)
- [Glossia vs Weblate](/docs/explanation/glossia-vs-weblate.md)

## Für Crawler und Agents

Veröffentlichte Seiten sind als Markdown verfügbar, indem Sie `.md` an ihre URL anhängen oder `Accept: text/markdown` mit der HTML URL anfordern. Die Markdown-URL der Homepage ist `/index.md`. Übersetzter Inhalt verwendet dieselben Sprachvorkennzeichner wie HTML und bewegt sich auf Englisch, wenn keine Übersetzung veröffentlicht ist.

Verwenden Sie [/llms.txt](/llms.txt) für Entdeckung, [/llms-full.txt](/llms-full.txt) für einen konsolidierten Dokumentationsexport und [/sitemap.xml](/sitemap.xml) für kanonische HTML-URLS. Kontodashboards sind Anwendungsoberflächen, keine Dokumentation; crawlen Sie sie nicht, um über Glossia zu lernen.
